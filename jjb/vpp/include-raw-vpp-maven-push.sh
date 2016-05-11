#!/bin/bash

# Determine the path to maven
if [ -z "${MAVEN_SELECTOR}" ]; then
    echo "ERROR: No Maven install detected!"
    exit 1
fi

MVN="${HOME}/tools/hudson.tasks.Maven_MavenInstallation/${MAVEN_SELECTOR}/bin/mvn"
GROUP_ID="io.fd.${PROJECT}"
BASEURL="${NEXUSPROXY}/content/repositories/fd.io."
BASEREPOID='fdio-'
declare -A REPO_TARGET
REPOID_TARGET=(
    [master:ubuntu1404]="${BASEREPOID}master.ubuntu.trusty.main"
    [master:ubuntu1604]="${BASEREPOID}master.ubuntu.xenial.main"
    [master:centos7]="${BASEREPOID}master.centos7"
    [stable/test:ubuntu1404]="${BASEREPOID}stable.test.ubuntu.trusty.main"
    [stable/test:ubuntu1604]="${BASEREPOID}stable.test.ubuntu.xenial.main"
    [stable/test:centos7]="${BASEREPOID}stable.test.centos7"
    [stable/1606:ubuntu1404]="${BASEREPOID}stable.1606.ubuntu.trusty.main"
    [stable/1606:ubuntu1604]="${BASEREPOID}stable.1606.ubuntu.xenial.main"
    [stable/1606:centos7]="${BASEREPOID}stable.1606.centos7"
)
declare -A REPOURL_TARGET
REPOURL_TARGET=(
    [master:ubuntu1404]="${BASEURL}master.ubuntu.trusty.main"
    [master:ubuntu1604]="${BASEURL}master.ubuntu.xenial.main"
    [master:centos7]="${BASEURL}master.centos7"
    [stable/test:ubuntu1404]="${BASEURL}stable.test.ubuntu.trusty.main"
    [stable/test:ubuntu1604]="${BASEURL}stable.test.ubuntu.xenial.main"
    [stable/test:centos7]="${BASEURL}stable.test.centos7"
    [stable/1606:ubuntu1404]="${BASEURL}stable.1606.ubuntu.trusty.main"
    [stable/1606:ubuntu1604]="${BASEURL}stable.1606.ubuntu.xenial.main"
    [stable/1606:centos7]="${BASEURL}stable.1606.centos7"
)

function push_file ()
{
    push_file=$1
    repoId=$2
    url=$3
    version=$4
    artifactId=$5
    file_type=$6
    classifier=$7

    if [ "$classifier" ]; then
        d_classifier="-Dclassifier=$7"
    fi

    # Disable checks for doublequote to prevent glob / splitting
    # shellcheck disable=SC2086
    $MVN org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$push_file -DrepositoryId=$repoId \
        -Durl=$url -DgroupId=$GROUP_ID \
        -Dversion=$version -DartifactId=$artifactId \
        -Dtype=$file_type $d_classifier\
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE

    # make sure the script bombs if we fail an upload
    if [ "$?" != '0' ]; then
        echo "ERROR: There was an error with the upload"
        exit 1
    fi
}

function push_jar ()
{
    jarfile=$1
    repoId="${BASEREPOID}snapshot"
    url="${BASEURL}snapshot"

    basefile=$(basename -s .jar "$jarfile")
    artifactId=$(echo "$basefile" | cut -f 1 -d '-')
    version=$(echo "$basefile" | cut -f 2 -d '-')

    push_file "$jarfile" "$repoId" "$url" "${version}-SNAPSHOT" "$artifactId" jar
}

function push_deb ()
{
    debfile=$1
    repoId=${REPOID_TARGET[${GERRIT_BRANCH}:${OS}]}
    url="${REPOURL_TARGET[${GERRIT_BRANCH}:${OS}]}"

    basefile=$(basename -s .deb "$debfile")
    artifactId=$(echo "$basefile" | cut -f 1 -d '_')
    version=$(echo "$basefile" | cut -f 2- -d '_')

    push_file "$debfile" "$repoId" "$url" "$version" "$artifactId" deb
}

function push_rpm ()
{
    rpmfile=$1
    repoId=${REPOID_TARGET[${GERRIT_BRANCH}:${OS}]}
    url="${REPOURL_TARGET[${GERRIT_BRANCH}:${OS}]}"

    if grep -qE '\.s(rc\.)?rpm' <<<"$rpmfile"
    then
        rpmrelease=$(rpm -qp --queryformat="%{release}.src" "$rpmfile")
    else
        rpmrelease=$(rpm -qp --queryformat="%{release}.%{arch}" "$rpmfile")
    fi
    artifactId=$(rpm -qp --queryformat="%{name}" "$rpmfile")
    version=$(rpm -qp --queryformat="%{version}" "$rpmfile")
    push_file "$rpmfile" "$repoId" "$url" "${version}-${rpmrelease}" "$artifactId" rpm
}

if [ "${OS}" == "ubuntu1404" ]; then
    # Find the files
    JARS=$(find . -type f -iname '*.jar')
    DEBS=$(find . -type f -iname '*.deb')
    for i in $JARS
    do
        push_jar "$i"
    done

    for i in $DEBS
    do
        push_deb "$i"
    done
elif [ "${OS}" == "ubuntu1604" ]; then
    DEBS=$(find . -type f -iname '*.deb')
    for i in $DEBS
    do
        push_deb "$i"
    done
elif [ "${OS}" == "centos7" ]; then
    # Find the files
    RPMS=$(find . -type f -iname '*.rpm')
    SRPMS=$(find . -type f -iname '*.srpm')
    SRCRPMS=$(find . -type f -name '*.src.rpm')
    for i in $RPMS $SRPMS $SRCRPMS
    do
        push_rpm "$i"
    done
fi
# vim: ts=4 sw=4 sts=4 et ft=sh :
