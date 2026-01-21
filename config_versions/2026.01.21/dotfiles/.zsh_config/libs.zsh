export TOOLS_PATH="$HOME/software"
export PATH="$PATH:$TOOLS_PATH/depot_tools"
export PATH="/Applications/MacVim.app/Contents/bin:$PATH"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.exo/bin"

fpath=(~/software/zellij/completion $fpath)
complete -C '$(which aws_completer)' awslocal

if [ -n "$TMUX" ] && [ -n "$DIRENV_DIR" ]; then
    direnv reload
fi
