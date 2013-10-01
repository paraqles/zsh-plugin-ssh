
ssh_config_add_endpoint() {
  if [[ -x $SSH_USER_CONFIG ]]; then
    touch $SSH_USER_CONFIG
  fi
  echo "
# SSH Endpoint for $1
Host $1
  HostName $1
  PreferredAuthentications publickey
  IdentityFile $2" >> $SSH_USER_CONFIG
  if [[ $# > 3 ]]; then
    echo "  User: $3" >> $SSH_USER_CONFIG
  fi
  echo "
" >> $SSH_USER_CONFIG
}
