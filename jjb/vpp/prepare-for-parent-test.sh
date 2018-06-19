cd $WORKSPACE
mkdir -p csit_
mv csit/output.xml csit_/output.xml
mv csit/log.html csit_/log.html
mv csit/report.html csit_/report.html
rm -rf csit
git checkout HEAD~
