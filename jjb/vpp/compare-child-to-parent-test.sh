cd $WORKSPACE

bash csit/resources/tools/jenkins/patch_vote/parse.sh

echo "PARENT:"
cat csit/results.txt

echo "NEW:"
cat csit_/results.txt

set +u
virtualenv --system-site-packages "env"
source "env/bin/activate"
pip install -r csit/resources/tools/jenkins/patch_vote/requirements.txt
python csit/resources/tools/jenkins/patch_vote/compare.py
# The exit code affects the vote result.
