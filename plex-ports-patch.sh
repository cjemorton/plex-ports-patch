#!/usr/bin/env sh

########################################################################################################
# Check if shell variables have been set.
########################################################################################################
echo "##################################################"
echo "SETTINGS: Fill these in in settings.conf"
echo "##################################################"
echo "apikey: " $apikey
echo "cmd: " $cmd
echo "URL: " $url
echo "PORT: " $port
echo "Distfiles: " $distfiles
echo "Ports Directory: " $ports_dir
echo "Email: " $email
echo "Name: " $name
echo "##################################################"
echo "Note: Script does not halt on missing settings"
echo "##################################################"
########################################################################################################
# Call api endpoint.
	json=$(curl -s -X GET "http://$url:$port/api/v2?apikey=$apikey&cmd=$cmd")

# Parse json call with jq and set varables with relavant data.
update_available=$(echo $json | jq '.response.data | {update_available}' | jq '.update_available')
download_url=$(echo $json | jq '.response.data | {download_url}' | jq '.download_url' | xargs)
version=$(echo $json | jq '.response.data | {version}' | jq '.version' | xargs)
timestamp=$(echo $json | jq '.response.data | {release_date}' | jq '.release_date' | xargs)
version_prefix=$(echo $version | cut -f 1 -d '-' | xargs)
version_suffix=$(echo $version | cut -f 2 -d '-' | xargs)

echo "New Plex Version Available: $update_available: -> $version"

if [ "$update_available" == 'true' ]
then

# Makefile Changes
if [ -e $ports_dir/Makefile ]
then
echo "Makefile exists, creating backup."
cp $ports_dir/Makefile $ports_dir/Makefile.orig

	sed -e "s/Created by.*/Created by: $name <$email>/g" \
	-e "s/PORTVERSION=.*/PORTVERSION=\t"$version_prefix"/g" \
	-e "s/DISTVERSIONSUFFIX=.*/DISTVERSIONSUFFIX="$version_suffix"/g" \
	-e "s/MAINTAINER=.*/MAINTAINER=\t"$email"/g" $ports_dir/Makefile > $ports_dir/Makefile.new

	mv $ports_dir/Makefile.new $ports_dir/Makefile

fi

# Generate distinfo

	# aria2c multi threads and connections.
#	aria2c -s16 -x16 --dir=$distfiles -c $download_url
	cd $ports_dir && make makesum


# Run update on jail.
#	cbsd jexec jname=plex synth install multimedia/plexmediaserver-plexpass
#	cbsd jexec jname=plex service plexmediaserver_plexpass status
#	cbsd jexec jname=plex service plexmediaserver_plexpass stop
#	cbsd jexec jname=plex service plexmediaserver_plexpass start
#	cbsd jexec jname=plex service plexmediaserver_plexpass status
else
	echo "Plex is running $version, no update needed."
fi
