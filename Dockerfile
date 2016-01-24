# SSH server based on baseimage-docker, with support for
# SSH certificates.

# I know I should attach to a particular revision... but
# let's just ride on *master* for the time being
FROM phusion/baseimage:latest

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN rm -f /etc/service/sshd/down

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
# RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Volume holding the user's CA certificate
# VOLUME /etc/ssh/users_ca.pub

# Add the proper configuration to SSH config file
ADD config_ssh.sh /tmp/config_ssh.sh
RUN /tmp/config_ssh.sh && rm -f /tmp/config_ssh.sh
