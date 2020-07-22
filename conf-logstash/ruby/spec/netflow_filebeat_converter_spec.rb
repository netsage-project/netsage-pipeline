require_relative '../netflow_filebeat_converter.rb'
require_relative 'helpers.rb'
require 'test/unit'
require 'json'
require 'logstash-event'


RSpec.describe EventWrapper do
  before(:each) do
    @data = load_data("filebeat_netflow.json")
    @datav6 = load_data("filebeat_netflow_ipv6.json")
  end
  it 'Event Wrapper Test' do
    event = EventWrapper.new({'Ford' => 'Broken Car'})
    expect(event.message['Ford']).to eq('Broken Car')
    event.set("type", "flow")
    expect(event.get('type')).to eq('flow')
  end
  it 'Give a date we should be able to convert to and from the String date' do
    start = @data["event"]["created"]
    expect(start).not_to eq(nil)
    epoch = str_to_epoch(start)
    expect(epoch).to be > 0
    converted_date = DateTime.strptime("%s" % epoch, '%s')
    converted_date = converted_date.strftime("%Y-%m-%dT%H:%M:%S%z")
    offset = converted_date.index('+0000')

    ## Strip off timezone data
    expect(offset).to be > 0
    converted_date = converted_date[0..offset - 1]
    offset = start.index('Z')
    start = start[0..offset - 1]
    ## Validate Date
    expect(converted_date[0..converted_date.index('T') - 1]).to eq(start[0..start.index('T') - 1])
    ## Validate TS
    result_ts = converted_date[converted_date.index('T') + 1..]
    start_ts = start.gsub(/(.*T)(.*)/, '\2').gsub(/\.\d+/, '')
    expect(result_ts).to eq(start_ts)
  end
  it 'Given Sample Data Proper conversion should occur' do
    ENV["DEBUG"] = "true"
    expect(@data).not_to eq(nil)
    #Ensure duration is not 0
    @data["netflow"]["flow_end_sys_up_time"] = @data["netflow"]["flow_start_sys_up_time"] + 1000
    event = EventWrapper.new(@data)
    result_event = filter(event)[0]
    expect(result_event).not_to eq(nil)
    expect(result_event.get('type')).to eq('flow')
    expect(result_event.get('interval')).to eq(600)
    values = result_event.get('values')
    meta = result_event.get('meta')
    expect(values.length).to eq(5)
    expect(meta.length).to eq(12)
    expect(meta["instance_id"]).to eq("instanceName")
    expect(meta["sensor_id"]).to eq("bestSensorEver")
    ##Duration validation
    expect(values["duration"]).to eq(1.0)
    expect(values["packets_per_second"]).to eq(100)
    expect(values["bits_per_second"]).to eq(32000)
    expect(result_event.get("raw_message")).to be_truthy
  end
  it 'Given IPv6 Message proper conversion occurs' do
    ENV["DEBUG"] = "true"
    expect(@datav6).not_to eq(nil)
    event = EventWrapper.new(@datav6)
    result_event = filter(event)[0]
    expect(result_event).not_to eq(nil)
    expect(result_event.get('type')).to eq('flow')
    meta = result_event.get('meta')
    expect(meta["src_ip"]).to eq("df7e:e014:fb08:81eb:ff:ff:ffff:ff72")
    expect(meta["dst_ip"]).to eq("2583:d47f:d0:ff16:ffff:ff00:c5ce:4bf3")
  end
  it 'Given Sample Data With 0 Duration' do
    ENV["LOG_LEVEL"] = "debug"
    expect(@data).not_to eq(nil)
    event = EventWrapper.new(@data)
    result_event = filter(event)[0]
    expect(result_event).not_to eq(nil)
    expect(result_event.get('type')).to eq('flow')
    values = result_event.get('values')
    expect(values["duration"]).to eq(0)
    expect(values["packets_per_second"]).to eq(0)
    expect(values["bits_per_second"]).to eq(0)
  end
end
