##
# Script that checks a source and destination countries to see if they are 
# "domestic" or international. If countries are missing, continents are considered.
#  1. If both ends are domestic, then set country_scope to "Domestic"
#  2. If only one end is domestic, then set country_scope to "Mixed"
#  3. If neither end is domestic, then set country_scope to "International"
#  4. If either end has Unknown country and continent, or the continent can't determine whether the end
#  is domestic or international, or dst is Multicast, add no country_scope. 

# Countries considered Domestic
DOMESTIC_MAP = {
    "United States" => true,
    "Puerto Rico" => true,
    "Guam" => true
}
# Continents containing the Domestic countries (may contain others also, of course!)
DOMESTIC_CONTINENTS_MAP = {
    "North America" => true,
    "Oceania" => true
}

DOMESTIC_VAL="Domestic"
INTERNATIONAL_VAL="International"
MIXED_VAL="Mixed"

def register (params)
    # name of the source country field - e.g. [meta][src_country_name]
    @src_country_field = params["src_country_field"]
    # name of the dest country field - e.g. [meta][dst_country_name]
    @dst_country_field = params["dst_country_field"]
    # name of the source continent field - e.g. [meta][src_continent]
    @src_continent_field = params["src_continent_field"]
    # name of the dest continent field - e.g. [meta][dst_continent]
    @dst_continent_field = params["dst_continent_field"]
    # name of the field where the result should be stored. [meta][country_scope]
    @target_field = params["target_field"]
end

def filter(event)
    #make sure we have our params
    if !@src_country_field or !@dst_country_field or !@src_continent_field or !@dst_continent_field or !@target_field then
        event.tag('Error: did not have all field names in domestic.rb')
        return [event]
    end
    
    #get countries and continents
    source_country = event.get(@src_country_field)
    dest_country = event.get(@dst_country_field)
    source_continent = event.get(@src_continent_field)
    dest_continent = event.get(@dst_continent_field)

    #if no source/dest country or either is 'Unknown' or 'Multicast' then don't tag
    #if !source_country or !dest_country or source_country == "Unknown" or dest_country == "Unknown" or dest_country == "Multicast" then
    #    return [event]
    #end
    
    #if dst is Multicast, don't set scope
    if dest_country == "Multicast" then
        return [event]
    end
    
    # if we have both countries, it's easy
    if source_country and dest_country and source_country != "Unknown" and dest_country != "Unknown" then
        #check the the endpoints and set the target field
        if DOMESTIC_MAP.key?(source_country) and DOMESTIC_MAP.key?(dest_country) then
            event.set(@target_field, DOMESTIC_VAL)
        elsif DOMESTIC_MAP.key?(source_country) or DOMESTIC_MAP.key?(dest_country) then
            event.set(@target_field, MIXED_VAL)
        else
            event.set(@target_field, INTERNATIONAL_VAL)
        end
        return [event]
    end

    # if we have one country and other continent, we may be able to tell scope by other continent
    if source_country and dest_continent and source_country != "Unknown" and dest_continent != "Unknown" then
        if DOMESTIC_MAP.key?(source_country) and !DOMESTIC_CONTINENTS_MAP.key?(dest_continent) then
            event.set(@target_field, MIXED_VAL)
        elsif !DOMESTIC_MAP.key?(source_country) and !DOMESTIC_CONTINENTS_MAP.key?(dest_continent) then
            event.set(@target_field, INTERNATIONAL_VAL)
        end
        return [event]
    end

    if dest_country and source_continent and dest_country != "Unknown" and source_continent != "Unknown" then
        if DOMESTIC_MAP.key?(dest_country) and !DOMESTIC_CONTINENTS_MAP.key?(source_continent) then
            event.set(@target_field, MIXED_VAL)
        elsif !DOMESTIC_MAP.key?(dest_country) and !DOMESTIC_CONTINENTS_MAP.key?(source_continent) then
            event.set(@target_field, INTERNATIONAL_VAL)
        end
        return [event]
    end

    # if we only have 2 continents, we can identify some international flows
    if source_continent and dest_continent and source_continent != "Unknown" and dest_continent != "Unknown" then
        if !DOMESTIC_CONTINENTS_MAP.key?(source_continent) and !DOMESTIC_CONTINENTS_MAP.key?(dest_continent) then
            event.set(@target_field, INTERNATIONAL_VAL)
        end
        return [event]
    end

    return [event]
end
