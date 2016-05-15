export MAVEN_SELECTOR=3.2.3
export ECHO=echo
OSES="ubuntu1404
ubuntu1604
centos7"
REPO_STREAM_PARTS="master
stable.test
stable.1606"

DEB_FILENAMES="vpp-1.0.0-100~gaa67d61_amd64.deb
    vpp-dbg-1.0.0-100~gaa67d61_amd64.deb
    vpp-dev-1.0.0-100~gaa67d61_amd64.deb
    vpp-dpdk-dev-1.0.0-100~gaa67d61_amd64.deb
    vpp-dpdk-dmks-1.0.0-100~gaa67d61_amd64.deb
    vpp-dpdk-lib-1.0.0-100~gaa67d61_amd64.deb"

RPM_FILENAMES="vpp-devel-1.0.0-321~gb270789.x86_64.rpm
vpp-lib-1.0.0-321~gb270789.x86_64.rpm
vpp-devel-1.0.0-321~gb270789.x86_64.rpm"

JAR_FILENAMES="jvpp-1.0.0-SNAPSHOT.jar"

echo "PACKAGE_FILENAMES[@]: ${PACKAGE_FILENAMES[@]}"

for OS in ${OSES};
do
    for REPO_STREAM_PART in ${REPO_STREAM_PARTS};do
        export OS=$OS
        if [ "${OS}" == "ubuntu1404" ];then
            export REPO_NAME="${REPO_STREAM_PART}.ubuntu.trusty.main"
            export TOUCH_LIST="$DEB_FILENAMES
            $JAR_FILENAMES"
        elif [ "${OS}" == "ubuntu1604" ]; then
            export REPO_NAME="${REPO_STREAM_PART}.ubuntu.xenial.main"
            export TOUCH_LIST="$DEB_FILENAMES
            $JAR_FILENAMES"
        elif [ "${OS}" == "centos7" ]; then
            export REPO_NAME="${REPO_STREAM_PART}.centos7"
            export TOUCH_LIST=$RPM_FILENAMES
        fi
        echo "OS: ${OS}"
        echo "REPO_STREAM_PART: ${REPO_STREAM_PART}"
        echo "REPO_NAME: ${REPO_NAME}"
        echo "TOUCH_LIST: ${TOUCH_LIST}"
        touch $TOUCH_LIST
        /bin/sh `dirname $0`/../../include-raw-vpp-maven-push.sh | awk '{$1="";print $0}'
        rm $TOUCH_LIST

    done
done