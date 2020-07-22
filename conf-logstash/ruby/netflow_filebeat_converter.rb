require 'json'
require 'socket'

NETFLOW = "netflow"

def str_to_epoch(str)
  # Convert an ISO8601 string to a epoch timestamp
  # Example: 2020-01-13T23:59:01.352Z --> 1578959941.352
  if str.nil? || str.class != String || str.length == 0
    return nil
  end
  begin
    date = DateTime.iso8601(str)
    return date.to_time.to_f
  rescue
    puts "invalid timestamp detected"
    return 0
  end
end

def update_instance(msg, meta)
  # Read instanceID from environment and set it, otherwise leave it blank
  instance = get_tag(msg, "instance")
  if instance.nil?
    return
  end
  elements = instance.split("_")
  if elements.length == 2 && elements[2] != ''
    meta["instance_id"] = elements[1]
  end

end


def update_sensor(msg, meta)
  # Read sensor name from ENV, if not set fallback on hostname
  sensorName = get_tag(msg, "sensor")
  sensor = nil
  if sensorName.nil?
    sensor = Socket.gethostname
  else
    sensors = sensorName.split("_")
    if sensors.length != 2
      sensor = Socket.gethostname
    else
      sensor = sensors[1]
    end
  end
  meta["sensor_id"] = sensor
end

def is_debug
  if ENV["DEBUG"] == "true"
    return true
  end
  false
end

def clear_event(event)
  #Remove all keys in event except the ones listed below
  event.to_hash.each { |k, v|
    unless ["@timestamp", "@version", "host", "message"].include?(k)
      event.remove(k)
    end
  }
end


def is_ipv6(data)
  # Test if event is for IPv4 or IPV6
  if data.key?("source_ipv6_address") || data.key?("destination_ipv6_address")
    return true
  end
  false
end

def process_netflow_data(event)
  # Will convert the filebeat event to the expected data format.
  if is_debug()
    puts "Event type is %s" % event.class
  end

  msg = event.to_hash
  clear_event(event)
  if is_debug
    event.set('raw_message', msg.to_json)
  end

  if msg.nil? || !msg.key?(NETFLOW) then
    puts "Failed sanity check on msg: %s" % msg
    return [event]
  end
  data = msg[NETFLOW]

  event.set("type", "flow")
  event.set("interval", 600)

  values = Hash.new
  meta = Hash.new

  ## Date Math
  netflow_event = msg["event"]
  duration = (data["flow_end_sys_up_time"] - data["flow_start_sys_up_time"]) / 1000.0
  start = str_to_epoch(netflow_event["created"])
  end_date = start + duration
  if (start == 0 || end_date == 0) || (start > end_date)
    puts "Invalid timestamps.  Criteria:  end_date must be greater then start and dates cannot be set to 0.  Invalidating record.  start=%s, end_date=%s" % [start, end_date]
    event.tag("invalid_time")
    event.cancel()
    return [event]
  else
    event.set("start", start)
    event.set("end", end_date)
    values["duration"] = duration
  end

  ## Packets count
  values["num_packets"] = data["packet_delta_count"]
  values["num_bits"] = data["octet_delta_count"] * 8
  if values["duration"] > 0
    values["packets_per_second"] = Integer(values["num_packets"] / values["duration"])
    values["bits_per_second"] = Integer(values["num_bits"] / values["duration"])
  else
    values["packets_per_second"] = 0
    values["bits_per_second"] = 0
  end

  # Transforms
  if is_ipv6(data)
    meta["src_ip"] = data["source_ipv6_address"]
    meta["dst_ip"] = data["destination_ipv6_address"]
  else
    meta["src_ip"] = data["source_ipv4_address"]
    meta["dst_ip"] = data["destination_ipv4_address"]
  end

  meta["src_port"] = data["source_transport_port"]
  meta["dst_port"] = data["destination_transport_port"]

  meta["dst_asn"] = data["bgp_destination_as_number"]
  meta["src_asn"] = data["bgp_source_as_number"]
  meta["flow_type"] = NETFLOW
  meta["num_protocol"] = data["protocol_identifier"]
  meta["src_ifindex"] = data["ingress_interface"]
  meta["dst_ifindex"] = data["egress_interface"]

  update_sensor(msg, meta)
  update_instance(msg, meta)


  event.set("values", values)
  event.set("meta", meta)

  return [event]
end

def get_tags(event)
  # Gets all tags, or returns empty array otherwise
  tags = event["tags"]
  if tags.nil? || tags.length == 0
    event.tag("Error: netflow/sflow tag missing on input source")
    return []
  end
  return tags

end

def get_tag(event, partial)
  # Find first partial match of a given tag
  tags = get_tags(event)
  tags.each { |item|
    if item.include? partial
      return item
    end
  }
  nil
end

def find_tag(event, name)
  # Return true if tag exists
  tags = event.get("tags")
  if tags.nil? || tags.length == 0
    event.tag("Error: netflow/sflow tag missing on input source")
    return nil
  end
  tags.each { |item|
    if name == item
      return true
    end
  }
  return false

end


def validate_event(event)
  if event.nil?
    puts "Event is nil"
    return false
  end
  true
end

def filter(event)
  if event.get("type").include? NETFLOW
    return process_netflow_data(event)
  else
    return [event]
  end
end
