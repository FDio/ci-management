
Standard Operating Procedures:

=== Environmental specifics ===

For the use of this document, the following environment variables
should be assumed set:

  CPPROJECT=fdio
  PVENAME=openstack-${CPPROJECT}

  LFID=cjcollier
  CP_NAME=FD.io
  CP_DOMAIN=fd.io
  VAGRANT_DEFAULT_PROVIDER=openstack
  RESEAL=1
  RUBY_VER=2.1.5
  LF_GIT=/usr/src/git/lf
  PVEPATH=${LF_GIT}/git.lf.org/${LFID}/python-virtual
  PVE_DIR=${PVEPATH}/${PVENAME}
  SERVER_NAME=${LFID}-vagrant

  RH_ARCH_32=i686
  RH_ARCH_64=x86_64
  DEB_ARCH_64=amd64
  DEB_ARCH_32=i386

  STACK_PROVIDER=vexxhost
  STACK_PORTAL=secure.${STACK_PROVIDER}.com
  STACK_ID_SERVER=auth.${STACK_PROVIDER}.net
  STACK_REGION_NAME=ca-ymq-1

  VAGRANT_DISTRIBUTOR=hashicorp
  VDIST_DOMAIN=releases.${VAGRANT_DISTRIBUTOR}.com
  # vagrant_${VDIST_VER}_${RH_ARCH_32}.deb
  # vagrant_${VDIST_VER}_${RH_ARCH_64}.deb
  VDIST_FILENAME=vagrant_${VDIST_VER}_${RH_ARCH}.deb
  # Ask the web server what its latest version is
  VDIST_VER=$(curl https://${VDIST_DOMAIN}/vagrant|html2text|awk -F_ '/_/ {print $2}'|sort|tail -1)
  VDIST_PATH=vagrant/${VDIST_VER}/${VDIST_FILENAME}
  VAGRANT_DISTFILE_URL=https://{$VDIST_DOMAIN}/${VDIST_PATH}

  GERRIT_HOSTNAME=gerrit.${CP_DOMAIN}
  GERRIT_DIR=${LF_GIT}/${GERRIT_HOSTNAME}
  CIADM_NAME=ci-management
  CIADM_DIR=${GERRIT_DIR}/${CIADM_NAME}
  RH_ARCH=${RH_ARCH_64}
  DEB_ARCH=${DEB_ARCH_64}
  PVERC=${PVE_DIR}/bin/activate

=== Establish Cloudstack Credentials ===

To get the correct configuration for the environment you will need
openstack credentials.  Those used for this project are managed by
${STACK_PROVIDER}.  Establish credentials through appropriate
channels.  Once credentials are acquired, visit this page:

https://${STACK_PORTAL}/console/#/account/credentials

The environment variables you need will be at the bottom of the page,
formatted as such:

 export OS_TENANT_NAME="00000000-0000-0000-0000-000000000000"
 export OS_USERNAME="00000000-0000-0000-0000-000000000000"
 export OS_PASSWORD="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
 export OS_AUTH_URL="https://${STACK_ID_SERVER}/v2.0/"
 export OS_REGION_NAME="${STACK_REGION_NAME}"

Save these lines to /tmp/openstack-credentials.sh

=== Establish a python-virtual environment ===

For Debian-based systems, be sure that you install the
virtualenvwrapper packages

 # Debian: sudo apt-get install virtualenvwrapper
 mkdir -p ${PVEPATH}
 cd ${PVEPATH}
 virtualenv ${PVENAME}
 cat /tmp/openstack-credentials.sh >> ${PVERC}
 source ${PVERC}
 pip install --upgrade pip setuptools
 pip install python-{cinder,glance,keystone,neutron,nova,openstack}client

=== Install your public key into the cloudstack environment ===

Via the web interface: https://${STACK_PORTAL}/console/v2.html#/compute/keypairs

This command will install your yubikey-backed ssh key:

  ssh-add -L | grep cardno | nova keypair-add --pub-key - ${LFID}

=== Establish the GUID of our network ===

Via the web interface: https://${STACK_PORTAL}/console/#/networking/networks

Command line:

 export NETID=$(nova network-list | awk "/${CPPROJECT}/ {print \$2}")
 grep -v '^NETID=' ${PVERC} | cat - > ${PVERC}
 echo "NETID=${NETID}" >> ${PVERC}

=== Install rbenv ===

==== Red Hat ====

 sudo yum install -y \
   git-core zlib zlib-devel gcc-c++ patch readline readline-devel \
   libyaml-devel libffi-devel openssl-devel make bzip2 autoconf \
   automake libtool bison curl sqlite-devel
 git clone git://github.com/sstephenson/rbenv.git ~/.rbenv
 eval $(echo 'export PATH="${HOME}/.rbenv/bin:${PATH}"' | tee -a ~/.bashrc)
 eval $(rbenv init -)
 time rbenv install ${RUBY_VER}

==== Debian ====

 sudo apt-get build-dep ruby
 sudo apt-get install rbenv ruby-build libssl-dev libreadline-dev
 eval $(rbenv init -)
 curl -fsSL https://gist.github.com/mislav/055441129184a1512bb5.txt > /tmp/debian-ssl-patch
 time rbenv install --patch ${RUBY_VER} < /tmp/debian-ssl-patch # 7m42.708s

==== Common ====

 rbenv local ${RUBY_VER}
 rbenv global ${RUBY_VER}
 grep 'rbenv init' ~/.bashrc || \
   echo 'eval "$(rbenv init -)"' >> ~/.bashrc && \
   echo "rbenv local ${RUBY_VER}" >> ~/.bashrc && \
   echo "rbenv global ${RUBY_VER}" >> ~/.bashrc

=== Install Vagrant, vagrant-openstack-provider ===

On Debian, you must uninstall the system vagrant and instead install
the upstream package:

  wget      -O ${VAGRANT_DISTFILE_NAME} ${VAGRANT_DISTFILE_URL}
  sudo dpkg -i ${VAGRANT_DISTFILE_NAME}
  vagrant plugin install vagrant-openstack-provider

=== Configure openstack 'dummy' box ===

CLI:
  vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box
  wget -P ~/.vagrant.d/boxes/dummy/0/openstack/ \
       https://raw.githubusercontent.com/cjac/scripts-n-things/master/vagrant/Vagrantfile
  vi ~/.vagrant.d/boxes/dummy/0/openstack/Vagrantfile

=== Check out the ci-management repo from gerrit ===

CLI:

  mkdir -p ${GERRIT_DIR}
  cd ${GERRIT_DIR}
  git clone ssh://${GERRIT_HOSTNAME}:29418/${CIADM_NAME}

=== Acquire base images ===

Cloud image links by platform:

CentOS: http://cloud.centos.org/centos/
Ubuntu: https://cloud-images.ubuntu.com/
Debian: http://cdimage.debian.org/cdimage/openstack/
Arch:   http://linuximages.de/openstack/arch/
Gentoo: http://linuximages.de/openstack/gentoo/

CLI:

 source ${CIADM_DIR}/vagrant/lib/respin-functions.sh

 download_deb_image 'Ubuntu' '14.04' 'amd64'
 download_deb_image 'Ubuntu' '16.04' 'amd64'
 download_deb_image 'Debian' 'stable' 'amd64'
 download_deb_image 'Debian' 'testing' 'amd64'
 download_deb_image 'Debian' 'unstable' 'amd64'
 download_rh_image 'CentOS' '7' 'x86_64'

=== Upload base images ===

CLI:

 source ${CIADM_DIR}/vagrant/lib/respin-functions.sh

 create_deb_image 'Ubuntu' '14.04' 'amd64'
 create_deb_image 'Ubuntu' '16.04' 'amd64'
 create_rh_image 'CentOS' '7' 'x86_64'


== Re-spin jcloud images ==

CLI:

  cd ${CIADM_DIR}/vagrant/basebuild
  source ${PVERC}

=== Manual bootstrap of Ubuntu 14.04 ===

CLI:
  export DIST='Ubuntu'
  export VERSION='14.04'
  export DST_TIMESTAMP=$(date +'%F T %T' | sed -e 's/[-: ]//g')
  export IMAGE="${DIST} ${VERSION} (${SRC_TIMESTAMP}) - LF upload"
  vagrant up

On manual bootstrap failure, one can connect to the VM using
  vagrant ssh

On success
  nova image-create --poll ${SERVER_NAME} "qq{$dist $version - basebuild - $isodate};"
