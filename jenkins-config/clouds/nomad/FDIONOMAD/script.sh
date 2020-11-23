#!/bin/bash
set -euo pipefail
#testing only will be removed

mktmpdir(){
  tmpdir=$(mktemp -d)
}

path="."
mktmpdir

files=()
while read -d $'\n'; do
     if [[ $REPLY =~ cloud.yaml ]];then
       cloudfile=$REPLY
     elif [[ $REPLY =~ defaults.yaml ]];then
       defaultsfile=$REPLY
     else
       files+=("$REPLY")
     fi
done < <(find "$path" -name "*.yaml" )

cp "${files[@]}" "$tmpdir"
cp $cloudfile "$tmpdir"
cp $defaultsfile "$tmpdir"

cd $tmpdir
 
for file in ${files[@]}; do
  yq3 merge "$defaultsfile" $file > tmpfile
  cp tmpfile $file
done

yq3 merge --arrays append "${files[@]}" > umerged.yaml

#yq3 m -x $defaultsfile umerged.yaml > withdefaults.yaml


yq3 p -- umerged.yaml  "jenkins.clouds[+] nomad" > nmerged.yaml
yq3 m --arrays update cloud.yaml nmerged.yaml > final.yaml
yq3 w -d'*' final.yaml 'jenkins.clouds[0].nomad.templates[*].password' somepassword

#
#rm -f umerged.yaml withdefaults.yaml nmerged.yaml final.yaml
cd ..
rm -rf $tmpdir
