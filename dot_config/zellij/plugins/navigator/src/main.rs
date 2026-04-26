use zellij_tile::prelude::*;

use std::collections::{BTreeMap, VecDeque};
use std::str::FromStr;
use std::time::Instant;

struct State {
    permissions_granted: bool,
    current_term_command: Option<String>,
    command_queue: VecDeque<Command>,
    // Timing: when the current pending command was received via pipe().
    pending_since: Option<Instant>,
    // Timing: when we dispatched list_clients() for the current pending command.
    list_clients_sent_at: Option<Instant>,

    // Configuration
    move_mod: Vec<Mod>,
    resize_mod: Vec<Mod>,
    use_arrow_keys: bool,
    editor_commands: Vec<String>,
}

enum Command {
    MoveFocus(Direction),
    MoveFocusOrTab(Direction),
    Resize(Direction),
}

#[derive(Debug)]
enum Mod {
    Shift,
    Alt,
    Ctrl,
    Super,
    Hyper,
    Meta,
    CapsLock,
    NumLock,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        self.parse_configuration(configuration);

        request_permission(&[
            PermissionType::WriteToStdin,
            PermissionType::ChangeApplicationState,
            PermissionType::ReadApplicationState,
        ]);
        subscribe(&[EventType::PermissionRequestResult, EventType::ListClients]);
        if self.permissions_granted {
            hide_self();
        }
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::ListClients(list) => {
                let rx_at = Instant::now();
                let rt_ms = self
                    .list_clients_sent_at
                    .map(|t| rx_at.duration_since(t).as_micros() as f64 / 1000.0);
                match rt_ms {
                    Some(ms) => eprintln!(
                        "[navigator][timing] ListClients received; list_clients round-trip = {:.3} ms",
                        ms
                    ),
                    None => eprintln!(
                        "[navigator][timing] ListClients received (no pending request tracked)"
                    ),
                }

                let parse_start = Instant::now();
                self.current_term_command = term_command_from_client_list(list);
                eprintln!(
                    "[navigator][timing] term_command_from_client_list = {:.3} ms; current_term_command = {:?}",
                    parse_start.elapsed().as_micros() as f64 / 1000.0,
                    self.current_term_command
                );

                if !self.command_queue.is_empty() {
                    let command = self.command_queue.pop_front().unwrap();
                    let exec_start = Instant::now();
                    self.execute_command(command);
                    let exec_elapsed = exec_start.elapsed().as_micros() as f64 / 1000.0;

                    let total_ms = self
                        .pending_since
                        .map(|t| t.elapsed().as_micros() as f64 / 1000.0);
                    match total_ms {
                        Some(ms) => eprintln!(
                            "[navigator][timing] execute_command = {:.3} ms; TOTAL pipe->execute = {:.3} ms",
                            exec_elapsed, ms
                        ),
                        None => eprintln!(
                            "[navigator][timing] execute_command = {:.3} ms",
                            exec_elapsed
                        ),
                    }

                    self.pending_since = None;
                    self.list_clients_sent_at = None;
                }
            }
            Event::PermissionRequestResult(permission) => {
                self.permissions_granted = match permission {
                    PermissionStatus::Granted => true,
                    PermissionStatus::Denied => false,
                };
                if self.permissions_granted {
                    hide_self();
                }
            }
            _ => {}
        }
        true
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        let pipe_at = Instant::now();
        let name = pipe_message.name.clone();
        let payload_dbg = pipe_message.payload.clone();
        if let Some(command) = parse_command(pipe_message) {
            eprintln!(
                "[navigator][timing] pipe() received: name={:?}, payload={:?}",
                name, payload_dbg
            );
            self.pending_since = Some(pipe_at);
            self.handle_command(command);
            eprintln!(
                "[navigator][timing] pipe() handler returned in {:.3} ms (waiting for ListClients)",
                pipe_at.elapsed().as_micros() as f64 / 1000.0
            );
        } else {
            eprintln!(
                "[navigator][timing] pipe() ignored message name={:?}, payload={:?}",
                name, payload_dbg
            );
        }
        true
    }
}

impl Default for State {
    fn default() -> Self {
        Self {
            permissions_granted: false,
            current_term_command: None,
            command_queue: VecDeque::new(),
            pending_since: None,
            list_clients_sent_at: None,

            move_mod: vec![Mod::Ctrl],
            resize_mod: vec![Mod::Alt],
            use_arrow_keys: false,
            editor_commands: vec!["nvim".into(), "vim".into()],
        }
    }
}

impl State {
    fn handle_command(&mut self, command: Command) {
        self.command_queue.push_back(command);
        let before = Instant::now();
        list_clients();
        self.list_clients_sent_at = Some(before);
        eprintln!(
            "[navigator][timing] list_clients() call returned in {:.3} ms (async, awaiting event)",
            before.elapsed().as_micros() as f64 / 1000.0
        );
    }

    fn execute_command(&mut self, command: Command) {
        let is_editor = self.current_pane_is_editor();
        eprintln!(
            "[navigator][timing] execute_command: is_editor_pane={}",
            is_editor
        );
        if is_editor {
            let t = Instant::now();
            write_chars(&self.command_to_keybind(&command));
            eprintln!(
                "[navigator][timing] write_chars returned in {:.3} ms",
                t.elapsed().as_micros() as f64 / 1000.0
            );
            return;
        }

        let t = Instant::now();
        match command {
            Command::MoveFocus(direction) => move_focus(direction),
            Command::MoveFocusOrTab(direction) => move_focus_or_tab(direction),
            Command::Resize(direction) => {
                resize_focused_pane_with_direction(Resize::Increase, direction)
            }
        }
        eprintln!(
            "[navigator][timing] focus/resize API returned in {:.3} ms",
            t.elapsed().as_micros() as f64 / 1000.0
        );
    }

    fn current_pane_is_editor(&self) -> bool {
        if let Some(current_command) = &self.current_term_command {
            let cmd = current_command.to_lowercase();
            return self.editor_commands.iter().any(|e| e == &cmd);
        }
        false
    }

    fn parse_configuration(&mut self, configuration: BTreeMap<String, String>) {
        self.move_mod = configuration.get("move_mod").map_or(vec![Mod::Ctrl], |f| {
            Self::parse_modifiers(f).unwrap_or_else(|e| {
                eprintln!("Illegal modifier for move_mod: {}, using default", e);
                vec![Mod::Ctrl]
            })
        });
        self.resize_mod = configuration.get("resize_mod").map_or(vec![Mod::Alt], |f| {
            Self::parse_modifiers(f).unwrap_or_else(|e| {
                eprintln!("Illegal modifier for resize_mod: {}, using default", e);
                vec![Mod::Alt]
            })
        });
        self.use_arrow_keys = configuration
            .get("use_arrow_keys")
            .is_some_and(|v| v.to_lowercase() == "true");
        self.editor_commands = configuration
            .get("editor_commands")
            .map_or(vec!["nvim".into(), "vim".into()], |v| {
                v.split(',')
                    .map(|s| s.trim().to_lowercase())
                    .filter(|s| !s.is_empty())
                    .collect()
            });
    }

    fn parse_modifiers(input: &str) -> Result<Vec<Mod>, String> {
        input.split('+').map(|s| s.trim().parse::<Mod>()).collect()
    }

    fn command_to_keybind(&mut self, command: &Command) -> String {
        let modifiers = match command {
            Command::MoveFocus(_) | Command::MoveFocusOrTab(_) => &self.move_mod,
            Command::Resize(_) => &self.resize_mod,
        };

        let direction = match command {
            Command::MoveFocus(direction)
            | Command::MoveFocusOrTab(direction)
            | Command::Resize(direction) => direction,
        };

        // Use the ASCII control characters for single modifier keybindings
        if modifiers.len() == 1 && !self.use_arrow_keys {
            match &modifiers[0] {
                Mod::Ctrl => return ctrl_keybinding(direction),
                Mod::Alt => return alt_keybinding(direction),
                _ => {}
            }
        }

        if self.use_arrow_keys {
            return arrow_kitty_keybinding(direction, modifiers);
        }

        kitty_keybinding(direction, modifiers)
    }
}

fn term_command_from_client_list(clients: Vec<ClientInfo>) -> Option<String> {
    for c in clients {
        if c.is_current_client {
            let command = c.running_command.split(' ').next()?;
            // Handle both Unix (/) and Windows (\) path separators
            let command = command
                .rsplit('/')
                .next()
                .unwrap_or(command);
            let command = command
                .rsplit('\\')
                .next()
                .unwrap_or(command);
            // Strip Windows .exe suffix
            let command = command.strip_suffix(".exe").unwrap_or(command);
            return Some(command.to_string());
        }
    }
    None
}

fn mod_to_kitty_protocol(modifier: &Mod) -> u8 {
    match modifier {
        Mod::Shift => 1,
        Mod::Alt => 2,
        Mod::Ctrl => 4,
        Mod::Super => 8,
        Mod::Hyper => 16,
        Mod::Meta => 32,
        Mod::CapsLock => 64,
        Mod::NumLock => 128,
    }
}

fn ctrl_keybinding(direction: &Direction) -> String {
    let direction = match direction {
        Direction::Left => "\u{0008}",
        Direction::Right => "\u{000C}",
        Direction::Up => "\u{000B}",
        Direction::Down => "\u{000A}",
    };
    direction.to_string()
}

fn alt_keybinding(direction: &Direction) -> String {
    let mut char_vec: Vec<char> = vec![0x1b as char];
    char_vec.push(match direction {
        Direction::Left => 'h',
        Direction::Right => 'l',
        Direction::Up => 'k',
        Direction::Down => 'j',
    });
    char_vec.iter().collect()
}

fn mods_to_kitty_protocol(modifiers: &[Mod]) -> String {
    let mut kitty_modifiers = 1;
    for modifier in modifiers {
        kitty_modifiers += mod_to_kitty_protocol(modifier);
    }
    format!("{}", kitty_modifiers)
}

fn arrow_kitty_keybinding(direction: &Direction, modifiers: &[Mod]) -> String {
    let key_code = match direction {
        Direction::Up => "A",
        Direction::Down => "B",
        Direction::Right => "C",
        Direction::Left => "D",
    };
    let mod_code = mods_to_kitty_protocol(modifiers);
    format!("\x1b\x5b1;{}{}", mod_code, key_code)
}

fn kitty_keybinding(direction: &Direction, modifiers: &[Mod]) -> String {
    let key_code = match direction {
        Direction::Left => "104",
        Direction::Right => "108",
        Direction::Up => "107",
        Direction::Down => "106",
    };

    let mod_code = mods_to_kitty_protocol(modifiers);

    format!("\x1b\x5b{};{}u", key_code, mod_code)
}

fn string_to_direction(s: &str) -> Option<Direction> {
    match s {
        "left" => Some(Direction::Left),
        "right" => Some(Direction::Right),
        "up" => Some(Direction::Up),
        "down" => Some(Direction::Down),
        _ => None,
    }
}

impl FromStr for Mod {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "shift" => Ok(Mod::Shift),
            "alt" => Ok(Mod::Alt),
            "ctrl" => Ok(Mod::Ctrl),
            "super" => Ok(Mod::Super),
            "hyper" => Ok(Mod::Hyper),
            "meta" => Ok(Mod::Meta),
            "caps_lock" => Ok(Mod::CapsLock),
            "num_lock" => Ok(Mod::NumLock),
            _ => Err(format!("Invalid modifier: {}", s)),
        }
    }
}

fn parse_command(pipe_message: PipeMessage) -> Option<Command> {
    let payload = pipe_message.payload?;
    let command = pipe_message.name;

    let direction = string_to_direction(payload.as_str())?;

    match command.as_str() {
        "move_focus" => Some(Command::MoveFocus(direction)),
        "move_focus_or_tab" => Some(Command::MoveFocusOrTab(direction)),
        "resize" => Some(Command::Resize(direction)),
        _ => None,
    }
}
