#!/usr/bin/env bash
########################
#
# Script to build varnish includes for each URL in api-list
# Script is intended to be called from parent directory
# from setup.sh
#
########################

######
# Glue exection to its own directory
##
str="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
here=${str%/*}
cd ${here}

######
# insert includes into api-targets.vcl
##

# Empty the file
>../2_varnish/etc/varnish/api-targets.vcl

# Append entries
for x in `cat api-list`
do
	y="include \"sites-enabled/${x}.vcl\";"
	echo ${y} >>../2_varnish/etc/varnish/api-targets.vcl
done
cat ../2_varnish/etc/varnish/api-targets.vcl
echo "includes added to 2_varnish/etc/varnish/api-targets.vcl"

#####
#
# Create cache rules for each URL in api-list
# copy template and substitute the domains host within
#
##
rm ../2_varnish/etc/varnish/sites-enabled/*.vcl
for x in `cat api-list `
do
        cat ../2_varnish/etc/varnish/sites-enabled/aaa_template \
        | sed -e "s/aaa_template.com/${x}/g" \
        > ../2_varnish/etc/varnish/sites-enabled/${x}.vcl

	echo "created Varnish rules: ${x}.vcl"
done

# Back to parent dir.
cd ..
