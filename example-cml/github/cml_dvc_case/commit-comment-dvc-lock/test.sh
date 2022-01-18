if [[ $(git status --porcelain | grep '.tx') ]]; then
echo 'commit'
fi