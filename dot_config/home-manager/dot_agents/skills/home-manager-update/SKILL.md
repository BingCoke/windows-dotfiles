---
name: home-manager-update
description: >
  Update this machine's Home Manager config. Use when the user asks to
  check nixpkgs or Home Manager updates, compare important packages such
  as Noctalia, advance or drop a pinned git source, run home-manager build
  or switch, or publish the config through chezmoi (pull, re-add, commit,
  push). Also 更新 home-manager、钉死的 git、switch、chezmoi 提交推送.
---

# Home Manager update

The config is `~/.config/home-manager`. This skill lives in that tree at `.agents/skills/home-manager-update/SKILL.md` and is published with the rest of the config. Chezmoi owns the tree from `~/.local/share/chezmoi` (`origin` `git@github.com:BingCoke/windows-dotfiles.git`). `docs/operations.md` is the switch and rollback procedure. `docs/upstream-workarounds.md` is the revocation rule for every pin. Read the section you are about to change. Those files win when this skill and the tree disagree.

A **profile** is one `homeConfigurations` attribute. A **pin** is an `overrideAttrs` `src` rev that replaces the nixpkgs package. A **generation** is one activated Home Manager build.

## 1. Name the profile

The desktop profile is `$(whoami)@$(hostname)`. Read both from the machine. Ignore the profile written in `docs/operations.md` and any profile remembered from another host. Use the attribute with the `-shell` suffix only when the user asks for the shell profile. Confirm the attribute exists in `flake.nix` and that its host module sets `home.username` to the current user. A shell profile has no desktop modules.

Done when that attribute exists and the host module names the current user.

## 2. Stay on the asked branch

Do the first branch the user asked for, then stop. A report does not update the lock, move a pin, switch, or publish. A pin move does not run `nix flake update`. A flake update does not delete a pin. Switch and chezmoi run only after the user asks for that step.

### Report

Compare the locked nixpkgs revision with `github:NixOS/nixpkgs/nixos-unstable` without writing `flake.lock`. Diff versions for packages the desktop modules actually reference. Always include noctalia, niri, mango, kitty, fcitx5, and quickshell, plus any package the user names.

A package whose `src` is pinned is unchanged by the flake move. Say so with the pin's current rev.

Done when every changed package has its old version, new version, and whether the running profile would pick it up.

### Pin

Read that pin's section in `docs/upstream-workarounds.md`, then compare three revs: the pin, upstream git HEAD, and `nixos-unstable`'s `src.rev`.

- Upstream git has commits after the pin that nixpkgs lacks: move the pin to that commit, refresh the fetch hash, and keep every local patch that still applies in its current order.
- nixpkgs already contains the pinned commit and the fix that justified it: delete the `src` override and apply the patches that the doc still requires onto `pkgs.<name>`.
- Neither is true: leave the pin.

`Cargo.lock` unchanged means the existing cargo-vendor hash still applies. Build the overridden package, then `home-manager build --flake ".#$PROFILE"`.

Done when the store path is the chosen rev and each kept patch applied during that build.

### Flake lock

Run `nix flake update` only for the inputs the user named. Build the live profile before switch. When the result is wrong, restore `flake.lock` as well as the generation; rollback alone leaves the lock moved (`docs/operations.md`).

Done when the build uses the new lock and the live profile evaluates.

### Switch

Run `home-manager switch --flake ".#$PROFILE"` only after that same profile's build succeeded. An existing regular file with the same contents as the generated file is a skip; leave it until the user asks to hand the path back to Home Manager.

Done when `home-manager generations` shows the new id as current and the profile's bin path is the built store path. A compositor process that started before the switch keeps the old binary until the next login.

### Chezmoi

Publish only the destination files this change owns. This skill is one of those files when it changed.

1. In the chezmoi source repo, `git pull --ff-only origin master`.
2. `chezmoi re-add` those destination paths only. A new file needs `chezmoi add` before the first commit.
3. Commit only the matching `dot_config/home-manager/...` paths. Other dirty source files stay unstaged.
4. `git push origin master`.

Done when `HEAD` equals `origin/master` and `git status` shows none of this change left uncommitted. Unrelated dirty files may remain.
