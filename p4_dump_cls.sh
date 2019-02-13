#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -c|--P4CLIENT)
    P4CLIENT="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--P4PASSWORD)
    P4PASSWORD="$2"
    shift # past argument
    shift # past value
    ;;
    -i|--INITIALS)
    INITIALS="$2"
    shift # past argument
    shift # past value
    ;;
    -j|--JIRAPREFIX)
	JIRAPREFIX="$2"
	shift
	shift
	;;
    -f|--FROM)
    FROM="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--TO)
    TO="$2"
    shift # past argument
    shift # past value
    ;;    
    -o|--OUTPUT)
    OUTPUT="$2"
    shift # past argument
    shift # past value
    ;;    
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


#echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)
if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 "$1"
    exit -1
fi

if [ "" == "${JIRAPREFIX}" ]; then
	JIRAPREFIX="DPI"
fi

if [ "" == "${OUTPUT}" ]; then
	OUTPUT=p4desc.txt
fi

if [ "" == "${P4PASSWORD}" ]; then
	P4PASSWORD="esko"
fi

if [ "" == "${INITIALS}" ]; then
	INITIALS="NEXU DAJI CRLI HAZH MAZH"
fi

echo ${P4PASSWORD} | p4 login

if [ "" == "${FROM}" ]; then
	echo FROM=p4 changes -m1 "@"${P4CLIENT} "| awk {'print $2'}"
	p4 changes -m1 @${P4CLIENT} 
	p4 changes -m1 @${P4CLIENT} | awk {'print $2'}
	FROM=`p4 changes -m1 @${P4CLIENT} | awk {'print $2'}`	
fi

if [ "" == "${TO}" ]; then
	echo TO=p4 changes -c ${P4CLIENT} -s submitted -m 1 //${P4CLIENT}/... "| awk {'print $2'}"
	p4 set P4CLIENT=${P4CLIENT}
	p4 changes -c ${P4CLIENT} -s submitted -m 1 //${P4CLIENT}/... 
	p4 changes -c ${P4CLIENT} -s submitted -m 1 //${P4CLIENT}/... | awk {'print $2'}
	TO=`p4 changes -c ${P4CLIENT} -s submitted -m 1 //${P4CLIENT}/... | awk {'print $2'}`
fi

echo
echo P4CLIENT  		= ${P4CLIENT}
echo P4PASSWORD    	= ${P4PASSWORD}
echo FROM          	= ${FROM}
echo TO          	= ${TO}
echo INITIALS      	= ${INITIALS}
echo JIRAPREFIX     = ${JIRAPREFIX}
echo OUTPUT        	= ${OUTPUT}

l_INITIALS=${INITIALS}
l_LASTSYNC=${FROM}

	
echo l_LASTSYNC=${l_LASTSYNC}


l_HEAD=${TO}
let l_FROM=l_LASTSYNC+1
echo l_PENDING=p4 changes -s submitted -m 20 //${P4CLIENT}/...'@'${l_FROM},${l_HEAD} "| awk {'print $2'}`"
l_PENDING=`p4 changes -s submitted -m 20 //${P4CLIENT}/...@${l_FROM},${l_HEAD} | awk {'print $2'}`

echo ""
echo "=========="
echo p4 last changelist: $l_LASTSYNC
echo p4 have changelist: $l_HEAD
echo p4 pending changelist: $l_PENDING
echo "=========="
echo ""

l_MSG=""
for l_CL in ${l_PENDING};
do

	l_WHO=`p4 describe -s ${l_CL} | head -n1 | awk -F'@' '{ print $1}' | awk -F' ' '{ print $4}'`
	#echo "${l_WHO} ${l_CL}"
	l_valid=0
	# match the initial
	for l_id in ${l_INITIALS}
	do
		if [ "${l_id}" == "${l_WHO}" ]; then
			l_valid=1
			break;
		fi
	done
	#match jira prefix
	if [ $l_valid -eq 1 ]; then
		l_DESC=`p4 changes -s submitted -l -m 20 //${P4CLIENT}/...@${l_CL},${l_CL} | grep -B2 ${JIRAPREFIX} | tail -n +3`
		if [ "${l_DESC}" == "" ]; then
			l_valid=0
		fi
	fi

	if [ $l_valid -eq 1 ]; then
		echo "Jira valid changelist: ${l_CL} ${l_WHO}" 
		#echo ${l_DESC}
		l_MSG+=${l_DESC}
	else 
		# //irrelevant change
		echo "skip irrelevant change: ${l_CL} ${l_WHO}"
	fi
done

if [ "${l_MSG}" == "" ]; then
	echo P4_HAS_DESC=0 > ${OUTPUT}
else
	echo P4_HAS_DESC=1 > ${OUTPUT}
fi

echo P4_CL_DESC=${l_MSG} >> ${OUTPUT}
echo ""
echo ">> ${OUTPUT}"
cat ${OUTPUT}
