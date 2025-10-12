#!/bin/bash
# Comprehensive script to stow ALL dotfiles from ~/dotfiles
# This ensures all items in ~/dotfiles are properly symlinked to ~

set -e  # Exit on error

DOTFILES_DIR="$HOME/dotfiles"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=== Stow ALL Dotfiles Script ==="
echo "This will ensure ALL items in ~/dotfiles are properly symlinked."
echo ""
echo "Press Enter to continue, or Ctrl+C to cancel..."
read

# Function to create backup and symlink
stow_config_item() {
    local item=$1
    local source_path="$DOTFILES_DIR/.config/$item"
    local target_path="$HOME/.config/$item"
    
    if [ ! -e "$source_path" ]; then
        return
    fi
    
    if [ -L "$target_path" ]; then
        return
    fi
    
    if [ -e "$target_path" ]; then
        echo "  📦 Backing up existing .config/$item"
        cp -r "$target_path" "${target_path}.backup.${TIMESTAMP}"
        rm -rf "$target_path"
    fi
    
    echo "  🔗 Symlinking .config/$item"
    ln -s "../dotfiles/.config/$item" "$target_path"
}

# Check if dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Error: $DOTFILES_DIR does not exist!"
    exit 1
fi

echo "Found dotfiles directory: $DOTFILES_DIR"
echo ""

# Process .config items
echo "=== Processing .config items ==="

# Get all items in dotfiles/.config
cd "$DOTFILES_DIR/.config"
for item in * .*; do
    # Skip . and ..
    if [ "$item" = "." ] || [ "$item" = ".." ]; then
        continue
    fi
    
    # Skip if not a directory or file
    if [ ! -e "$item" ]; then
        continue
    fi
    
    stow_config_item "$item"
done

echo ""
echo "=== Processing root-level dotfiles ==="

# Process root-level dotfiles (files starting with .)
cd "$DOTFILES_DIR"
for item in .*; do
    # Skip . and ..
    if [ "$item" = "." ] || [ "$item" = ".." ]; then
        continue
    fi
    
    # Skip .git directory
    if [ "$item" = ".git" ]; then
        continue
    fi
    
    # Skip .config (already handled)
    if [ "$item" = ".config" ]; then
        continue
    fi
    
    # Skip .gitignore (repository file)
    if [ "$item" = ".gitignore" ]; then
        continue
    fi
    
    source_path="$DOTFILES_DIR/$item"
    target_path="$HOME/$item"
    
    # Check if already symlinked
    if [ -L "$target_path" ]; then
        continue
    fi
    
    # Backup and remove if exists
    if [ -e "$target_path" ]; then
        echo "  📦 Backing up existing $item"
        cp -r "$target_path" "${target_path}.backup.${TIMESTAMP}"
        rm -rf "$target_path"
    fi
    
    # Create symlink
    if [ -e "$source_path" ]; then
        echo "  🔗 Symlinking $item"
        ln -s "dotfiles/$item" "$target_path"
    fi
done

echo ""
echo "=== Summary ==="
echo "All dotfiles have been processed!"
echo ""
if [ -n "$(find ~ ~/.config -name "*.backup.${TIMESTAMP}" 2>/dev/null)" ]; then
    echo "Backups created with timestamp: ${TIMESTAMP}"
    echo "Backups location: ~/.config/*.backup.${TIMESTAMP} and ~/.*.backup.${TIMESTAMP}"
else
    echo "No backups needed - everything was already stowed!"
fi
echo ""
echo "To verify, run: ~/dotfiles-status.sh"
echo ""
echo "=== Done! ==="

