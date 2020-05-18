##
# This script checks source and destination countries to see if 
# they are in a list of "domestic" countries and tags as follows:
#  1. If both ends domestic, then tag "Domestic"
#  2. If only one end is domestic, then tag "Mixed"
#  3. If neither end is domestic, then tag "International"

DOMESTIC_MAP = {
    "United States" => true,
    "Puerto Rico" => true,
    "Guam" => true
}
DOMESTIC_VAL="Domestic"
INTERNATIONAL_VAL="International"
MIXED_VAL="Mixed"

def register (params)
    # name of the source country field - e.g. [meta][src_country_name]
    @src_country_field = params["src_country_field"]
    # name of the dest country field - e.g. [meta][dst_country_name]
    @dst_country_field = params["dst_country_field"]
    # name of the field where the result should be stored. [meta][country_scope]
    @target_field = params["target_field"]
end

def filter(event)
    #make sure we have our params
    if !@src_country_field or !@dst_country_field or !@target_field then
        return [event]
    end
    
    #get countries
    source_country = event.get(@src_country_field)
    dest_country = event.get(@dst_country_field)
    #if no source/dest country or either is 'Unknown' then don't tag
    if !source_country or !dest_country or source_country == "Unknown" or dest_country == "Unknown" then
        return [event]
    end
    
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
