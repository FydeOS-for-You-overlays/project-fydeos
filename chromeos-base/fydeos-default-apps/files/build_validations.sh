#!/bin/bash
curDir=`pwd`
extensionDirs="extensions arc-extensions"
validationFile=${curDir}/validations/fydeos-default-apps-1.0.0.validation
echo "" > $validationFile
for ext in $extensionDirs ; do
  cd ${curDir}/$ext
  for file in `ls *.crx` ; do
   sha256sum $file >> $validationFile;
  done
  cd .. 
done



