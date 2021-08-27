# Clone dotfiles repo
local_repo=~/shizen-os
origin="https://github.com/maxpower24/shizen-os.git"
cd $local_repo
git init
git fetch $origin
git checkout -b main $origin
git pull $origin main

# Copy config and other dotfile data
cp -r $local_repo/wallpapers ~/pics
cp -r $local_repo/dotfiles/. ~