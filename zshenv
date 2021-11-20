if [[ -d "$XDG_CONFIG_HOME/zsh" ]]
then
        export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
	export ZPLUG_HOME="$ZDOTDIR/zplug"
fi
