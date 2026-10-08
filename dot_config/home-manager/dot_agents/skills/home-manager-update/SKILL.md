---
name: home-manager-update
description: >
  Update this machine's Home Manager config. Use when the user asks to
  check nixpkgs or Home Manager updates, see which tools would change,
  advance or drop a pinned git source, run home-manager build or switch,
  or publish the config through chezmoi. Also 更新 home-manager、钉死的
  git、switch、chezmoi 提交推送.
---

# Home Manager update

The config is `~/.config/home-manager`. This skill lives in that tree at `.agents/skills/home-manager-update/SKILL.md` and is published with the rest of the config. Chezmoi owns the tree from `~/.local/share/chezmoi` (`origin` `git@github.com:BingCoke/windows-dotfiles.git`). `docs/operations.md` is the switch and rollback procedure. `docs/upstream-workarounds.md` is the revocation rule for every pin. Read the section you are about to change. Those files win when this skill and the tree disagree.

A **profile** is one `homeConfigurations` attribute. A **session** is graphical when `XDG_SESSION_TYPE` is `wayland` or `x11`, or `XDG_CURRENT_DESKTOP` is set; otherwise it is shell. A **tool** is a package or enabled program in the selected profile. A **pin** is an `overrideAttrs` `src` rev that replaces the nixpkgs package. A **generation** is one activated Home Manager build.

The tool set is whatever that profile declares. Read it from Home Manager. Names in this skill would go stale.

## 1. Name the profile

Read the user and hostname from the machine. A graphical session uses `user@hostname`. A shell session uses `user@hostname-shell`. Ignore the profile written in `docs/operations.md` and any profile remembered from another host. Confirm the attribute exists in `flake.nix` and that its host module sets `home.username` to the current user.

Done when that attribute exists and matches the session.

## 2. Tell the user the updates

Compare the locked nixpkgs revision with `github:NixOS/nixpkgs/nixos-unstable` without writing `flake.lock`. Enumerate the selected profile's tools and diff their versions. A pinned tool does not follow the flake; say so with its current rev, then compare that pin with upstream git and nixpkgs as in the pin branch.

Report the version changes to the user and stop. A later branch runs only after the user accepts that report. A pin move does not run `nix flake update`. A flake update does not delete a pin.

### Pin

Read that pin's section in `docs/upstream-workarounds.md`, then compare three revs: the pin, upstream git HEAD, and `nixos-unstable`'s `src.rev`.

- Upstream git has commits after the pin that nixpkgs lacks: move the pin to that commit and refresh the hashes that expression already records. Keep every local patch that still applies, in its current order.
- nixpkgs already contains the pinned commit and the fix that justified it: delete the `src` override and apply the patches that the doc still requires onto `pkgs.<name>`.
- Neither is true: leave the pin.

Build the overridden package, then `home-manager build --flake ".#$PROFILE"`.

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
