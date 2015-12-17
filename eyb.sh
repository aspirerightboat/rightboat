#!/bin/bash
echo "Updating File"
download="http://www.eyb.fr/exports/RGB/out/auto/RGB_Out.xml"
wget "$download" -O  ./tmp/eyb.tmp.xml
sed -i.bak -e 's/&ndash;/-/g' --e "s/&rsquo;/'/g" -e 's/&eacute;/é/g' -e 's/&euro;/?~B?/g' -e 's/&gt;//g' -e 's/&copy;/©/g' -e 's/&agrave;/?| /g' -e 's/&ecirc;/ê/g' ./tmp/eyb.tmp.xml
xml fo ./tmp/eyb.tmp.xml |  iconv -c -fISO-8859-1 -tUTF-8 | sed 's/ISO-8859-1/UTF-8/g' > ./tmp/eyb.xml
rm ./tmp/eyb.tmp.xml

xml validate -q ./tmp/eyb.xml
if [ $? == "1" ]; then
  echo "Error - file invalid"
else
  mv ./tmp/eyb.xml ./import_data/eyb.xml
  echo "Done"
fi