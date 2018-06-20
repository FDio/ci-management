cd $WORKSPACE

rm -f csit/results.txt
grep -o "'Maximum Receive Rate Results .*\]'" csit/output.xml
grep -o "'Maximum Receive Rate Results .*\]'" csit/output.xml | grep -o '\[.*\]'
grep -o "'Maximum Receive Rate Results .*\]'" csit/output.xml | grep -o '\[.*\]' >> csit/results.txt

echo "PARENT:"
cat csit/results.txt

echo "NEW:"
cat csit_/results.txt

# TODO: Move the following into CSIT git
# possible together with dealing with configurable regexp.

virtualenv --system-site-packages "env"
source "env/bin/activate"

pip install jumpavg==0.1.2

cat << EOF > compare.py

import json
import sys
import jumpavg

parent_lines = list()
new_lines = list()
with open("csit/results.txt") as parent_file:
    parent_lines = parent_file.readlines()
with open("csit_/results.txt") as new_file:
    new_lines = new_file.readlines()
# TODO: Figure out what to do if only parent fails.
if len(parent_lines) != len(new_lines):
    print "Number of passed tests does not match!"
    sys.exit(1)
classifier = jumpavg.BitCountingClassifier()
num_tests = len(parent_lines)
exit_code = 0
for index in range(num_tests):
    parent_values = json.loads(parent_lines[index])
    new_values = json.loads(new_lines[index])
    parent_stats = jumpavg.AvgStdevMetadataFactory(parent_values)
    new_stats = jumpavg.AvgStdevMetadataFactory(new_values)
    classified_list = classifier.classify([parent_stats, new_stats])
    if len(classified_list) < 2:
        print "Test index {index} no group boundary detected".format(index=index)
        continue
    anomaly = classified_list[1].metadata.classification
    if anomaly == "regression":
        print "Regression in test index {index}".format(index=index)
        print "Parent stats {stats}".format(stats=parent_stats)
        print "New stats {stats}".format(stats=new_stats)
        print "Parent values: {values}".format(values=parent_values)
        print "New values: {values}".format(values=new_values)
        exit_code = 1
        continue
    print "Test index {index} anomaly {anomaly}".format(index=index, anomaly=anomaly)
sys.exit(exit_code)
EOF

python compare.py
# The exit code affects the vote result.
