declare variable $qty external;
declare variable $includeAll external;
declare variable $error external;

declare function local:airportCountry($airportCode as element()) as node() {

        let $countryCode:= ( 
            for $airport in doc("airports.xml")/root/response/response
            where $airport/iata_code = $airportCode
            return $airport/country_code)[1]
        
        let $sec:=
            for $country in doc("countries.xml")/root/response/response
            where $country/code = $countryCode    
            return $country/name/text()
        return    
        if (not($sec))
        then
            <country/>
        else
            <country>
                $sec[1]
            </country>
};

declare function local:airportName($airportCode as element()) as node() {
    let $sec:=
        for $airportData in doc("airports.xml")/root/response/response
        where $airportData/iata_code = $airportCode
        return $airportData/name
    return
    if (not($sec))
    then
        <name/>
    else
        $sec[1] 
};
<flights_data>
{
    if($error != 0)
    then()
        (:error:)
    else {
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
                if($fresponse/dep_iata)
                then
                    <departure_airport>
                        {local:airportCountry($fresponse/dep_iata)}
                        {local:airportName($fresponse/dep_iata)}
                    </departure_airport>
                else()
            }
            {
                if($fresponse/arr_iata)
                then
                    <arrival_airport>
                        {local:airportCountry($fresponse/arr_iata)}
                        {local:airportName($fresponse/arr_iata)}
                    </arrival_airport>
                else()
            }
        </flight>
    }
}
</flights_data>