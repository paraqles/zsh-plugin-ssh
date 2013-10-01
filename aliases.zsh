for al in `ls $ZSH_PLUGIN_SSH_DIR/aliases.*.zsh`; do
  source $al
done

alias sshcd='cd $HOME/.ssh'
alias sshae='ssh_config_add_endpoint'
