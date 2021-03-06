# TPE-Xml

## Autores
#### Santiago Ballerini (Cuiniardium)
#### Agustin Zakalik (TheSpackJarrow)
#### Gonzalo Martone (ImNotGone)
#
## Ejecucion del codigo
#### Previo a la ejecucion del codigo se debe registrar en `airlabs.co` y asignar a la variable de entrorno `AIRLABS_API_KEY` su llave personal.
1) Para procesar toda la informacion llame al programa de la siguiente manera
`bash ./tpe.sh`

2) Si desea limitar la cantidad de vuelos procesados, el llamar al programa asi, limita la salida a los primeros `qty` segun el codigo del vuelo
`bash ./tpe.sh qty`
#
# <text>tpe.sh</text>
## Este programa se encarga de decargar los datos de la API, llamar a *extract_data.xq* y a *generate_report.xsl*.
### Algunos comentarios sobre el codigo:
#
En la primera seccion del archivo, declaramos un par de funciones  y constantes auxiliares. Las funciones son para validar la entrada del usuario y entre las constantes esta `ALL_VALUES` que se le asigna a la variable `qty` si el usuario quiere ver todos los datos procesados. Las otras constantes son esencialmente, para poder imprimir con colores en la pantalla
```sh
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
```
Iniciamos la variable `errno` en 0 y `desc` en "no error", indicando de esta manera q no hay errores e iniciamos `qty` con el valor de la constante `ALL_VALUES`. Luego nos fijamos la cantidad de argumentos que recibimos del usuario (`$#`). Si la cantidad es 0, no hacemos nada y se procesa toda la información recibida. Si la cantidad es 1, verificamos que el parametro sea un numero positivo, sino actualizamos `errno` y `desc` por lo que los datos no se procesaran. Si la cantidad es mayor a 1, tambien actualizamos `errno` y `desc` por lo que los datos tampoco serán procesados.

En caso de que el usuario envíe correctamente un único numero positivo como parametro se lo asignamos a `qty` (`qty=$1`).

Finalmente, si no se encuentra declarada la variable `AIRLABS_API_KEY` que contiene la clave para acceder al api de airlabs, se actualizan `errno` y `desc`, los datos tampoco serán procesados si esto se cumple.
```sh
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
```
Una vez terminadas las validaciones, verificamos que no hubiese ningun error y en ese caso eliminamos las versiones viejas de todos los archivos de la API si existieran, y descargamos todos los archivos nuevamente. Si hubo algun error, no descargamos nada y notificamos al usuario de ello mismo.
```sh
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
```
Luego hacemos los llamados a *extract_data.xq* y a *generate_report.xsl* pasandole las variables necesarias para su correcto funcionamieto. A *extract_data.xq* le pasamos `errno` y `desc` para que verifique si hubo algun error y generar un nodo con su descripción si es necesario además a *generate_report.xsl* le pasamos `qty` y `ALL_VALUES` para que limite o no la información en la salida. En caso de que no se hubieran generado los archivos necesarios, genero un nuevo error.
```sh
echo -e "${GREEN}[INFO ]${WHITE} Processing *.xml ..."
if [ ! -e airports.xml ] || [ ! -e countries.xml ] || [ ! -e flights.xml ]
then
  if [ $errno -eq 0 ]
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
```
Una vez terminada la ejecución de *extract_data.xq* y de *generate_report.xsl*, notificamos al usuario, cual fue el error cometido si es que hubo alguno. Sino, imprimimos a salida estandar que no hubo errores.
```sh
if [ $errno -ne 0 ]
then
  echo -e "\n${RED}[ERROR]${WHITE} Data was not processed correcty, errors were reported"
  echo -e "\n${ORANGE}[ERRNO] Error number = ${errno}${WHITE}"
  echo -e "${ORANGE}[DESC ] ${desc}${WHITE}"
else
  echo -e "\n${GREEN}[INFO ]${WHITE} Data processing finished no errors were found"
fi
exit $errno
```

# extract_data.xq 
## El archivo *extract_data.xq* se encarga de procesar los datos recibidos mediante la API.
### Algunos comentarios sobre el codigo:
#
Esta primera linea del xQuery es para poder recibir mediante una variable externa, si hubo algun error previo en la ejecución del *<text>tpe.sh</text>* y la descripción de este.
```xq
declare variable $errno external;
declare variable $desc external;
```

La única función que implementamos, se encarga de unificar el comportamiento que necesitaríamos para generar los nodos con la información de los aeropuertos, tanto para `<departure_airport/>` como para `<arrival_airport>`. Recibe por parametro el código iata y busca la información necesaria para crear los 2 nodos hijos `<country/>` y `<name/>`.
En caso de que la información no exista, no retorna ningun nodo.
```xq
declare function local:buildAirport($iata as element()) as node()* {
    let $airport:= (doc("airports.xml")/root/response/response[./iata_code = $iata])[1]
    let $countryName:= (doc("countries.xml")/root/response/response[./code = $airport/country_code]/name)[1]
    return
        if($airport)
        then
            typeswitch ($iata) 
                case element(arr_iata) return    
                    <arrival_airport>
                        <country>{$countryName/text()}</country>
                        {$airport/name}
                    </arrival_airport>
                case element(dep_iata) return 
                    <departure_airport>
                        <country>{$countryName/text()}</country>
                        {$airport/name}
                    </departure_airport>
                default return ()
        else()
};
```

Luego tenemos la seccion que se encarga de armar el .xml dados los datos del API
#
En esta primera parte nos encargamos de hacer el error handling, para ello utilizamos la variable externa `$errno`, la cual nos indica si hubo un error en la ejecución del *<text>tpe.sh</text>* y cual fue el mismo. Si hubo algun error, se genera un nodo `<error>` con la descripcion del mismo mediante la variable externa `desc`. 
```xq
<flights_data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="flights_data.xsd">
{
    if($errno != 0)
    then
        <error>{$desc}</error>
    else
```
En caso de que no hubiera ningun error, empezamos a armar los nodos `<flight>` a partir de la información de los archivos *flights.xml*, *airports.xml* y *countries.xml*.
#
Inicialmente ordenamos los vuelos segun su `hex`
```xq
    for $fresponse in doc("flights.xml")/root/response/response
    order by $fresponse/hex
```
Una vez ya ordenados pasamos a moldear la información acorde a lo necesario. Cargamos el `hex` como un atributo `id` en el nodo `<flight>`, luego generamos los nodos hijos.
```xq
    return
        <flight id="{$fresponse/hex}">
```
Al generar los nodos hijos, debemos buscar su información saltando entre los archivos que nos dio el API. Mezclando la información generamos el nodo `<country>`, (si este existe) con el país de origen del avion. Luego generamos el nodo `<position>` el cual tiene como hijos la latitud `<lat>` y longitud `<lng>` en la cual se encuentra el avión en el momento. El tercer nodo hijo es `<status>` donde se almacena el estado del vuelo (en-route, sheduled o landed). 
```xq
            {
                let $country:= (doc("countries.xml")/root/response/response[./code = $fresponse/flag]/name)[1]
                return
                    if($country)
                    then
                        <country>{$country/text()}</country>
                    else()
            }
            <position>
                {$fresponse/lat}
                {$fresponse/lng}
            </position>
            {$fresponse/status}
```
Por último estan los `<departure_airport>` y `<arrival_airport>` que guardan la información de el aeropuerto de salida y el de llegada. Estos nodos no estan siempre presentes, por lo que primero preguntamos si su "código" existe debido a que la funcion que escribimos no puede recibir un nodo vacío. Si los codigos de los aeropuertos no estan presentes, simplmente no creamos el nodo. Si lo estan llamamos a la función *buildAirport()* para que la misma nos retorne los nodos con la información acerca del aeropuerto
```xq
            {$fresponse/status}
            {
                if($fresponse/dep_iata)
                then
                    local:buildAirport($fresponse/dep_iata)
                else()
            }
            {
                if($fresponse/arr_iata)
                then
                    local:buildAirport($fresponse/arr_iata)
                else()
            }
        </flight>
}
</flights_data>
```
# generate_report.xsl
## El archivo *generate_report.xsl* se encarga de procesar el output de *extract_data.xq* y armar un reporte en formato LaTeX llamado *report.tex*

### Algunos comentarios sobre el código:
#
Esta primera linea del XSLT es para poder recibir mediante variables externas la información necesaria del *<text>tpe.sh</text>* para poder limitar la salida si asi lo desesea el usuario.  
```xsl
<xsl:param name="qty" required="yes">
<xsl:param name="ALL_VALUES" required="yes"/>
```

Se declara que la salida va a ser solamente texto y no otro tipo de documento. Tambien es necesario para poder mostrar los *&*.
``` xsl
<xsl:output method="text"/>
```
La transformación comienza determinando si se va a generar el reporte o si se va a mostrar un error.

``` xsl
<xsl:template match="/">
```
Si se encuentra algun nodo error, esto implica que ocurrió un error en el programa, por lo tanto no corresponde generar el reporte. Solamente se genera texto explicando el error obtenido. El comando *\verb|...|* permite escapar caracteres reservados de LaTeX como el "*_*" que se necesita en un mensaje de error.
```xsl    
<xsl:choose>
    <xsl:when test="//flights_data/error">
        \documentclass[a4paper, 10pt]{minimal}
        \begin{document}
        An error was found while processing data and the report could not be generated properly. The error found was the following: "\verb|<xsl:value-of select="//flights_data/error"/>|"
        \end{document}
    </xsl:when>
```
Si no se encuentra ningun nodo error, entonces no ocurrió ningun error en el programa, por lo que corresponde generar el reporte. Se llaman al template *getTitle*, *getTable* y se agrega al final la linea *\end{document}* que le indica a LaTeX que termina el archivo.
```xsl        
    <xsl:otherwise>
        <xsl:call-template name="getTitle" />
        <xsl:call-template name="getTable"/> 
        \end{document}
    </xsl:otherwise>    
</xsl:choose>
</xsl:template>
```

Este template genera las lineas necesarias para que LaTeX cree el documento y el título. Se utiliza el formato *article* con tipo de hoja *a4* y tamaño de letra *10*. Se declara el margen que se va a utilizar junto al título, autor, fecha y las lineas que permitirarn generar el documento y el título. 
```xsl
<xsl:template name="getTitle">
    \documentclass[a4paper, 10pt]{article}
    \usepackage{longtable}
    \usepackage[margin=1in]{geometry}
            
    \begin{document}
    \title{Flight Report}
    \author{XML Group 01}
    \date{\today}
    \maketitle
    \newpage
</xsl:template>
```
Una vez generado el documento y el título, correponde generar la tabla con los vuelos, de esto se encarga el template *getTable*. En primer lugar se llama al template auxiliar *getTableHeader* que generará la tabla y el encabezado de esta. 

```xsl
<xsl:template name="getTable">
        <xsl:call-template name="getTableHeader"/>
```
Abajo se encuentra el codigo del template. Se genera la tabla y se establecen los anchos que ocupara cada columna de esta. La linea *\hline* corresponde a una línea separadora de fila, el *&amp* correponde a una línea separadora de columna y el *\\\\* indica un fin de fila.    
```xsl
<xsl:template name="getTableHeader">
    \begin{longtable}{| p{.10\textwidth}| p{.13\textwidth}| p{.12\textwidth}| p{.10\textwidth}| p{.19\textwidth}| p{.19\textwidth}|}
    \hline
    Flight Id &amp; Country &amp; Position &amp; Status &amp; Departure Airport &amp; Arrival Airport \\
    \hline
    \hline
</xsl:template>
```
Una vez generada la tabla se llama al template *getTableRow*. Este template recibira un parametro con cada uno de los datos necesarios de un vuelo y se encargará de generar la fila de la tabla correspondiente al vuelo. Se llamará *qty* veces a este template, si *qty* es igual a *ALL_VALUES* se llamara para todos los vuelos.
```xsl        
        <xsl:for-each select="//flights_data/flight">
            <xsl:if test="position() &lt;= $qty or $qty = $ALL_VALUES">
                <xsl:call-template name="getTableRow">
                    <xsl:with-param name="country" select="country" />
                    <xsl:with-param name="position" select="position" />
                    <xsl:with-param name="status" select="status" />
                    <xsl:with-param name="departure_airport" select="departure_airport/name" />
                    <xsl:with-param name="arrival_airport" select="arrival_airport/name" />
                    <xsl:with-param name="id" select="./@id" />
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
```
Abajo se encuentra el código del template. Cada parametro recibido es asignado en su respectiva columna dentro de la fila, se indica el final de la fila con el *\\\\* y se agrega la linea separadora de fila. Como se declaro al principio que el output es un texto, el llamado de la funcion */text()* en los nodos es redundante y no se incluye.
``` xsl
<xsl:template name="getTableRow">
    <xsl:param name="country" />
    <xsl:param name="position" />
    <xsl:param name="status" />
    <xsl:param name="departure_airport" />
    <xsl:param name="arrival_airport" />
    <xsl:param name="id" />
        <xsl:value-of select="$id"/> &amp; <xsl:value-of select="$country"/> &amp; (<xsl:value-of select="$position/lat"/>, <xsl:value-of select="$position/lng"/>) &amp; <xsl:value-of select="$status"/> &amp; <xsl:value-of select="$departure_airport"/> &amp; <xsl:value-of select="$arrival_airport"/> \\
        \hline
</xsl:template>
```
Una vez generado todo el contenido de la tabla, se le indica a LaTeX que la tabla ha terminado.
``` xsl        
        \end{longtable}

    </xsl:template>
```

# <text>topdf.sh</text>
## Este ultimo programa se encargaría de procesar el report.tex y generar un pdf a partir del mismo.
#### Decidimos aislar este ultimo programa a un archivo aparte ya que es un agregado y no es parte del tpe.
### Algunos comentarios sobre el codigo:
#
Utiliza la herramienta MikteX para generar el pdf y luego borra los archivos extra que la misma genera.
```sh
echo -e "${GREEN}[INFO ]${WHITE} Processing report.tex"
`pdflatex.exe report.tex &>/dev/null`
`rm -rf report.aux`
`rm -rf report.log`
echo -e "${GREEN}[INFO ]${WHITE} File report.pdf created"
```