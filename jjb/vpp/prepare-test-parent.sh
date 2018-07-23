cd $WORKSPACE
rm -rf csit_new
mkdir -p csit_new
for filename in output.xml log.html report.html; do
    mv csit/$filename csit_new/$filename
done
bash csit/resources/tools/jenkins/patch_vote/parse.sh csit_new
# TODO: Also handle archive/ and make job archive everything useful.
rm -rf csit
rm -rf build-root
cp -r build_parent build-root
