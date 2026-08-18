# rofi-clipboard

A lightweight and minimal clipboard manager built around [Rofi](https://github.com/davatorium/rofi) and [cliphist](https://github.com/sentriz/cliphist).

It provides a simple Rofi-based interface for browsing clipboard history, copying entries, removing individual items, clearing the entire history, and previewing image entries.

## Dependencies

* `rofi`
* `cliphist`
* `wl-clipboard`

### Optional

* `mako` or another notification daemon for desktop notifications.
* A Wayland compositor such as Hyprland, Sway, or Niri.

## Attentive

Please make sure that `cliphist` is already configured and running correctly before using `rofi-clipboard`.

This script is designed for **Wayland** environments and relies on `wl-copy` for copying clipboard contents.

The script stores temporary image previews in:

```text
~/.cache/cliphist-preview
```

## Installation

Clone the repository and make the script executable:

```bash
git clone https://github.com/FrostShelter/rofi-clipboard.git
cd rofi-clipboard
sudo install -Dm755 rofi-clipboard.sh /usr/local/bin/rofi-clipboard
cd ~
rm -rf ~/rofi-clipboard
```
## Usage
In any terminal type:

```bash
rofi-clipboard
```

## Uninstall
To remove the binary from your system:

```bash
sudo rm /usr/local/bin/rofi-clipboard
hash -r
```

## Acknowledgements

Thanks for the inspiration!

* [rofi-bluetooth](https://github.com/nickclyde/rofi-bluetooth)
* [networkmanager-dmenu](https://github.com/firecat53/networkmanager-dmenu)

These projects inspired the design and concept of building lightweight, Rofi-based utilities for interacting with the Linux desktop.
