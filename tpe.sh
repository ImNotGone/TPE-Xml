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

errno=0
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
      errno=1
    fi
  else
    errno=2
  fi
  ;;
*) errno=3 ;;
esac

if [ $errno -eq 0 ]
then
  echo -e "${GREEN}[INFO ]${WHITE} Downloading airports.xml"
  `curl https://airlabs.co/api/v9/airports.xml?api_key=${AIRLABS_API_KEY} > airports.xml`
  echo -e "${GREEN}[INFO ]${WHITE} Downloading countries.xml"
  `curl https://airlabs.co/api/v9/countries.xml?api_key=${AIRLABS_API_KEY} > countries.xml`
  echo -e "${GREEN}[INFO ]${WHITE} Downloading flights.xml"
  `curl https://airlabs.co/api/v9/flights.xml?api_key=${AIRLABS_API_KEY} > flights.xml`
else
  echo -e "${RED}[ERROR]${WHITE} Api data won't be downloaded, errors will be reported"
fi

echo -e "${GREEN}[INFO ]${WHITE} Processing *.xml"
`java net.sf.saxon.Query ./extract_data.xq errno=${errno} > ./flights_data.xml`
echo -e "${GREEN}[INFO ]${WHITE} File flights_data.xml created"

echo -e "${GREEN}[INFO ]${WHITE} Processing flights_data.xml"
`java net.sf.saxon.Transform -s:flights_data.xml -xsl:generate_report.xsl -o:report.tex qty=${qty} ALL_VALUES=${ALL_VALUES}`
echo -e "${GREEN}[INFO ]${WHITE} File report.tex created"

if [ $errno -ne 0 ]
then
  echo -e "\n${RED}[ERROR]${WHITE} Data was not processed correcty, errors were reported"
  echo -e "\n${ORANGE}[ERRNO] Error number = ${errno}${WHITE}"
  
  case $errno in
  1) echo -e "${ORANGE}[DESC ] Decimal number must be greater than 0${WHITE}";;
  2) echo -e "${ORANGE}[DESC ] The argument recived was not a decimal number${WHITE}";;
  3) echo -e "${ORANGE}[DESC ] Maximum argument count exceeded${WHITE}";;
  *) echo -e "${ORANGE}[DESC ] Unknown error${WHITE}";;
  esac
else
  echo -e "\n${GREEN}[INFO ]${WHITE} Data processing finished no errors were found"
fi
exit $errno