#!/bin/bash
validates(){
  echo $1 | egrep $2 &>/dev/null
  return $?
}

is_decimal_num(){
  validates $1 '^-?[0-9]+$'
  return $?
}

is_decimal_positive() {
  validates $1 '^[1-9][0-9]*$'
  return $?
}

declare -r ALL_VALUES=0
declare -r WHITE="\e[m"
declare -r RED="\e[31m"
declare -r GREEN="\e[32m"
declare -r ORANGE="\e[38;5;208m"
declare -r RETURN="\e[1A\e[K"
errno=0
desc="no error"
qty=$ALL_VALUES
case $# in
0);; 
1) 
  if is_decimal_num $1
  then
    if is_decimal_positive $1
    then
      qty=$1
    else
      desc="Decimal number must be greater than 0"
      errno=1
    fi
  else
    desc="The argument received was not a decimal number"
    errno=2
  fi
  ;;
*) desc="Maximum argument count exceeded"; errno=3 ;;
esac

if [ -z $AIRLABS_API_KEY ]
then
  desc="AIRLABS_API_KEY not defined, please set your api key as an enviroment variable"
  errno=4
fi

if [ $errno -eq 0 ]
then
  rm -f airports.xml countries.xml flights.xml
  echo -e "${GREEN}[INFO ]${WHITE} Downloading airports data ..." 
  curl https://airlabs.co/api/v9/airports.xml?api_key=${AIRLABS_API_KEY} > airports.xml -s
  echo -e "${RETURN}${GREEN}[INFO ]${WHITE} File airports.xml \t created"
  echo -e "${GREEN}[INFO ]${WHITE} Downloading countries data ..." 
  curl https://airlabs.co/api/v9/countries.xml?api_key=${AIRLABS_API_KEY} > countries.xml -s
  echo -e "${RETURN}${GREEN}[INFO ]${WHITE} File countries.xml \t created"
  echo -e "${GREEN}[INFO ]${WHITE} Downloading flights data ..." 
  curl https://airlabs.co/api/v9/flights.xml?api_key=${AIRLABS_API_KEY} > flights.xml -s
  echo -e "${RETURN}${GREEN}[INFO ]${WHITE} File flights.xml \t created"
else
  echo -e "${RED}[ERROR]${WHITE} Api data won't be downloaded, errors will be reported"
fi

echo -e "${GREEN}[INFO ]${WHITE} Processing *.xml ..."
if [ ! -e airports.xml ] || [ ! -e countries.xml ] || [ ! -e flights.xml ]
then
  if [ $errno -ne 0 ]
  then
    desc="Missing necessary API files"
    errno=5
  fi
fi
java net.sf.saxon.Query ./extract_data.xq errno=${errno} desc="${desc}"> ./flights_data.xml
echo -e "${RETURN}${GREEN}[INFO ]${WHITE} File flights_data.xml \t created"

echo -e "${GREEN}[INFO ]${WHITE} Processing flights_data.xml ..."
java net.sf.saxon.Transform -s:flights_data.xml -xsl:generate_report.xsl -o:report.tex qty=${qty} ALL_VALUES=${ALL_VALUES}
echo -e "${RETURN}${GREEN}[INFO ]${WHITE} File report.tex \t created"

if [ $errno -ne 0 ]
then
  echo -e "\n${RED}[ERROR]${WHITE} Data was not processed correcty, errors were reported"
  echo -e "\n${ORANGE}[ERRNO] Error number = ${errno}${WHITE}"
  echo -e "${ORANGE}[DESC ] ${desc}${WHITE}"
else
  echo -e "\n${GREEN}[INFO ]${WHITE} Data processing finished no errors were found"
fi
exit $errno