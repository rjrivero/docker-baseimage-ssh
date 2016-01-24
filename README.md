SSH server with certificate support
===================================

This is a base container image built upon
[baseimage-docker](https://github.com/phusion/baseimage-docker),
that enables the ssh service and allows user login with certificates.

  - See [baseimage-docker](https://github.com/phusion/baseimage-docker)
    for information on how to use this image as a base.
  - See (https://www.digitalocean.com/community/tutorials/how-to-create-an-ssh-ca-to-validate-hosts-and-clients-with-ubuntu)
    for further reference on how to use certificates with SSH.

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

This image's *sshd_config* file is modified so it accepts a CA signing
certificate. The certificate must be volume-mounted at
**/etc/ssh/users_ca.pub**. You mount your certificate at that path
adding a *-v* flag to the docker command:

```
-v </path/to/your/signing/certificate>:/etc/ssh/users_ca.pub
```

You generate your signing certificate first using **ssh-keygen**:

```
ssh-keygen -b 4096 -f users_ca
```

It is recommended that you set a strong password for your root CA certificate.
Then you copy the **id_rsa.pub** file from your user and sign it with
the previous cert:

```
ssh-keygen -s users_ca -I "Your Name" -n root -V +52w id_rsa.pub
```

You are asked for the password you entered when creating the root CA cert,
and then the tool generates a signed certificate valid for *52 weeks* (roughly
a year), which is what the *+52w* stands for in the command line.

The generated certificate is saved as **id_rsa-cert.pub**. You just copy
it to your .ssh folder:

```
cp id_rsa-cert.pub ~/.ssh/
```

That's all, you can now log into the container as the *root* user without
providing any password:

```
CONTAINER_IP=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' ssh-container`
ssh -a -l root $CONTAINER_IP
```

You can create a different user in your Dockerfile, and then log in as
that user, if you sign your certificate with the proper username
instead of *root*. In your Dockerfile:

```
# Add unprivileged user to perform any task you want
RUN useradd -m -s /bin/bash -p PASSWORD myuser
``` 

You need to set a password to have the account unlocked. Otherwise
you won't be able to ssh in, even when you are using certificates
instead of passwords.

Then, from your command line:

```
ssh-keygen -s users_ca -I "Your Name" -n myuser -V +52w id_rsa.pub
cp id_rsa-cert.pub ~/.ssh/

CONTAINER_IP=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' ssh-container`
ssh -a -l myuser $CONTAINER_IP
```

Managing several identities
---------------------------

If you need several certificates for several different usernames, you will
need as many private keys as identities.
For example, if you need to login as *www-data* in one server and as *pgsql*
in other, you better:

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

  - Use the **-i** flag to specify the proper identity to the ssh client

```
ssh -a -l www-data -i ~/.ssh/www-data_rsa www-data-server
ssh -a -l pgsql    -i ~/.ssh/pgsql_rsa    pgsql-server
```
