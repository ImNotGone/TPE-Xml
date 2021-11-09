declare variable $errno external;
declare variable $desc external;

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
<flights_data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="flights_data.xsd">
{
    if($errno != 0)
    then
        <error>{$desc}</error>
    else
    for $fresponse in doc("flights.xml")/root/response/response
    order by $fresponse/hex
    return 
        <flight id="{$fresponse/hex}">
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