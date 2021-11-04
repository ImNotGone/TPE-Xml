declare variable $qty external;
declare variable $includeAll external;

declare function local:airportCountry($airportCode as element()) as node() {
    <country>
    {
        let $countryCode:= 
            for $airport in doc("airports.xml")/root/response/response
            where $airport/iata_code = $airportCode
            return $airport/country_code
        
        for $country in doc("countries.xml")/root/response/response
        where $country/code = $countryCode    
        return $country/name/text()
    }
    </country>
};

(:
declare function local:airportName($airportCode as element()) as node() {
    for $airportData in doc("airports.xml")/root/response/response
    where $airportData/iata_code = $airportCode
    return $airportData/name
};

declare function local:createAirportNode($airport as element(), $type as xs:QName) as node() {
    if($airport)
    then
        <>
            {local:airportCountry($airport)}
            {local:airportName($airport)}
        </xdmp:unquote($type)>
    else
        <error> Could note create $type node</error>
};
:)
<flights_data>
{
    let $values:=
        for $response in doc("flights.xml")/root/response/response
        order by $response/hex
        return $response

    for $fresponse at $index in $values
    where $index <= $qty or $qty = $includeAll
    return 
        <flight id="{$fresponse/hex}">
            <country>
                {   
                    for $cresponse in doc("countries.xml")/root/response/response
                    where $cresponse/code = $fresponse/flag
                    return $cresponse/name/text()
                }
            </country>
            <position>
                {$fresponse/lat}
                {$fresponse/lng}
            </position>
            {$fresponse/status}
            {
                if ($fresponse/dep_iata)
                then
                    <departure_airport>
                        {local:airportCountry($fresponse/dep_iata)}
                        {
                            for $airportData in doc("airports.xml")/root/response/response
                            where $airportData/iata_code = $fresponse/dep_iata
                            return $airportData/name
                        }
                    </departure_airport>
                else
                    <error> Could note create departure_airport node</error>
            }
            {
                if ($fresponse/arr_iata)
                then
                    <arrival_airport>
                        <country>
                        {
                            let $airportCode:= 
                                for $airport in doc("airports.xml")/root/response/response
                                where $airport/iata_code = $fresponse/arr_iata
                                return $airport/country_code
                            
                            for $country in doc("countries.xml")/root/response/response
                            where $country/code = $airportCode    
                            return $country/name/text()
                        }
                        </country>
                        {
                            for $airportData in doc("airports.xml")/root/response/response
                            where $airportData/iata_code = $fresponse/arr_iata
                            return $airportData/name
                        }
                    </arrival_airport>
                else
                    <error>Could note create arrival_airport node</error>
            }
        </flight>
}
</flights_data>