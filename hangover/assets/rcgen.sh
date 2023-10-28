#!/bin/bash

contents() {
echo "GLFW_ICON ICON \"$2\""
echo "1 VERSIONINFO"
echo -n "FILEVERSION  "
echo $1 | sed "s/\./,/g
              s/-/,/g"
echo -n "PRODUCTVERSION  "
echo $1 | sed "s/\./,/g
              s/-/,/g"
cat <<EOF
BEGIN
  BLOCK "StringFileInfo"
  BEGIN
    BLOCK "080904E4"
    BEGIN
      VALUE "CompanyName", "None"
      VALUE "FileDescription", "%%2%%"
      VALUE "FileVersion", "%%1%%"
      VALUE "InternalName", "%%2%%"
      VALUE "OriginalFilename", "%%2%%.exe"
    END
  END
  BLOCK "VarFileInfo"
  BEGIN
    VALUE "Translation", 0x809, 1252
  END
END
EOF
}

ver=$(echo $1 | sed -s 's/-/./')
contents $1 $3 | sed "s/%%1%%/$ver/g" | sed "s/%%2%%/$2/g" > $4

echo $3
