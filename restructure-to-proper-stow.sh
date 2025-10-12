#!/bin/bash
# Restructure ~/dotfiles to proper GNU Stow format and migrate existing symlinks

set -e

DOTFILES="$HOME/dotfiles"
BACKUP_DIR="$HOME/dotfiles-old-structure-backup-$(date +%Y%m%d_%H%M%S)"

echo "=== Restructure to Proper GNU Stow ==="
echo ""
echo "This will convert ~/dotfiles to proper stow package structure:"
echo "  Current: ~/dotfiles/.bashrc"
echo "  New:     ~/dotfiles/bash/.bashrc"
echo ""
echo "All existing symlinks in ~ will be updated automatically."
echo "Original ~/dotfiles will be backed up to: $BACKUP_DIR"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Backup current dotfiles
echo "📦 Creating backup..."
cp -r "$DOTFILES" "$BACKUP_DIR"
echo "✓ Backup created at: $BACKUP_DIR"
echo ""

cd "$DOTFILES"

# Create package directories
echo "📁 Creating package structure..."

# Root-level dotfiles -> packages
declare -A FILE_MAP=(
    [".bashrc"]="bash/.bashrc"
    [".bash_profile"]="bash/.bash_profile"
    [".bash_logout"]="bash/.bash_logout"
    [".gitconfig"]="git/.gitconfig"
    [".tmux.conf"]="tmux/.tmux.conf"
    [".tmux"]="tmux/.tmux"
    [".vim"]="vim/.vim"
    [".xinitrc"]="x11/.xinitrc"
    [".hushlogin"]="shell/.hushlogin"
    [".nvimlog"]="nvim/.nvimlog"
    [".sudo_as_admin_successful"]="misc/.sudo_as_admin_successful"
)

# Move root-level files to packages
for src in "${!FILE_MAP[@]}"; do
    if [ -e "$DOTFILES/$src" ]; then
        dest="${FILE_MAP[$src]}"
        pkg=$(dirname "$dest")
        
        mkdir -p "$DOTFILES/$pkg"
        mv "$DOTFILES/$src" "$DOTFILES/$dest"
        echo "  ✓ $src -> $dest"
    fi
done

# Handle .config items - each gets its own package
echo ""
echo "📁 Creating .config packages..."
if [ -d "$DOTFILES/.config" ]; then
    cd "$DOTFILES/.config"
    for item in *; do
        if [ -e "$item" ]; then
            mkdir -p "$DOTFILES/$item/.config"
            mv "$item" "$DOTFILES/$item/.config/"
            echo "  ✓ .config/$item -> $item/.config/$item"
        fi
    done
    cd "$DOTFILES"
    rmdir "$DOTFILES/.config" 2>/dev/null || true
fi

echo ""
echo "🔗 Updating symlinks in home directory..."

# Remove old symlinks
find ~ -maxdepth 1 -type l -lname "dotfiles/*" -delete 2>/dev/null || true
find ~/.config -maxdepth 1 -type l -lname "../dotfiles/.config/*" -delete 2>/dev/null || true

# Stow all packages
cd "$DOTFILES"
packages=$(find . -maxdepth 1 -type d ! -name "." ! -name ".." ! -name ".git" -exec basename {} \;)

echo "📦 Stowing packages with GNU Stow..."
for pkg in $packages; do
    echo "  stow $pkg"
    stow -v "$pkg" 2>&1 | grep -v "^LINK:" || true
done

echo ""
echo "✅ Restructure complete!"
echo ""
echo "Your ~/dotfiles is now using proper GNU Stow structure."
echo "Backup: $BACKUP_DIR"
echo ""
echo "To add new packages: mkdir ~/dotfiles/mypackage && cd ~/dotfiles && stow mypackage"
echo ""
