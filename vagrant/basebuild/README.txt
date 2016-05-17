
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

=== Acquire base images ===

Cloud image links by platform:

CentOS: http://cloud.centos.org/centos/
Ubuntu: https://cloud-images.ubuntu.com/
Debian: http://cdimage.debian.org/cdimage/openstack/
Arch:   http://linuximages.de/openstack/arch/
Gentoo: http://linuximages.de/openstack/gentoo/

CLI:



Review wiki page:

https://pdx-caf-support.int.codeaurora.org/wiki/openstack


https://lists.fd.io/pipermail/vpp-dev/2016-May/000992.html

To fix it, please:

Merge, button mash, and push a DO NOT MERGE probe patch to vpp to test:

1) Add capacity for honeycomb to verify images. https://gerrit.fd.io/r/#/c/1073/ 

So that we have the means to test new images against honeycomb (as images need to
be respun).

Merge:
2) Instrument Jenkins images/builds https://gerrit.fd.io/r/#/c/983/
3) Disable things which may lock /var/lib/dpkg/lock https://gerrit.fd.io/r/#/c/1128/ 
4) Add build dependencies for documentation https://gerrit.fd.io/r/#/c/1114/

5) Respin images
6) Stage them to verify-image-{os}
7) Submit a probe patch to vpp (as DO NOT MERGE) and comment 'verify-images' to check the new images against vpp
8) Submit a probe patch to honeycomb (as DO NOT MERGE) and comment 'verify-images' to check the new images against honeycomb
9) If and only if both probe patches pass verify-images, deploy the new images
10) Abandon the vpp and honeycomb probe patches

Ed
