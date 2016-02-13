SSH server with certificate support
===================================

[![](https://badge.imagelayers.io/rjrivero/baseimage-ssh:latest.svg)](https://imagelayers.io/?images=rjrivero/baseimage-ssh:latest 'Get your own badge on imagelayers.io')

This is a base container image built upon [baseimage-docker](https://github.com/phusion/baseimage-docker), that enables the ssh service and allows user login with certificates.

  - See [baseimage-docker](https://github.com/phusion/baseimage-docker) for information on how to use this image as a base.
  - See (https://www.digitalocean.com/community/tutorials/how-to-create-an-ssh-ca-to-validate-hosts-and-clients-with-ubuntu) for further reference on how to use certificates with SSH.

Usage
-----

From Docker registry:

```
docker pull rjrivero/baseimage-ssh
```

Or build yourself:

```
git clone https://github.com/rjrivero/docker-baseimage-ssh.git
docker build --rm -t rjrivero/baseimage-ssh docker-baseimage-ssh
```

Running the image:

```
docker run --rm -it --name ssh-container -v </path/to/your/ca/cert.pub>:/etc/ssh/users_ca.pub rjrivero/baseimage-ssh
```

Use in your Dockerfile:

```
FROM rjrivero/baseimage-ssh:<tag>
```

SSH Certificates
----------------

This image's *sshd_config* file is modified to accept a CA signing certificate. The certificate must be mounted at **/etc/ssh/users_ca.pub**. You mount your certificate adding a *-v* flag to the docker command:

```
-v </path/to/your/signing/certificate.pub>:/etc/ssh/users_ca.pub
```

You generate your signing certificate first using **ssh-keygen**:

```
ssh-keygen -b 4096 -f users_ca
```

It is recommended that you set a strong password for your root CA certificate. Then you sign the **id_rsa.pub** file from your *~/.ssh* folder with the signing certificate:

```
ssh-keygen -s users_ca -I "Your Name" -n root -V +52w ~/.ssh/id_rsa.pub
```

You are asked for the password you entered when creating the root CA cert, and then the tool generates a signed certificate valid for *52 weeks* (roughly a year), which is what the *+52w* stands for in the command line.

The generated certificate is saved as **~/.ssh/id_rsa-cert.pub**. Now you can log into the container as the *root* user without providing any password:

```
CONTAINER_IP=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' ssh-container`
ssh -a -l root $CONTAINER_IP
```

Adding users at build time
--------------------------

You can add users to the container at build time, so later on you can log into it using an unprivileged user account instead of *root*. In your Dockerfile:

```
# Add unprivileged user
RUN useradd -m -s /bin/bash -p PASSWORD myuser
``` 

You need to set a password to have the account unlocked. Otherwise you won't be able to ssh in, even when ssh login with passwords is actually disabled.

You can configure your users according to your needs, including adding them to any required group, for example:

```
# Allow my unprivileged user to run sudo
RUN usermod -a -G sudo myuser
```

If you are generating random user passwords, you won't be able to run sudo unless you first log into the container as root and reset the user's password to a known one. A different approach would be adding a file inside */etc/sudoers.d/*, with the following contents:

```
myuser ALL = (ALL) NOPASSWD:ALL
```

That will allow your user to run passwordless sudo. You **must** set the file permissions to **0440**, otherwise it won't work.

Adding users at boot time
-------------------------

You can also add your user at boot time instead of build time. You only need to provide the following environment variables when launching the container with docker:

  - NEWUSER: Username to add.

  - NEWUSER_UID: UID you want for the new user, defaults to 1000.

  - NEWUSER_GROUPS: Comma-separated list of groups to add your user to.

  - NEWUSER_SUDO: If **YES**, the user can run passwordless sudo.

For example, if you want to add an user named **myuser**, with UID **955**, in groups **sudo** and **audio**, and capable of passwordless sudo, you run:

```
docker run --rm -it --name ssh-container \
    -v </path/to/your/ca/cert.pub>:/etc/ssh/users_ca.pub \
    -e NEWUSER=myuser \
    -e NEWUSER_UID=995 \
    -e NEWUSER_GROUPS=sudo,audio \
    -e NEWUSER_SUDO=YES \
    rjrivero/baseimage-ssh

Login as non root user
----------------------

If you have built or booted your container with an unprivileged user account *myuser*, and want to log in as that user, you must generate your certificate accordingly. Instead of *root*, you will have to provide the proper username to *ssh-keygen*:

```
ssh-keygen -s users_ca -I "Your Name" -n myuser -V +52w id_rsa.pub
cp id_rsa-cert.pub ~/.ssh/

CONTAINER_IP=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' ssh-container`
ssh -a -l myuser $CONTAINER_IP
```

Managing several identities
---------------------------

If you need several certificates for several different usernames, you will need as many private keys as identities. For example, if you need to login as *www-data* in one server and as *pgsql* in other, you would:

  - Generate new identity files per username

```
ssh-keygen -f ~/.ssh/www-data_rsa
ssh-keygen -f ~/.ssh/pgsql_rsa
```

  - Generate a signed certificate per identity

```
ssh-keygen -s users_ca -I "My Name" -n www-data ~/.ssh/www-data_rsa.pub
ssh-keygen -s users_ca -I "My Name" -n pgsql    ~/.ssh/pgsql_rsa.pub

cp www-data_rsa-cert.pub ~/.ssh
cp pgsql_rsa-cert.pub    ~/.ssh
```

  - Use the **-i** flag to specify the proper identity to the ssh client when connecting to the server

```
ssh -a -l www-data -i ~/.ssh/www-data_rsa www-data-server
ssh -a -l pgsql    -i ~/.ssh/pgsql_rsa    pgsql-server
```
