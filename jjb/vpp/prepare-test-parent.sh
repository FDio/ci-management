cd $WORKSPACE
bash csit/resources/tools/jenkins/patch_vote/parse.sh
rm -rf csit_new
mkdir -p csit_new
for filename in output.xml log.html report.html results.txt; do
    mv csit/$filename csit_new/$filename
done
# TODO: Also handle archive/ and make job archive everything useful.
rm -rf build-root
cp -r build_parent build-root
