#!/usr/bin/env bash

####
# very basic sense check on records in api-list
# only contian URI character, a-z 1-9 and . 
#
# Intended to be called from ../setup.sh
##

str="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
here=${str%/*}
cd ${here}

echo "Checking api-list"

IFS=$'\t\n'
for x in `cat api-list`
do 

[[ "${x}" =~ ^[A-Za-z0-9.-]*$ ]] 
 if [ $? == 0 ] 
  then 
	echo "checked ok: ${x} "
	echo ${x} >> api-list.checked
  else
	echo "record ${x} is not supported"
	echo "api-list records can only be abc.123.def"
	echo " : / \ ? * etc are not allowed"
  fi
done

mv api-list api-list.pre-check
cp api-list.checked api-list

IFS=$' \t\n'

# Send Back
cd ..
