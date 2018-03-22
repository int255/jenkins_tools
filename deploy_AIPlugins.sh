#!/bin/bash
if [ "$1" != "" ]; then
	VERSION=$1
else
	VERSION=`curl -s 'http://macmini.esko-graphics.com:8080/view/EnabledJobs/job/PublishAIBuild/lastSuccessfulBuild/artifact/artifacts/buildnumber.txt'`
fi

WORKSPACE=/p4/nexu_l_ai18A1
LICDIR=/Users/nexu/Desktop/demo/Licensing/Mac

TGT=~/Desktop/$VERSION

CC2014='/tmp/ai_links/2014'
CC2015='/tmp/ai_links/CC2015'
AI21='/tmp/ai_links/AI21'
AI22='/tmp/ai_links/AI22'
AI20='/tmp/ai_links/AI20'
CC='/tmp/ai_links/CC'
CS6='/tmp/ai_links/CS6'

QT_CLANG_DIR=${WORKSPACE}/Output/MacOSX-clang-debug-x86_64/
QT_DIR=/tmp/_nonexisting_placeholder

QT5_DIR=${WORKSPACE}/Output/MacOSX-clang-debug-x86_64/

echo "Download? (y/n) [n]"
DO_COPY=0

read OPT
case $OPT in
    y) DO_COPY=1;;
esac

echo 
echo "Which AI version to deploy? "
echo '1) CC2014'
echo '2) CC2015'
echo '3) CS6'
echo '4) CC2015.3'
echo '5) CC2017'
echo '6) CC2018'

read OPT
case $OPT in
    1) AI_LINK_DIR=$CC2014 SDKVER=18 LIC_SUB=CC2014 QT_DIR=$QT_CLANG_DIR;;
	2) AI_LINK_DIR=$CC2015 SDKVER=19 LIC_SUB=CC2015 QT_DIR=$QT_CLANG_DIR;;
	3) AI_LINK_DIR=$CS6 SDKVER=16 LIC_SUB=CS6 QT_DIR=$QT_CLANG_DIR;;
	4) AI_LINK_DIR=$AI20 SDKVER=20 LIC_SUB=AI20 QT_DIR=$QT_CLANG_DIR;;
	5) AI_LINK_DIR=$AI21 SDKVER=21 LIC_SUB=AI21 QT_DIR=$QT_CLANG_DIR;;
	6) AI_LINK_DIR=$AI22 SDKVER=22 LIC_SUB=AI22 QT_DIR=$QT_CLANG_DIR;; 
esac


echo
echo "Deploy Debug ? (y/n) [y]"
DO_DBG_LIC=1

read OPT
case $OPT in
    n) DO_DBG_LIC=0;;
esac

echo ===== START DEPLOY =====
echo WORKSPACE=${WORKSPACE}
echo OUTPUT=${QT_DIR}
echo SDKVER=${SDKVER}
echo DO_DBG_LIC=${DO_DBG_LIC}


function prepare()
{
	rm -rf /tmp/ai_links
	mkdir /tmp/ai_links/
	cd /tmp/ai_links
	ln -s /Applications/Adobe\ Illustrator\ CS6 CS6
	ln -s /Applications/Adobe\ Illustrator\ CC\ 2014 CC2014
	ln -s /Applications/Adobe\ Illustrator\ CC\ 2015 CC2015
	ln -s /Applications/Adobe\ Illustrator\ CC\ 2015.3 AI20
	ln -s /Applications/Adobe\ Illustrator\ CC\ 2017 AI21
	ln -s /Applications/Adobe\ Illustrator\ CC\ 2018 AI22
}

function Usage ()
{
echo Usage: 
echo '	'`basename $0` '<Version>' 
echo Example:
echo '	'`basename $0` 14.0.100
echo 
exit 0
}

function Error ()
{
	echo $1
	exit -1
}

function extract_7z ()
{
	cd $TGT
	if [ ! -d "EskoLoc" ]; then
		rm -rf Esko
		7z x *_Mac_Localisation.7z
		mv Esko EskoLoc
	fi

	if [ ! -d "Esko20" ]; then
		rm -rf Esko
		7z x *_Mac_AI20.7z
		mv Esko Esko20
	fi

	if [ ! -d "Esko21" ]; then
		rm -rf Esko
		7z x *_Mac_AI21.7z
		mv Esko Esko21
	fi

	if [ ! -d "Esko22" ]; then
		rm -rf Esko
		7z x *_Mac_AI22.7z
		mv Esko Esko22
	fi

	if [ ! -d "Esko16" ]; then
		rm -rf Esko
		7z x *_Mac_AI16.7z
		mv Esko Esko16	
	fi
}

function deploy_AI ()
{
	AIDIR=$1
	PLUGIN=Esko$2
	test -d "$AIDIR" || Error "AI dir $AIDIR does not exist"
	test -d "${TGT}/EskoLoc" || Error "${TGT}/EskoLoc does not exist"
	test -d "${TGT}/$PLUGIN" || Error "${TGT}/${PLUGIN} does not exist"

	cd $AIDIR
	rm -rf Esko
	sleep 1
	mkdir Esko
	echo  cp -rf ${TGT}/EskoLoc/* Esko/
	cp -rf ${TGT}/EskoLoc/* Esko/

	rm -rf Plug-ins.localized/Esko
	sleep 1
	mkdir Plug-ins.localized/Esko
	echo  cp -rf ${TGT}/${PLUGIN}/* Plug-ins.localized/Esko/
	cp -rf ${TGT}/${PLUGIN}/* Plug-ins.localized/Esko/

	echo Plugins Deployed!!!
}

function deploy_Debug_Licensing ()
{
	AIDIR=$1
	PLUGIN=Esko$2
	test -d "$AIDIR" || Error "AI dir $AIDIR does not exist"
	test -d "${TGT}/EskoLoc" || Error "${TGT}/EskoLoc does not exist"
	test -d "${TGT}/$PLUGIN" || Error "${TGT}/${PLUGIN} does not exist"
	test -d "${LICDIR}" || Error "${LICDIR} does not exist"
	test -d "${QT_DIR}" || Error "${QT_DIR} does not exist"

	cd $AIDIR
	rm -rf Esko/LicenseSetup.plugin
	echo Copying license debug resources
	cp -rf ${LICDIR}/Esko/LicenseSetup.plugin Esko/

	rm -rf Plug-ins.localized/Esko/Licensing/*
	echo  Copying license debug plugin
	cp -rf ${LICDIR}/Plug-ins/${LIC_SUB}/* Plug-ins.localized/Esko/Licensing/

	echo Copying Qt5 debug .dylib
	cp -rfv ${QT5_DIR}/libQt5*.dylib Plug-ins.localized/Esko/UI/
	cp -rfv ${QT5_DIR}/libqcocoa_debug.dylib Plug-ins.localized/Esko/UI/
	cp -rfv ${QT5_DIR}/AISDKVersion${SDKVER}-StaticLibs/libBGADMQt5Managerd.dylib Plug-ins.localized/Esko/UI/
	cp -rfv ${QT5_DIR}/imageformats Plug-ins.localized/Esko/UI/
	echo Debug License and QT Deployed!!!
}

prepare

# Check if parameter is given
test $VERSION || Usage

if [[ "$DO_COPY" == "1" ]]; 
then
	mkdir ${TGT}
	cd ${TGT}
	curl -O 'http://macmini.esko-graphics.com:8080/job/PublishAIBuild/lastSuccessfulBuild/artifact/artifacts/downloads.txt'
	cat downloads.txt | grep Mac| xargs -L1 curl -O
fi

#extract the 7z anyway, 
extract_7z

deploy_AI $AI_LINK_DIR $SDKVER

if [[ "$DO_DBG_LIC" == "1" ]];
then
	deploy_Debug_Licensing $AI_LINK_DIR $SDKVER
fi



