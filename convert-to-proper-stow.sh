#!/bin/bash
# Script to convert ~/dotfiles to use proper GNU Stow structure
# This is OPTIONAL and more advanced - only run if you want to use stow properly

set -e

echo "=== Convert to Proper GNU Stow Structure ==="
echo ""
echo "This script will restructure ~/dotfiles to use proper stow packages."
echo "Your current manual symlinks work fine, so this is OPTIONAL."
echo ""
echo "Proper stow structure example:"
echo "  ~/dotfiles/bash/.bashrc"
echo "  ~/dotfiles/vim/.vim/"
echo "  ~/dotfiles/tmux/.tmux.conf"
echo ""
echo "Then you'd run: cd ~/dotfiles && stow bash vim tmux"
echo ""
echo "⚠️  WARNING: This requires manual reorganization!"
echo "⚠️  Your current setup works fine as-is."
echo ""
echo "Do you want to see a detailed conversion plan? (y/N)"
read response

if [[ "$response" =~ ^[Yy]$ ]]; then
    cat << 'PLAN'

## Conversion Plan to Proper Stow

### Current Structure (working, but not proper stow):
~/dotfiles/.bashrc
~/dotfiles/.vim/
~/dotfiles/.tmux.conf
~/dotfiles/.config/nvim/
... etc

### Proper Stow Structure Would Be:
~/dotfiles/bash/.bashrc
~/dotfiles/vim/.vim/
~/dotfiles/tmux/.tmux.conf
~/dotfiles/nvim/.config/nvim/
... etc

### Steps to Convert:
1. Create package directories:
   mkdir -p ~/dotfiles/{bash,vim,tmux,git,nvim}

2. Move files into packages:
   mv ~/dotfiles/.bashrc ~/dotfiles/bash/
   mv ~/dotfiles/.vim ~/dotfiles/vim/
   mv ~/dotfiles/.tmux.conf ~/dotfiles/tmux/
   mv ~/dotfiles/.gitconfig ~/dotfiles/git/
   
3. For .config items, create .config in each package:
   mkdir -p ~/dotfiles/nvim/.config
   mv ~/dotfiles/.config/nvim ~/dotfiles/nvim/.config/

4. Remove old symlinks:
   cd ~ && rm .bashrc .vim .tmux.conf .gitconfig

5. Use stow properly:
   cd ~/dotfiles
   stow bash vim tmux git nvim

### Recommendation:
Your current setup works fine! Only do this if you want to:
- Use stow's automatic conflict detection
- Have a cleaner package-based organization
- Match standard stow conventions

Otherwise, just run ~/stow-unstowed-files.sh and you're done!

PLAN
else
    echo "No problem! Your current setup works great."
    echo "Run ~/stow-unstowed-files.sh to finish stowing the 3 remaining files."
fi
