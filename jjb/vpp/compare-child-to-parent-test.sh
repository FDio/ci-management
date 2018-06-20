cd $WORKSPACE

rm -f csit/results.txt
grep -o "'Maximum Receive Rate Results .*\]'" csit/output.xml
grep -o "'Maximum Receive Rate Results .*\]'" csit/output.xml | grep -o '\[.*\]'
grep -o "'Maximum Receive Rate Results .*\]'" csit/output.xml | grep -o '\[.*\]' >> csit/results.txt

echo "PARENT:"
cat csit/results.txt

echo "NEW:"
cat csit_/results.txt

echo "FIXME: IMPLEMENT THE REST!"
exit 1
