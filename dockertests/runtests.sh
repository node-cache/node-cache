VERSIONS[1]="6.9"
VERSIONS[2]="6.0_alpine"
VERSIONS[3]="6.9_alpine"

VERSIONS[4]="7.2"
VERSIONS[5]="7_alpine"

VERSIONS[6]="argon"
VERSIONS[7]="boron"
VERSIONS[8]="carbon"
VERSIONS[9]="dubnium"
VERSIONS[10]="latest"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SCRIPTDIR="dockertests"
cd $DIR
rm -f *.log

cd ..

grunt build

for version in "${VERSIONS[@]}"
do
	:
	FV=`echo $version | sed 's/\./_/g'`
	DFile="Dockerfile_$FV"
	if [ -f "$SCRIPTDIR/$DFile" ]; then
		DIMG=`head -n 1 $SCRIPTDIR/$DFile`
		echo "\n-------------\nDocker Test ($DIMG)\n-------------"
		BUILDLOGS="$DIR/dockerbuild_$version.log"
		docker build -t=mpneuried.nodecache.test:$version -f=$SCRIPTDIR/$DFile . > $BUILDLOGS
		docker run --rm mpneuried.nodecache.test:$version >&2
	else
		echo "Dockerfile '$DFile' not found"
	fi
done
