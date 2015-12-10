#!/bin/bash

# Determine the path to maven
if [ -z "${MAVEN_SELECTOR}" ]; then
    echo "ERROR: No Maven install detected!"
    exit 1
fi

MVN="${HOME}/tools/hudson.tasks.Maven_MavenInstallation/${MAVEN_SELECTOR}/bin/mvn"
GROUP_ID="info.projectrotterdam.${PROJECT}"
BASEURL="${NEXUSPROXY}/content/repositories/rotterdam."
BASEREPOID='rotterdam-'

# find the files
JARS=$(find . -type f -iname '*.jar')
DEBS=$(find . -type f -iname '*.deb')

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
    repoId="${BASEREPOID}dev"
    url="${BASEURL}dev"

    basefile=$(basename -s .deb "$debfile")
    artifactId=$(echo "$basefile" | cut -f 1 -d '_')
    version=$(echo "$basefile" | cut -f 2- -d '_')

    push_file "$debfile" "$repoId" "$url" "$version" "$artifactId" deb
}

for i in $JARS
do
    push_jar "$i"
done

for i in $DEBS
do
    push_deb "$i"
done

# vim: ts=4 sw=4 sts=4 et ft=sh :
