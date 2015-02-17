for al in `ls aliases.*.zsh`; do
  source $al
done

alias sshcd='cd $HOME/.ssh'
alias sshae='ssh_config_add_endpoint'
