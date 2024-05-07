# Ruby filter to anonymize an ipv6 address
# by stripping the last 4 hex numbers
# (Note: Ruby scripts can't go in the logstash/conf.d/ dir. directly)

def register (params)
    # pass in the name of the ipv6 field to process and reset, eg, [meta][src_ip]
    @ip_field = params["ip_field"]
end

def filter(event)
            begin
            ip = event.get(@ip_field)

            # First, expand to full 8 hex numbers
            ip_parts = ip.split(":")
            missing = 8 - ip_parts.length
            missing = missing + 1 if ip =~ /::/
            new_ip_parts = []
            ip_parts.each do |part|
                # handle any ::
                if part.length == 0
                    missing.times do
                        new_ip_parts.push("0")
                    end
                else
                    new_ip_parts.push(part)
                end
            end

            # Anonymize by replacing last 4 parts with x:x:x:x
            new_ip_parts[4] = new_ip_parts[5] = new_ip_parts[6] = new_ip_parts[7] = "x"

            if new_ip_parts.length != 8
		event.tag('error in anonymize_ipv6 - no. of parts in addr is ' + new_ip_parts.length.to_s + ', not 8 ')
            end
            #
            # save new value
            clipped_ip = new_ip_parts.join(":")
            event.set(@ip_field, clipped_ip)

            rescue Exception => e
		event.tag('_rubyexception in anonymize_ipv6 - ' + e.message)
                return [event]
            end

            return [event]
end
