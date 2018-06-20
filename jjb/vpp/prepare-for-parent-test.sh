cd $WORKSPACE
mkdir -p csit_
mv csit/output.xml csit_/output.xml
mv csit/log.html csit_/log.html
mv csit/report.html csit_/report.html
# TODO: Also handle archive/ and make job archive everything useful.
rm -rf csit
# FIXME: Make the regexp confirugable.
rm -f csit_/results.txt
grep -o "'Maximum Receive Rate Results .*\]'" csit_/output.xml | grep -o '\[.*\]' >> csit_/results.txt
git checkout HEAD~
set +u
