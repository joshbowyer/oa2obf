# converter.sh

Uses oa2osm to convert [OpenAddresses result CSVs](https://openaddresses.io/) to [OpenStreetMap XML](https://wiki.openstreetmap.org/wiki/OSM_XML), formatted for addition
to OSM data files from the [GeoFabric OSM mirror](http://download.geofabrik.de/north-america.html)

# How to use
First change the Java heap size in utilities.sh so that -Xmx has the maximum memory you can give it. For large files it is advisable to format a flash drive as swap and add that to the total. After that just run the script from within its directory, it will do everything for you.

# Dependencies
npm
libcommons-logging-java

# Usage
Usage: bash converter.sh

# Warnings
The Geofrabrik server seems to have a short connection limit. It will stop serving
requests after around 30 requests, and the script makes 52. I have put a 30 minute
sleep command to circumvent this.
