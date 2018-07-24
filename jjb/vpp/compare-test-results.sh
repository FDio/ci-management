cd $WORKSPACE
rm -rf csit_parent
mkdir -p csit_parent
for filename in output.xml log.html report.html; do
    mv csit/$filename csit_parent/$filename
done
bash csit/resources/tools/jenkins/patch_vote/parse.sh csit_parent
set +u
virtualenv --system-site-packages "env"
source "env/bin/activate"
pip install -r csit/resources/tools/jenkins/patch_vote/requirements.txt
python csit/resources/tools/jenkins/patch_vote/compare.py
# The exit code affects the vote result.
