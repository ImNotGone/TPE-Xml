#!/bin/bash
cumple(){
  echo $1 | egrep $2 &>/dev/null
  return $?
}

is_numero(){
  cumple $1 '^[0-9]+$'
  return $?
}

if [ -e ./colores.sh ]
then
  source ./colores.sh
else
  echo "Por favor descargue el archivo \"colores.sh\" del repositorio"
  echo ""
  exit 3
fi

qty=0
case $# in
0) ;; #para atrapar en caso de que me pasen 0 argumentos
1) 
    if is_numero $1
    then
        qty=$1
    else
        echo -e "\n${red}[ERROR] El argumento recibido no es un numero${white}"
        exit 1
    fi
    ;;
*) 
    echo -e "\n${red}[ERROR] Cantidad de argumentos exedente${white}"
    exit 2
;;
esac

echo -e "[INFO] Descargando airpors.xml\n"
# `curl https://airlabs.co/api/v9/airports.xml?api_key=${AIRLABS_API_KEY} > airports.xml`
echo -e "[INFO] Descargando countries.xml\n"
# `curl https://airlabs.co/api/v9/countries.xml?api_key=${AIRLABS_API_KEY} > countries.xml`
echo -e "[INFO] Descargando flights.xml\n"
# `curl https://airlabs.co/api/v9/flights.xml?api_key=${AIRLABS_API_KEY} > flights.xml`

`java net.sf.saxon.Query ./extract_data.xq qty=${qty} includeAll=0 error=0 > ./flights_data.xml`

`java net.sf.saxon.Transform -s:flights_data.xml -xsl:generate_report.xsl -o:report.tex`