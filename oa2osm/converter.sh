#!/bin/bash

######################################################################################
##										    ##
##										    ##
##    converter.sh: This script converts OpenAddresses csv files                    ##
##                  to OSM format, adds them to the latest OSM                      ##
##                  data files for US states, and then generates                    ##
##                  an OBF file from the data.                                      ##
##										    ##
##										    ##
##    Script by: Josh Bullock                                                       ##
##										    ##
######################################################################################


#################################
#  Declare working directories  #
#################################

STARTDIR="$(dirname ${PWD})"

OUTPUTDIR="${STARTDIR}/new-osm"

#########################################
#  Downloads the latest OSM data files  #
#########################################

for url in $(cat osmdownloads); do wget ${url} -P ${STARTDIR}/latest-osm; done

sleep 30m

for url in $(cat ${STARTDIR}/oa2osm/osmdownloads2); do wget ${url} -P ${STARTDIR}/latest-osm; done

for url in $(cat ${STARTDIR}/oa2osm/oa-downloads); do wget ${url} -P ${STARTDIR}/oa-osm/; done

cd ${STARTDIR}/latest-osm

bunzip2 *.bz2

for latestosm in $(ls ${STARTDIR}/latest-osm); do mv ${STARTDIR}/latest-osm/${latestosm} "${STARTDIR}/latest-osm/$(echo ${latestosm} | sed -e 's/-//g' -e 's/latest//' -e 's/\.osm/-latest.osm/')" 2> /dev/null; done

cd ${STARTDIR}/oa-osm

for i in *.zip; do unzip -o ${i} -d ${i%%.zip}; done

##############################################
#  Convert OpenAddress CSV to OSM and trim,  #
#  then concatenate to latest OSM data file  #
#  with proper formatting.                   #
##############################################

cd ${STARTDIR}

for REGION in $(ls ${STARTDIR}/oa-osm/ | grep openaddr | grep -v zip); do 

    DATADIR=${STARTDIR}/oa-osm/${REGION}/us

    for STATE in $(ls ${DATADIR}); do

        for county in $(ls ${DATADIR}/${STATE}/*.csv); do ${STARTDIR}/oa2osm/oa2osm.js --title-case 'STREET,CITY' ${county} ${county/csv/osm}; done

        for file in $(ls ${DATADIR}/${STATE}/*.osm); do

            if [[ ! $(cat ${DATADIR}/${STATE}/id_counter 2> /dev/null) ]]; then NEWID=0; else NEWID="$(cat ${DATADIR}/${STATE}/id_counter)"; fi

            cat ${file} | perl -pe "s/(id="'"'")([^"'"'"]*)("'"'")/\$1 . (${NEWID} + \$2) . \$3/e" >> ${DATADIR}/${STATE}/${STATE}.osm

            echo "$(($(tac ${file} | grep -m1 "id=" | sed 's/^.*id="\([^"]*\).*$/\1/') + $(if [[ ! $(cat ${DATADIR}/${STATE}/id_counter 2> /dev/null) ]]; then echo "0"; else cat ${DATADIR}/${STATE}/id_counter; fi)))" > ${DATADIR}/${STATE}/id_counter

        done

        sed -i '/^<osm/d' ${DATADIR}/${STATE}/${STATE}.osm

        sed -i '/^<?xml/d' ${DATADIR}/${STATE}/${STATE}.osm

	sed -i '/<\/osm>/d' ${DATADIR}/${STATE}/${STATE}.osm

        MAXID="$(tail -n 10 ${DATADIR}/${STATE}/${STATE}.osm | tr '\n' ' ' | sed 's/$/\n/' | sed 's/^.*id="\([^"]*\)".*$/\1/')"

        sed 's/^\(<node\)\( .*\) id="\(-[^>]*\)>/\1 id="\3\2>/' ${DATADIR}/${STATE}/${STATE}.osm | perl -pe "s/(id="'"'")([^"'"'"]*)("'"'")/\$1 . (${MAXID} - \$2 - 1) . \$3/e" > ${DATADIR}/${STATE}/${STATE}-new.osm

        mv ${DATADIR}/${STATE}/${STATE}-new.osm ${DATADIR}/${STATE}/${STATE}.osm

        NEWSTATE="$(grep "${STATE}," ${STARTDIR}/oa2osm/states.txt | sed 's/^[^,]*,//')"

        mv ${DATADIR}/${STATE}/${STATE}.osm ${OUTPUTDIR}/${NEWSTATE}.osm

        tail +4 ${STARTDIR}/latest-osm/${NEWSTATE}-latest.osm >> ${OUTPUTDIR}/${NEWSTATE}.osm

        sed -i "s/timestamp=.*$/timestamp="'"'"$(date +%Y"-"%m"-"%d"T"%H":"%M":"%S"Z")"'"'">/" ${STARTDIR}/oa2osm/osmheader.txt

        cat ${STARTDIR}/oa2osm/osmheader.txt > ${OUTPUTDIR}/${NEWSTATE}-openaddress.osm
  
        sed -n '3p' ${STARTDIR}/latest-osm/${NEWSTATE}-latest.osm >> ${OUTPUTDIR}/${NEWSTATE}-openaddress.osm	

        cat ${OUTPUTDIR}/${NEWSTATE}.osm >> ${OUTPUTDIR}/${NEWSTATE}-openaddress.osm

	rm -f ${OUTPUTDIR}/${NEWSTATE}.osm

	rm -f ${DATADIR}/${STATE}/id_counter

        echo -e "\n\n${NEWSTATE} osm file created\n\n"
    done

done

#######################################
#  Convert the final OSM file to OBF  #
#######################################

cd ${STARTDIR}/oa2osm

sed -i "s|STARTDIR|${STARTDIR}|g" ${STARTDIR}/oa2osm/batch.xml

${STARTDIR}/oa2osm/utilities.sh generate-obf-files-in-batch ${STARTDIR}/oa2osm/batch.xml

for file in $(ls ${OUTPUTDIR} | grep "obf$"); do mv ${OUTPUTDIR}/${file} ${OUTPUTDIR}/${file/_2/}.zip 2> /dev/null; done

