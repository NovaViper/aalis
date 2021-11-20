# If not running interactively, don't do anything
[[ $- != *i* ]] && return

###
# Variable Declaration and Initalization
###
termcol="$(tput colors)"
source /usr/share/zsh/scripts/zplug/init.zsh

###
# Zplug initalization
###

### Add Plugins
zplug "romkatv/powerlevel10k", as:theme, depth:1
zplug "jeffreytse/zsh-vi-mode"
zplug "plugins/sudo", from:oh-my-zsh
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-history-substring-search"
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"
#zplug "zpm-zsh/ssh"
zplug "plugins/emacs", from:oh-my-zsh

## Non tty plugins
if [ $termcol = 256 ] ; then
  zplug "kutsan/zsh-system-clipboard"
fi

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

clear
neofetch --ascii_distro arch_small

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Then, source plugins and add commands to $PATH
zplug load

#### 
# User Configurations
####

HISTFILE=~/.config/zsh/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

#Enable AutoCD into dir, terminal bell, and terminal notify
setopt autocd beep notify

# Enable Vi mode
bindkey -v

# History scroll
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
if [ $termcol != 256 ] ; then
#  echo 'Mnimal Mode'
#  echo $termcol
#  sleep 5
  [[ ! -f /etc/skel/.p10k_min.zsh ]] || source /etc/skel/.p10k_min.zsh
else
#  echo 'Full Mode'
#  echo $termcol
#  sleep 5
  [[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
fi
