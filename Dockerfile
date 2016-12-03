# Zato web-admin

FROM ubuntu:14.04
MAINTAINER Rafał Krysiak <rafal@zato.io>

RUN ln -s -f /bin/true /usr/bin/chfn

# Install helper programs used during Zato installation
RUN apt-get update && apt-get install -y apt-transport-https \
    python-software-properties \
    software-properties-common \
    curl \
    telnet \
    wget

# Add the package signing key
RUN curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | sudo apt-key add -

# Add Zato repo to your apt
# update sources and install Zato
RUN apt-add-repository https://zato.io/repo/stable/2.0/ubuntu
RUN apt-get update && apt-get install -y zato

COPY zato_update_password.config /opt/zato/
RUN chmod 755 /opt/zato/zato_update_password.config
RUN chown zato:zato /opt/zato/zato_update_password.config

USER zato

EXPOSE 8183

# Prepare additional config files, CA certificates, keys and starter scripts
RUN mkdir /opt/zato/ca
COPY certs /opt/zato/certs
COPY zato_web_admin.config /opt/zato/

COPY zato_start_web_admin /opt/zato/
COPY zato_from_config_create_web_admin /opt/zato/
COPY zato_from_config_update_password /opt/zato/
USER root
RUN chmod 755 /opt/zato/zato_start_web_admin /opt/zato/zato_from_config_create_web_admin \
              /opt/zato/zato_from_config_update_password


USER zato
RUN rm -rf /opt/zato/env/web-admin && mkdir -p /opt/zato/env/web-admin

# Set a password for an user and append it to a config file
WORKDIR /opt/zato
RUN touch /opt/zato/web_admin_password
RUN uuidgen > /opt/zato/web_admin_password
WORKDIR /opt/zato
RUN echo 'password'=$(cat /opt/zato/web_admin_password) >> /opt/zato/zato_update_password.config

CMD ["/opt/zato/zato_start_web_admin"]
