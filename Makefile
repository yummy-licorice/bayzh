CONFIG_DIR := $(HOME)/.config
FONTS_DIR := $(HOME)/.local/share/fonts
BACKUP_DIR := $(HOME)/.dotfiles-backup-$(shell date +%Y%m%d_%H%M%S)

AUR_PACKAGES := walker-bin hyprland hyprshot hyprlock vesktop helix mako eww-git foot fastfetch adw-gtk-theme whitesur-icon-theme nim asdf-vm ttf-scientifica ttf-ia-writer ttf-oswald

# Config directories to backup and install
CONFIG_TARGETS := fastfetch foot gtk-3.0 gtk-4.0 helix hypr mako vesktop walker

.PHONY: all install install-ame install-deps backup-configs install-configs install-fonts install-home clean help

all: install

install: install-ame install-deps backup-configs install-configs install-fonts install-home
	@echo "✅ Dotfiles installation complete!"
	@echo "Backup created at: $(BACKUP_DIR)"

install-ame:
	@echo "🔧 Checking for ame AUR helper..."
	@if ! command -v ame >/dev/null 2>&1; then \
		echo "Installing ame AUR helper..."; \
		sudo pacman -S --needed --noconfirm base-devel pacman-contrib cargo; \
		if [ ! -d "ame" ]; then \
			git clone https://github.com/crystal-linux-packages/ame; \
		fi; \
		cd ame && makepkg -si --noconfirm; \
		cd ..; \
	else \
		echo "ame is already installed ✅"; \
	fi

install-deps: install-ame
	@echo "📦 Installing AUR packages..."
	@ame -S --noconfirm $(AUR_PACKAGES)

backup-configs:
	@echo "💾 Creating backup directory: $(BACKUP_DIR)"
	@mkdir -p $(BACKUP_DIR)/config
	@mkdir -p $(BACKUP_DIR)/fonts
	@mkdir -p $(BACKUP_DIR)/home
	@echo "Backing up existing configurations..."
	@for target in $(CONFIG_TARGETS); do \
		if [ -d "$(CONFIG_DIR)/$$target" ] || [ -f "$(CONFIG_DIR)/$$target" ]; then \
			echo "  Backing up ~/.config/$$target"; \
			cp -r "$(CONFIG_DIR)/$$target" "$(BACKUP_DIR)/config/" 2>/dev/null || true; \
		fi; \
	done
	@if [ -d "$(FONTS_DIR)" ]; then \
		echo "  Backing up fonts"; \
		cp -r "$(FONTS_DIR)"/* "$(BACKUP_DIR)/fonts/" 2>/dev/null || true; \
	fi
	@if [ -f "$(HOME)/.zshrc" ]; then \
		echo "  Backing up ~/.zshrc"; \
		cp "$(HOME)/.zshrc" "$(BACKUP_DIR)/home/"; \
	fi
	@if [ -d "$(HOME)/zsh" ]; then \
		echo "  Backing up ~/zsh"; \
		cp -r "$(HOME)/zsh" "$(BACKUP_DIR)/home/"; \
	fi

install-configs: backup-configs
	@echo "⚙️  Installing configuration files..."
	@mkdir -p $(CONFIG_DIR)
	@for target in $(CONFIG_TARGETS); do \
		if [ -d "config/$$target" ]; then \
			echo "  Installing ~/.config/$$target"; \
			cp -r "config/$$target" "$(CONFIG_DIR)/"; \
		fi; \
	done
	@echo "Setting up GTK symlinks..."
	@if [ -d "/usr/share/themes/adw-gtk3/gtk-4.0" ]; then \
		ln -sf /usr/share/themes/adw-gtk3/gtk-4.0/gtk-dark.css $(CONFIG_DIR)/gtk-4.0/gtk-dark.css; \
		ln -sf /usr/share/themes/adw-gtk3/gtk-4.0/gtk.css $(CONFIG_DIR)/gtk-4.0/gtk.css; \
	else \
		echo "  ⚠️  adw-gtk3 theme not found, GTK symlinks not created"; \
	fi

install-fonts: backup-configs
	@echo "🔤 Installing fonts..."
	@mkdir -p $(FONTS_DIR)
	@if [ -d "fonts" ]; then \
		cp fonts/*.ttf "$(FONTS_DIR)/" 2>/dev/null || true; \
		fc-cache -fv; \
	fi

install-home: backup-configs
	@echo "🏠 Installing home directory files..."
	@if [ -f "home/.zshrc" ]; then \
		echo "  Installing ~/.zshrc"; \
		cp "home/.zshrc" "$(HOME)/"; \
	fi
	@if [ -d "home/zsh" ]; then \
		echo "  Installing ~/zsh"; \
		cp -r "home/zsh" "$(HOME)/"; \
	fi

clean:
	@echo "🧹 Cleaning up..."
	@rm -rf ame/
	@echo "Cleanup complete!"

restore:
	@if [ -z "$(BACKUP)" ]; then \
		echo "❌ Please specify backup directory: make restore BACKUP=/path/to/backup"; \
		exit 1; \
	fi
	@if [ ! -d "$(BACKUP)" ]; then \
		echo "❌ Backup directory $(BACKUP) not found"; \
		exit 1; \
	fi
	@echo "🔄 Restoring from backup: $(BACKUP)"
	@if [ -d "$(BACKUP)/config" ]; then \
		cp -r "$(BACKUP)/config"/* "$(CONFIG_DIR)/" 2>/dev/null || true; \
	fi
	@if [ -d "$(BACKUP)/fonts" ]; then \
		cp -r "$(BACKUP)/fonts"/* "$(FONTS_DIR)/" 2>/dev/null || true; \
		fc-cache -fv; \
	fi
	@if [ -d "$(BACKUP)/home" ]; then \
		cp -r "$(BACKUP)/home"/* "$(HOME)/" 2>/dev/null || true; \
	fi
	@echo "✅ Restore complete!"

list-backups:
	@echo "📋 Available backups:"
	@ls -la $(HOME)/.dotfiles-backup-* 2>/dev/null || echo "No backups found"

force-install:
	@echo "⚠️  Force installing dotfiles (no backup)..."
	@$(MAKE) install-ame install-deps install-configs install-fonts install-home
	@echo "✅ Force installation complete!"

uninstall-deps:
	@echo "🗑️  Removing AUR packages..."
	@ame -R $(AUR_PACKAGES)

help:
	@echo "bayzh"
	@echo ""
	@echo "Available targets:"
	@echo "  install        - Full installation (default)"
	@echo "  install-ame    - Install ame AUR helper only"
	@echo "  install-deps   - Install AUR dependencies only"
	@echo "  backup-configs - Create backup of existing configs"
	@echo "  install-configs- Install configuration files"
	@echo "  install-fonts  - Install fonts"
	@echo "  install-home   - Install home directory files"
	@echo "  force-install  - Install without creating backup"
	@echo "  restore        - Restore from backup (use: make restore BACKUP=/path)"
	@echo "  list-backups   - List available backups"
	@echo "  uninstall-deps - Remove installed AUR packages"
	@echo "  clean          - Clean up temporary files"
	@echo "  help           - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make install                    # Full installation"
	@echo "  make restore BACKUP=~/.dotfiles-backup-20240101_120000"
	@echo "  make force-install             # Skip backup creation"
