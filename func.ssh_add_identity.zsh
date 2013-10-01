
ssh_add_identity() {
  key_type='rsa'
  if [[ $# > 2 ]]; then
    key_type=$2
  fi
  if [[ -x $SSH_USER_DIR/ids/id_$1_$key_type ]]; then
    ssh-add $SSH_USER_DIR/ids/id_$1_$key_type
  else
    echo "Identity does not exit!"
  fi
}
