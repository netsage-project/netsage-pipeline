require_relative '../flow_format_converter.rb'
require_relative 'helpers.rb'
require 'test/unit'
require 'json'
require 'logstash-event'


RSpec.describe EventWrapper do
  before(:each) do
    @netflowData = load_data("input_netflow.json")
    @sflow_data = load_data("input_sflow.json")
  end
  it 'Netflow Event Wrapper Test' do
    event = EventWrapper.new({'Ford' => 'Broken Car'})
    expect(event.message['Ford']).to eq('Broken Car')
    event.set("type", "flow")
    expect(event.get('type')).to eq('flow')
  end
  it 'Given Netflow Sample Data Proper conversion should occur' do
    ENV["DEBUG"] = "true"
    expect(@netflowData).not_to eq(nil)
    event = EventWrapper.new(@netflowData)
    result_event = filter(event)[0]
    puts result_event
    expect(result_event).not_to eq(nil)
    expect(result_event.get('type')).to eq('flow')
    expect(result_event.get('interval')).to eq(600)
    values = result_event.get('values')
    meta = result_event.get('meta')
    expect(values.length).to eq(5)
    expect(meta.length).to eq(12)
    expect(meta["instance_id"]).to eq("instanceName")
    expect(meta["sensor_id"]).to eq("awesomeSensor")
    ##Duration validation
    expect(values["duration"]).to eq(2.0)
    expect(values["num_packets"]).to eq(200)
    expect(values["num_bits"]).to eq(83200)
    expect(values["packets_per_second"]).to eq(100)
    expect(values["bits_per_second"]).to eq(41600)
    expect(result_event.get("raw_message")).to be_truthy
  end
  it 'Given Sflow Sample Data Proper conversion should occur' do
    ENV["DEBUG"] = "false"
    expect(@sflow_data).not_to eq(nil)
    event = EventWrapper.new(@sflow_data)
    result_event = filter(event)[0]
    puts result_event
    expect(result_event).not_to eq(nil)
    expect(result_event.get('type')).to eq('flow')
    expect(result_event.get('interval')).to eq(600)
    values = result_event.get('values')
    meta = result_event.get('meta')
    expect(values.length).to eq(5)
    expect(meta.length).to eq(12)
    expect(meta["instance_id"]).to eq("instanceName")
    expect(meta["sensor_id"]).to eq("awesomeSensor")
    expect(meta["flow_type"]).to eq("sflow")
    expect(meta["protocol"]).to eq("tcp")
    # ##Duration validation.  SFlow duration is always 0, so no calculated rates are present.
    expect(values["num_packets"]).to eq(90)
    expect(values["num_bits"]).to eq(4640)
    expect(values["packets_per_second"]).to eq(0)
    expect(values["bits_per_second"]).to eq(0)
    expect(values["duration"]).to eq(0)
  end

  it 'Given Sample Data With 0 Duration' do
    ENV["LOG_LEVEL"] = "debug"
    expect(@netflowData).not_to eq(nil)
    @netflowData["timestamp_end"] = @netflowData["timestamp_start"]
    event = EventWrapper.new(@netflowData)
    result_event = filter(event)[0]
    expect(result_event).not_to eq(nil)
    expect(result_event.get('type')).to eq('flow')
    values = result_event.get('values')
    expect(values["duration"]).to eq(0)
    expect(values["packets_per_second"]).to eq(0)
    expect(values["bits_per_second"]).to eq(0)
  end
end