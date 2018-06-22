cd $WORKSPACE
bash csit/resources/tools/jenkins/patch_vote/parse.sh
mkdir -p csit_
mv csit/output.xml csit_/output.xml
mv csit/log.html csit_/log.html
mv csit/report.html csit_/report.html
mv csit/results.txt csit_/results.txt
# TODO: Also handle archive/ and make job archive everything useful.
rm -rf csit
git checkout HEAD~
set +u
