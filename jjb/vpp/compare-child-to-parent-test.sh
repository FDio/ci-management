cd $WORKSPACE

rm -f csit/results.txt
grep "Maximum Receive Rate Results" csit/output.xml
grep -o "'Maximum Receive Rate Results .*\]'" csit/output.xml | grep -o '\[.*\]' >> results.txt

echo "PARENT:"
cat csit/results.txt

echo "NEW:"
cat csit_/results.txt

echo "FIXME: IMPLEMENT THE REST!"
exit 1
