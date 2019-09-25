#!/bin/bash
FILE="scan.txt"
OUTPUT="output.txt"

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb || true
apt-get install -f -y 

google-chrome --headless --disable-gpu -dump-dom --no-sandbox https://scan.coverity.com/projects/fd-io-vpp > $FILE

NEW=$(grep -i -B 1 '<dt>Newly detected</dt>' $FILE | grep -Eo '[0-9]{1,4}')
ELIM=$(grep -i -B 1 '<dt>Eliminated</dt>' $FILE | grep -Eo '[0-9]{1,4}')
OUT=$(grep -i -B 1 '<dt>Outstanding</dt>' $FILE | grep -Eo '[0-9]{1,4}')

#ls -lg $FILE
#cat $FILE

if [ "${OUT}" == "0" ]; then
        echo 'Current outstanding issues are zero' > $OUTPUT
        echo "Newly detected: $NEW" >> $OUTPUT
		echo "Eliminated: $ELIM" >> $OUTPUT
		echo "More details can be found at  https://scan.coverity.com/projects/fd-io-vpp" >> $OUTPUT
else
        echo "Current number of outstanding issues are $OUT" > $OUTPUT
        echo "Newly detected: $NEW" >> $OUTPUT
		echo "Eliminated: $ELIM" >> $OUTPUT
		echo "More details can be found at  https://scan.coverity.com/projects/fd-io-vpp" >> $OUTPUT
        exit 1
fi


#echo "Newly detected: $NEW" > $OUTPUT
#echo "Eliminated: $ELIM" >> $OUTPUT
#echo "Outstanding: $OUT" >> $OUTPUT
#echo "More details can be found at  https://scan.coverity.com/projects/fd-io-vpp" >> $OUTPUT
#cat $FILE
#head $FILE
#grep -i -B 1 'Newly detected' $FILE| grep -Eo '[0-9]{1,4}'
#echo $NEW

