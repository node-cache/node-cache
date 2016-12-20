VERSIONS[0]="0.10"
VERSIONS[1]="0.12"
VERSIONS[2]="4.2"
VERSIONS[3]="5.0"
VERSIONS[4]="5.4"
VERSIONS[5]="lts"
VERSIONS[6]="latest"

VERSIONS[7]="alpine4"
VERSIONS[8]="alpine6"
VERSIONS[9]="alpine7"

VERSIONS[10]="ubuntu14"
VERSIONS[11]="ubuntu14_node4"
VERSIONS[12]="ubuntu16"
VERSIONS[13]="ubuntu1610"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SCRIPTDIR="issue78"
cd $DIR
cd ..

for version in "${VERSIONS[@]}"
do
	:
	FV=`echo $version | sed 's/\./_/'`
	DFile="Dockerfile_$FV"
	if [ -f "$SCRIPTDIR/$DFile" ]; then
		DIMG=`head -n 1 $SCRIPTDIR/$DFile`
		echo "\n-------------\nDocker Test ($DIMG)\n-------------"

		BUILDLOGS="$DIR/dockerbuild_$version.log"
		rm -f $BUILDLOGS
		docker build -t mpneuried.nodecache.testissue78.$version -f=$SCRIPTDIR/$DFile . > $BUILDLOGS
		docker run --rm mpneuried.nodecache.testissue78.$version >&2
	else
		echo "Dockerfile '$DFile' not found"
	fi
done
