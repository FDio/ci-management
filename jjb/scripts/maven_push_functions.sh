#!/bin/bash

echo "*******************************************************************"
echo "* STARTING PUSH OF PACKAGES TO REPOS"
echo "* NOTHING THAT HAPPENS BELOW THIS POINT IS RELATED TO BUILD FAILURE"
echo "*******************************************************************"

MVN="/opt/apache/maven/bin/mvn"
GROUP_ID="io.fd.${PROJECT}"
BASEURL="${NEXUSPROXY}/content/repositories/fd.io."
BASEREPOID='fdio-'

# Determine the path to maven
if [ -n "${MAVEN_SELECTOR}" ]
then
    MVN=${MVN:-"${HOME}/tools/hudson.tasks.Maven_MavenInstallation/${MAVEN_SELECTOR}/bin/mvn"}
else
    MVN="echo $(which mvn)"
fi

function push_file ()
{
    push_file=$1
    repoId=$2
    url=$3
    version=$4
    artifactId=$5
    file_type=$6

    if [ -n "$7" ]; then
        d_classifier="-Dclassifier=$7"
    fi

    if [ ! -f "$push_file" ] ; then
        echo "file for deployment does not exist: $push_file"
        exit 1;
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
    repoId=${2:-"${BASEREPOID}snapshot"}
    url=${3:-"${BASEURL}snapshot"}

    basefile=$(basename -s .jar "$jarfile")
    artifactId=$(echo "$basefile" | cut -f 1 -d '-')
    version=${4:-$(echo "$basefile" | cut -f 2 -d '-')}
    if [ -z "$4" ] ; then version="${version}-SNAPSHOT" ; fi

    push_file "$jarfile" "$repoId" "$url" "$version" "$artifactId" jar
}

function push_deb ()
{
    debfile=$1
    repoId=${2:-"fd.io.${REPO_NAME}"}
    url=${3:-"${BASEURL}${REPO_NAME}"}

    basefile=$(basename -s .deb "$debfile")
    artifactId=$(echo "$basefile" | cut -f 1 -d '_')
    version=$(echo "$basefile" | cut -f 2- -d '_')

    push_file "$debfile" "$repoId" "$url" "$version" "$artifactId" deb
}

function push_rpm ()
{
    rpmfile=$1
    repoId=${2:-"fd.io.${REPO_NAME}"}
    url=${3:-"${BASEURL}${REPO_NAME}"}

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
