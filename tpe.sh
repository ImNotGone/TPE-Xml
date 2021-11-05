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
if [ -e ./colores.sh ]
then
  source ./colores.sh
else
  echo -e "Por favor descargue el archivo \"colores.sh\" del repositorio\n"
  exit 1
fi

errno=0
declare -r ALL_VALUES=0
# checkear si el valor es > 0
case $# in
0) qty=$ALL_VALUES ;; 
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
*) 
    errno=3
;;
esac

if [ $errno -eq 0 ]
then
  echo -e "${green}[INFO ]${white} Downloading airports.xml"
  # `curl https://airlabs.co/api/v9/airports.xml?api_key=${AIRLABS_API_KEY} > airports.xml`
  echo -e "${green}[INFO ]${white} Downloading countries.xml"
  # `curl https://airlabs.co/api/v9/countries.xml?api_key=${AIRLABS_API_KEY} > countries.xml`
  echo -e "${green}[INFO ]${white} Downloading flights.xml"
  # `curl https://airlabs.co/api/v9/flights.xml?api_key=${AIRLABS_API_KEY} > flights.xml`
else

  echo -e "${red}[ERROR]${white} Api data won't be downloaded, no data will be processed"
fi

echo -e "${green}[INFO ]${white} Processing *.xml"
`java net.sf.saxon.Query ./extract_data.xq qty=${qty} ALL_VALUES=${ALL_VALUES} errno=${errno} > ./flights_data.xml`
echo -e "${green}[INFO ]${white} File flights_data.xml created"

echo -e "${green}[INFO ]${white} Processing flights_data.xml"
`java net.sf.saxon.Transform -s:flights_data.xml -xsl:generate_report.xsl -o:report.tex`
echo -e "${green}[INFO ]${white} File report.tex created"

if [ $errno -ne 0 ]
then
  echo -e "\n${red}[ERROR]${white} Data was not processed correcty"
  echo -e "\n${orange}[ERRNO] Error number = ${errno}${white}"
  
  case $errno in
  1) echo -e "${orange}[DESC ] Decimal number must be greater than 0${white}";;
  2) echo -e "${orange}[DESC ] The argument received was not a decimal number${white}";;
  3) echo -e "${orange}[DESC ] Maximum argument count exceeded${white}";;
  *) echo -e "${orange}[DESC ] Unknown error${white}";;
  esac
else
  echo -e "\n${green}[INFO ]${white} Data processing finished no errors were found"
fi
exit $errno