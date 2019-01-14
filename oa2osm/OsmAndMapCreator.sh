#!/bin/sh
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ -z "$JAVA_OPTS" ]; then 
	JAVA_OPTS="-Xms64M -Xmx12G"
fi
java -Djava.util.logging.config.file="$DIR/logging.properties" -jar "$DIR/OsmAndMapCreator.jar"
