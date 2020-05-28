FROM ubuntu:18.04
MAINTAINER Ed Kern <ejk@cisco.com>
LABEL Description="CSIT shim container"
LABEL Vendor="cisco.com"
LABEL Version="1.2"

# Setup the environment
ENV DEBIAN_FRONTEND=noninteractive
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

ADD files/wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

# Install packages and Docker
RUN apt-get -q update \
 && apt-get install -y -qq \
        bash \
        curl \
        iproute2 \
        locales \
        ssh \
        sudo \
        tzdata \
        uuid-runtime \
 && curl -fsSL https://get.docker.com | sh \
 && rm -rf /var/lib/apt/lists/*

# Configure locales
RUN locale-gen en_US

RUN mkdir /var/run/sshd
RUN echo 'root:Csit1234' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Need volume for sidecar docker launches
VOLUME /var/lib/docker

# SSH to listen on port 6022 in shim
RUN echo 'Port 6022' >>/etc/ssh/sshd_config
RUN echo 'Port 6023' >>/etc/ssh/sshd_config
ADD files/badkeypub /root/.ssh/authorized_keys
ADD files/sshconfig /root/.ssh/config

# Start sshd by default
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
