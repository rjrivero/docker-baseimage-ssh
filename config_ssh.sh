#!/usr/bin/env sh

# Add TrustedUserCAKeys to the sshd config file,
# and disable password authentication
cat <<EOF >> /etc/ssh/sshd_config
TrustedUserCAKeys /etc/ssh/users_ca.pub
PasswordAuthentication no
EOF
