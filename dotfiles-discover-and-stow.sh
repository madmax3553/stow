#!/bin/bash
# Discover unstowed configs and interactively add them to dotfiles repo

DOTFILES="$HOME/dotfiles"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=== Dotfiles Discovery Tool ==="
echo ""
echo "Scanning for config files not in your dotfiles repo..."
echo ""

# Arrays to hold discovered files
declare -a root_configs
declare -a config_items

IGNORE_FILE="$DOTFILES/.stowignore"
declare -a STOW_IGNORE=()
if [ -f "$IGNORE_FILE" ]; then
    mapfile -t STOW_IGNORE < <(sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$IGNORE_FILE")
fi

is_ignored() {
    local candidate="$1"
    for ignored in "${STOW_IGNORE[@]}"; do
        if [[ "$candidate" == "$ignored" ]]; then
            return 0
        fi
    done
    return 1
}

if [ ${#STOW_IGNORE[@]} -gt 0 ]; then
    echo "Using ignore list from $IGNORE_FILE"
fi

# Check root-level dotfiles
for item in ~/.*; do
    basename=$(basename "$item")
    
    # Skip special cases
    [[ "$basename" == "." ]] && continue
    [[ "$basename" == ".." ]] && continue
    [[ "$basename" == ".git" ]] && continue
    [[ "$basename" == ".cache" ]] && continue
    [[ "$basename" == ".local" ]] && continue
    [[ "$basename" == ".config" ]] && continue
    [[ "$basename" =~ ^\.bash_history ]] && continue
    [[ "$basename" =~ \.backup\. ]] && continue
    [[ "$basename" =~ ^\..*\.tmp$ ]] && continue
    [[ "$basename" == ".Xauthority" ]] && continue
    [[ "$basename" == ".viminfo" ]] && continue
    [[ "$basename" == ".wget-hsts" ]] && continue
    [[ "$basename" == ".pulse-cookie" ]] && continue
    is_ignored "$basename" && continue
    
    # Skip if already a symlink to dotfiles
    if [ -L "$item" ]; then
        target=$(readlink "$item")
        [[ "$target" =~ ^dotfiles/ ]] && continue
    fi
    
    # Skip if already in dotfiles (check all packages)
    found=false
    for pkg in "$DOTFILES"/*/; do
        if [ -e "$pkg/$basename" ]; then
            found=true
            break
        fi
    done
    $found && continue
    
    # Add to list
    root_configs+=("$item")
done

# Check ~/.config items
if [ -d ~/.config ]; then
    for item in ~/.config/*; do
        basename=$(basename "$item")
        
        # Skip if symlink to dotfiles
        if [ -L "$item" ]; then
            target=$(readlink "$item")
            [[ "$target" =~ ^\.\./dotfiles/ ]] && continue
        fi
        
        # Skip if already in dotfiles
        [ -d "$DOTFILES/$basename/.config/$basename" ] && continue

        # Skip if ignored
        is_ignored ".config/$basename" && continue
        
        # Add to list
        config_items+=("$item")
    done
fi

# Display findings
echo "=== Found Unstowed Configs ==="
echo ""

if [ ${#root_configs[@]} -eq 0 ] && [ ${#config_items[@]} -eq 0 ]; then
    echo "✓ All configs are stowed! Nothing to add."
    echo ""
    exit 0
fi

echo "Root-level dotfiles:"
for item in "${root_configs[@]}"; do
    echo "  - $(basename "$item")"
    if [ -d "$item" ]; then
        size=$(du -sh "$item" 2>/dev/null | cut -f1)
        echo "    (directory, $size)"
    else
        size=$(ls -lh "$item" 2>/dev/null | awk '{print $5}')
        echo "    (file, $size)"
    fi
done

echo ""
echo "~/.config items:"
for item in "${config_items[@]}"; do
    echo "  - $(basename "$item")"
    if [ -d "$item" ]; then
        size=$(du -sh "$item" 2>/dev/null | cut -f1)
        echo "    (directory, $size)"
    else
        size=$(ls -lh "$item" 2>/dev/null | awk '{print $5}')
        echo "    (file, $size)"
    fi
done

echo ""
echo "=== Interactive Add to Dotfiles ==="
echo ""

# Function to add a root-level config
add_root_config() {
    local item=$1
    local basename=$(basename "$item")
    
    # Determine package name (remove leading dot)
    local pkg_name=${basename#.}
    
    echo ""
    echo "Adding: $basename"
    read -p "Package name [$pkg_name]: " custom_pkg
    [[ -n "$custom_pkg" ]] && pkg_name="$custom_pkg"
    
    # Create package
    mkdir -p "$DOTFILES/$pkg_name"
    
    # Copy to dotfiles
    cp -r "$item" "$DOTFILES/$pkg_name/"
    echo "  ✓ Copied to $DOTFILES/$pkg_name/"
    
    # Remove original and stow
    rm -rf "$item"
    cd "$DOTFILES"
    stow "$pkg_name"
    echo "  ✓ Stowed $pkg_name"
    
    # Git add if in repo
    if [ -d "$DOTFILES/.git" ]; then
        cd "$DOTFILES"
        git add "$pkg_name"
        echo "  ✓ Added to git (not committed)"
    fi
}

# Function to add a .config item
add_config_item() {
    local item=$1
    local basename=$(basename "$item")
    
    echo ""
    echo "Adding: .config/$basename"
    read -p "Package name [$basename]: " custom_pkg
    [[ -z "$custom_pkg" ]] && custom_pkg="$basename"
    
    # Create package
    mkdir -p "$DOTFILES/$custom_pkg/.config"
    
    # Copy to dotfiles
    cp -r "$item" "$DOTFILES/$custom_pkg/.config/"
    echo "  ✓ Copied to $DOTFILES/$custom_pkg/.config/"
    
    # Remove original and stow
    rm -rf "$item"
    cd "$DOTFILES"
    stow "$custom_pkg"
    echo "  ✓ Stowed $custom_pkg"
    
    # Git add if in repo
    if [ -d "$DOTFILES/.git" ]; then
        cd "$DOTFILES"
        git add "$custom_pkg"
        echo "  ✓ Added to git (not committed)"
    fi
}

# Process root-level configs
for item in "${root_configs[@]}"; do
    basename=$(basename "$item")
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Config: $basename"
    
    read -p "Add to dotfiles? (y/N/q to quit) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Qq]$ ]]; then
        echo "Quitting."
        exit 0
    fi
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        add_root_config "$item"
    else
        echo "  Skipped."
    fi
done

# Process .config items
for item in "${config_items[@]}"; do
    basename=$(basename "$item")
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Config: .config/$basename"
    
    read -p "Add to dotfiles? (y/N/q to quit) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Qq]$ ]]; then
        echo "Quitting."
        exit 0
    fi
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        add_config_item "$item"
    else
        echo "  Skipped."
    fi
done

echo ""
echo "✅ Done!"
echo ""
if [ -d "$DOTFILES/.git" ]; then
    echo "📝 Don't forget to commit your changes:"
    echo "   cd ~/dotfiles && git status && git commit -m 'Add new configs'"
fi
echo ""
