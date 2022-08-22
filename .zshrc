alias ohmyzsh="source ~/.oh-my-zsh"
alias tb="cd ~/code/truebill"
alias tb.api="cd ~/code/truebill/packages/web"
alias tb.admin="cd ~/code/truebill/admin-client"
alias tb.n="cd ~/code/truebill-native"
alias tb.ops="cd ~/code/ops"
alias tb.prod.connect="~/code/truebill/scripts/ops/tb-remote-postgres/tb-remote-postgres.sh"
alias tb.web="cd ~/code/truebill/web-client"
alias tb.deserve="convox proxy --tls -r staging 4443:sandbox-platform.deserve.com:443"
alias tb.debug='open "rndebugger://set-debugger-loc?host=localhost&port=8081"'
eval "$(direnv hook zsh)"

source ~/.truebillrc

#funct
killp(){
  kill -9 $(lsof -t -i:$1)
}

snakeenvold() {
  this_dir=${PWD##*/}
  conda create -n "$this_dir" python=2.7
}

snakeenv() {
    this_dir=${PWD##*/}
    conda create -n "$this_dir" python=3.8
}

snakework() {
    this_dir=${PWD##*/}
    conda activate $this_dir
}

snakeremove() {
    this_dir=${PWD##*/}
    conda deactivate
    conda env remove --name $this_dir
}


##### BEGIN LIBS SETUP 
#
export GITSTATUS_LOG_LEVEL=DEBUG
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
export PATH=$HOME/bin:/usr/local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(1password aliases git gitignore git-extras heroku node postgres rbenv taskwarrior thefuck web-search yarn)

source $ZSH/oh-my-zsh.sh

export JAVA_HOME="/Applications/Android Studio.app/Contents/jre/Contents/Home"
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/EFrost/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/EFrost/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/EFrost/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/EFrost/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

##### END LIBS SETUP

### Sourced Configs
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
