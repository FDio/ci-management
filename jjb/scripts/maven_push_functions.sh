#!/bin/bash
set -xe -o pipefail
echo "*******************************************************************"
echo "* STARTING PUSH OF PACKAGES TO REPOS"
echo "* NOTHING THAT HAPPENS BELOW THIS POINT IS RELATED TO BUILD FAILURE"
echo "*******************************************************************"

[ "$MVN" ] || MVN="/opt/apache/maven/bin/mvn"
GROUP_ID="io.fd.${PROJECT}"
BASEURL="${NEXUSPROXY}/content/repositories/fd.io."
BASEREPOID='fdio-'

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
    $MVN -B org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
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

    # examples:
    # * jvpp-registry-16.09.jar
    # * jvpp-16.09.jar

    basefile=$(basename -s .jar "$jarfile")
    artifactId=$(echo "$basefile" | rev | cut -d '-' -f 2-  | rev)
    version=$(echo "$basefile" | rev | cut -d '-' -f 1  | rev)

    push_file "$jarfile" "$repoId" "$url" "${version}-SNAPSHOT" "$artifactId" jar
}

function push_deb ()
{
    debfile=$1
    repoId="fd.io.${REPO_NAME}"
    url="${BASEURL}${REPO_NAME}"

    basefile=$(basename -s .deb "$debfile")
    artifactId=$(echo "$basefile" | cut -f 1 -d '_')
    version=$(echo "$basefile" | cut -f 2- -d '_')
    file_type=deb
    classifier=deb

    push_file "$debfile" "$repoId" "$url" "$version" "$artifactId" "$file_type" "$classifier"
}

function push_rpm ()
{
    rpmfile=$1
    repoId="fd.io.${REPO_NAME}"
    url="${BASEURL}${REPO_NAME}"

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
