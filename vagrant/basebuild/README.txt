
Standard Operating Procedures:

=== Establish Cloudstack Credentials ===

To get the correct configuration for the environment you will need
openstack credentials.  Those used for this project are managed by
vexxhost.  Establish credentials through appropriate channels.  Once
credentials are acquired, visit this page:

https://secure.vexxhost.com/console/#/account/credentials

The environment variables you need will be at the bottom of the page,
formatted as such:

 export OS_TENANT_NAME="00000000-0000-0000-0000-000000000000"
 export OS_USERNAME="00000000-0000-0000-0000-000000000000"
 export OS_PASSWORD="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
 export OS_AUTH_URL="https://auth.vexxhost.net/v2.0/"
 export OS_REGION_NAME="ca-ymq-1"

Save these lines to /tmp/openstack-credentials.sh

=== Establish a python-virtual environment ===

For Debian-based systems, be sure that you install these packages:
* libpython-dev
* python-virtualenv

 CPPROJECT=fdio

 export PVENAME=openstack-${CPPROJECT}
 export PVEPATH=/usr/src/git/lf/git.lf.org/cjcollier/python-virtual
 export PVERC=${PVEPATH}/${PVENAME}/bin/activate
 mkdir -p ${PVEPATH}
 cd ${PVEPATH}
 virtualenv ${PVENAME}
 cat /tmp/openstack-credentials.sh >> ${PVERC}
 source  ${PVERC}
 pip install --upgrade pip setuptools
 pip install python-{cinder,glance,keystone,neutron,nova,openstack}client

=== Install your public key into the cloudstack environment ===

https://secure.vexxhost.com/console/v2.html#/compute/keypairs

This will install your yubikey-backed ssh key:

  ssh-add -L | grep cardno | nova keypair-add --pub-key - $USER

=== Establish the GUID of our network ===

Via the web interface: https://secure.vexxhost.com/console/#/networking/networks

Command line:

 NETID=$(nova network-list | awk '/${CPPROJECT}/ {print $2}')
 echo "NETID=${NETID}" >> ${PVERC}

=== Install Vagrant, vagrant-openstack-provider ===

On Debian, you must uninstall the system vagrant and instead install the
upstream package:

  # https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_i686.deb
  wget https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_${RH_ARCH}.deb
  sudo dpkg -i vagrant_1.8.1_${RH_ARCH}.deb
  vagrant plugin install vagrant-openstack-provider

=== Configure openstack 'dummy' box ===

CLI:
  vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box
  wget -P ~/.vagrant.d/boxes/dummy/0/openstack/ https://raw.githubusercontent.com/cjac/scripts-n-things/master/vagrant/Vagrantfile
  vi ~/.vagrant.d/boxes/dummy/0/openstack/Vagrantfile

=== Check out the ci-management branch from fdio gerrit ===

CLI:

 FDIO_GDIR=/usr/src/git/lf/gerrit.fd.io
 mkdir -p ${FDIO_GDIR}
 cd ${FDIO_GDIR}
 git clone ssh://gerrit.fd.io:29418/ci-management

=== Acquire base images ===

Cloud image links by platform:

CentOS: http://cloud.centos.org/centos/
Ubuntu: https://cloud-images.ubuntu.com/
Debian: http://cdimage.debian.org/cdimage/openstack/
Arch:   http://linuximages.de/openstack/arch/
Gentoo: http://linuximages.de/openstack/gentoo/

CLI:

 source ${FDIO_GDIR}/vagrant/lib/respin-functions.sh

 download_deb_image 'Ubuntu' '14.04' 'amd64'
 download_deb_image 'Ubuntu' '16.04' 'amd64'
 download_rh_image 'CentOS' '7' 'x86_64'

=== Upload base images ===

CLI:

 source ${FDIO_GDIR}/vagrant/lib/respin-functions.sh

 create_deb_image 'Ubuntu' '14.04' 'amd64'
 create_deb_image 'Ubuntu' '16.04' 'amd64'
 create_rh_image 'CentOS' '7' 'x86_64'


== Re-spin jcloud images ==

CLI:

  export VAGRANT_DEFAULT_PROVIDER=openstack
  export SERVER_NAME=kf7bmp-vagrant
  export RESEAL=1
  cd $FDIO_GDIR/ci-management/vagrant/basebuild

  source ${FDIO_GDIR}/vagrant/lib/respin-functions.sh
  respin_deb_image 'Ubuntu' '14.04' 'amd64'
  respin_deb_image 'Ubuntu' '16.04' 'amd64'
  respin_rh_image 'CentOS' '7' 'x86_64'


=== Verify images ===

* Update *-staging images at https://jenkins.fd.io/configure
* Submit a probe patch to vpp (as DO NOT MERGE) and comment 'verify-images' to check the new images against vpp
* Submit a probe patch to honeycomb (as DO NOT MERGE) and comment 'verify-images' to check the new images against honeycomb
* If and only if both probe patches pass verify-images, update remaining images at https://jenkins.fd.io/configure
* Abandon the vpp and honeycomb probe patches
