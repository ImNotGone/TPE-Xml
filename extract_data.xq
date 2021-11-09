declare variable $errno external;

declare function local:buildAirport($iata as element()) as node()* {
    let $airport:= (doc("airports.xml")/root/response/response[./iata_code = $iata])[1]
    let $countryName:= (doc("countries.xml")/root/response/response[./code = $airport/country_code]/name)[1]
    return
        if($airport)
        then
            (<country>{$countryName/text()}</country>, $airport/name)
        else
            (<country/>, <name/>)
};

<flights_data>
{
    if($errno = 1)
    then
        <error>Decimal number must be greater than 0</error>
    else if($errno = 2)
    then
        <error>The argument recived was not a decimal number</error>
    else if($errno = 3)
    then
        <error>Maximum argument count exceeded</error>
    else if($errno != 0)
    then
        <error>Unknown error</error>
    else
    for $fresponse in doc("flights.xml")/root/response/response
    order by $fresponse/hex
    return 
        <flight id="{$fresponse/hex}">
            <country>{(doc("countries.xml")/root/response/response[./code = $fresponse/flag]/name)[1]/text()}</country>
            <position>
                {$fresponse/lat}
                {$fresponse/lng}
            </position>
            {$fresponse/status}
            {
                if($fresponse/dep_iata)
                then
                    <departure_airport>
                        {local:buildAirport($fresponse/dep_iata)}
                    </departure_airport>
                else()
            }
            {
                if($fresponse/arr_iata)
                then
                    <arrival_airport>
                        {local:buildAirport($fresponse/arr_iata)}
                    </arrival_airport>
                else()
            }
        </flight>
}
</flights_data>