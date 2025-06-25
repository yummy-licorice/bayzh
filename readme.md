# Bayzh
Comprehensive dotfiles for my Hyprland setup based on the colorscheme of the Nier Automata game.
## Showcase
![image](https://github.com/user-attachments/assets/e5cf147c-28ee-4161-9975-ed202f52d5a4)
<details>
<summary>More Screenshots</summary>
<table>
<tr>
<td><strong>Eww</strong></td>
<td><img src="https://github.com/user-attachments/assets/34b12b45-9d1f-4ea1-9e17-f23284eac8ee" alt="2025-06-24-193001_hyprshot"></td>
</tr>
<tr>
<td><strong>Walker</strong></td>
<td><img src="https://github.com/user-attachments/assets/554e96be-1481-4b8b-b647-b02135d6da30" alt="Walker screenshot"></td>
</tr>
<tr>
<td><strong>Zen</strong></td>
<td><img src="https://github.com/user-attachments/assets/900a3f7b-bc47-4d4a-9fc2-96498b50aafe" alt="2025-06-13-183443_hyprshot"></td>
</tr>
<tr>
<td><strong>Foot</strong></td>
<td><img src="https://github.com/user-attachments/assets/abf0c043-f4b0-4641-a7b5-fd030d242404" alt="2025-06-13-034757_hyprshot"></td>
</tr>
<tr>
<td><strong>Discord</strong></td>
<td><img src="https://github.com/user-attachments/assets/b96d46c0-672b-45f0-811e-5f015b47e6f2" alt="2025-06-15-110741_hyprshot"></td>
</tr>
<tr>
<td><strong>Helix</strong></td>
<td><img src="https://github.com/user-attachments/assets/cbc0cf7e-de9b-4f78-83d7-b883bef8220f" alt="Helix screenshot"></td>
</tr>
<tr>
<td><strong>GTK</strong></td>
<td><img src="https://github.com/user-attachments/assets/a1c9c7b5-7493-408f-8c21-0dd86c72851b" alt="2025-06-13-185307_hyprshot"></td>
</tr>
</table>
</details>

## Info
### Apps
- Hyprland: Window manager
- Helix: Text editor
- Walker: App launcher
- Eww: Widgets and bar
- Mako: Notifications
- Foot: Terminal
- Vesktop: Discord client
### Fonts
- Phosphor: Icons font
- Scientifica: Terminal font (bitmap; use 8 or 16 px)
- IA Writer Duo: Main UI font
- Oswald: Widget font
### Shell Configuration
- Zsh: Shell of choice
- Shelly: Custom shell prompt
## Installation
### Prerequisites
- Arch Linux or Arch-based distribution
- Git
- Internet connection
### Quick Install
```bash
git clone https://github.com/yummy-licorice/bayzh ~/.dotfiles
cd ~/.dotfiles
make install
```
The installer will:
- Install the `ame` AUR helper if not present
- Install all required packages
- Create backups of existing configurations
- Install all dotfiles to their proper locations
- Set up fonts and refresh font cache
- Configure GTK themes and symlinks
### Manual Steps
If you aren't on an arch based distro you'll have to manually install the dependencies
1. **Clone the repository**
```bash
git clone https://github.com/yummy-licorice/bayzh ~/.dotfiles
cd ~/.dotfiles
```
2. **Run the installation**
```bash
make install-configs
make install-fonts
make install-home
```
## Installed Packages
- `walker-bin` - App launcher
- `hyprland` - Wayland compositor
- `hyprshot` - Screenshot tool
- `hyprlock` - Screen locker
- `vesktop` - Discord client
- `helix` - Text editor
- `mako` - Notification daemon
- `eww-git` - Widgets
- `foot` - Terminal
- `fastfetch` - System fetch
- `adw-gtk-theme` - GTK3 theme
- `whitesur-icon-theme` - GTK icon theme
- `nim` - Compiler
- `asdf-vm` - Programming version manager
- `ttf-scientifica` - Programming font
- `ttf-ia-writer` - UI font
- `ttf-oswald` - Widget font
## Usage

### Basic Commands
```bash
# Full installation
make install

# Install without backup (use with caution)
make force-install

# Install only dependencies
make install-deps

# Show help
make help
```
### Backups
```bash
# List available backups
make list-backups

# Restore from backup
make restore BACKUP=~/.dotfiles-backup-20240101_120000

# Clean temporary files
make clean
```
### Components
```bash
# Install only configurations
make install-configs

# Install only fonts
make install-fonts

# Install only home directory files
make install-home
```
## Directory Structure
```
├── config
│   ├── fastfetch
│   │   ├── config.jsonc
│   │   └── mewo.txt
│   ├── foot
│   │   └── foot.ini
│   ├── gtk-3.0
│   │   ├── bookmarks
│   │   ├── gtk.css
│   │   └── settings.ini
│   ├── gtk-4.0
│   │   ├── gtk.css -> /usr/share/themes/adw-gtk3/gtk-4.0/gtk.css
│   │   └── gtk-dark.css -> /usr/share/themes/adw-gtk3/gtk-4.0/gtk-dark.css
│   ├── helix
│   │   ├── config.toml
│   │   ├── languages.toml
│   │   └── themes
│   │       ├── articblush.toml
│   │       ├── dark-decay.toml
│   │       ├── light-decay.toml
│   │       ├── nier.toml
│   │       ├── oxocarbon.toml
│   │       └── sapphy.toml
│   ├── hypr
│   │   ├── eww
│   │   │   ├── assets
│   │   │   │   ├── art.png
│   │   │   │   ├── bottom.png
│   │   │   │   ├── default-bottom.jpg
│   │   │   │   ├── default.jpg
│   │   │   │   ├── default-strip.jpg
│   │   │   │   └── strip.png
│   │   │   ├── _colors.scss
│   │   │   ├── eww.scss
│   │   │   ├── eww.yuck
│   │   │   ├── scripts
│   │   │   │   ├── battery
│   │   │   │   ├── colorstrip
│   │   │   │   ├── polaroid
│   │   │   │   ├── scripts.nimble
│   │   │   │   ├── src
│   │   │   │   │   ├── battery.nim
│   │   │   │   │   ├── colorstrip.nim
│   │   │   │   │   ├── polaroid.nim
│   │   │   │   │   ├── tarana.nim
│   │   │   │   │   └── ws.nim
│   │   │   │   ├── tarana
│   │   │   │   └── ws
│   │   │   └── widgets
│   │   │       ├── bar.scss
│   │   │       ├── bar.yuck
│   │   │       ├── tarana.scss
│   │   │       └── tarana.yuck
│   │   ├── hyprland.conf
│   │   ├── hyprland.confiZL7U0.bck
│   │   ├── hyprlock
│   │   │   └── hyprlogo.png
│   │   ├── hyprlock.conf
│   │   └── plugins.conf
│   ├── mako
│   │   └── config
│   ├── vesktop
│   │   └── quick.css
│   └── walker
│       ├── config.toml
│       └── themes
│           ├── default.css
│           ├── default.toml
│           ├── default_window.toml
│           ├── nier.css
│           └── nier.toml
├── fonts
│   ├── Phosphor-Fill.ttf
│   └── phosphor.ttf
├── home
│   └── zsh
│       ├── functions.nim
│       ├── LICENSE
│       ├── README.rst
│       ├── shelly
│       ├── shelly copy.nim
│       ├── shelly.nim
│       └── zshrc
├── Makefile
└── readme.md
```
## Backups
Bayzh automatically creates backups with timestamps before making any changes to system configurations
- Location: `~/.dotfiles-backup-YYYYMMDD_HHMMSS/`
- Restoration: `make restore BACKUP=/path/to/backup`
## Keybinds
Keybinds are configured in `config/hypr/hyprland.conf`. Some notable ones are:
- `Super + Return` - Open terminal
- `Super + D` - Open application launcher
- `Super + Q` - Close window
*Check the configs for the full list of keybinds*
## Troubleshooting
### Common Issues
- Installation fails with permission errors
```bash
# Make sure you have sudo access and try again
sudo -v
make install
```
- Missing dependencies
```bash
# Install the basic development stuff
sudo pacman -S --needed base-devel git
```
- Font issues
```bash
# Reload font cache
fc-cache -fv
```
- GTK themes not applying
```bash
# Try rebooting
reboot
```
### Help
1. Run `make help` for available commands
2. Check the [Issues](https://github.com/yummy-licorice/bayzh/issues) page and make a new issue
## Acknowledgments
- [YoRHa CSS](https://github.com/metakirby5/yorha) - Color scheme inspiration
- [BeatsPrint](https://github.com/TrueMyst/BeatPrints/tree/main) - Music widget inspiration
- [nishiiko/niri-dots](https://github.com/nishiiko/niri-dots) - Fastfetch config
