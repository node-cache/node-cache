VERSIONS[1]="0.10"
VERSIONS[2]="0.10_ubuntu1404"
VERSIONS[3]="0.10_alpine"

VERSIONS[4]="0.12"

VERSIONS[5]="4.2"
VERSIONS[6]="4_ubuntu1404"
VERSIONS[7]="4_ubuntu1604"
VERSIONS[8]="4_ubuntu1610"
VERSIONS[9]="4.4.3_alpine"

VERSIONS[10]="5.0"
VERSIONS[11]="5.4"

VERSIONS[12]="6.9"
VERSIONS[13]="6.0_alpine"
VERSIONS[14]="6.9_alpine"

VERSIONS[15]="7.2"
VERSIONS[16]="7_alpine"

VERSIONS[17]="argon"
VERSIONS[18]="boron"
VERSIONS[18]="carbon"
VERSIONS[19]="latest"


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
