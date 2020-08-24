require 'json'

class EventWrapper
  attr_reader :message
  attr_reader :cancelled

  def initialize(message)
    @message = message
    @cancelled = false
  end

  def set(key, value)
    self.message[key] = value
  end

  def to_hash()
    self.message
  end

  def get(key)
    if key == "message" then
      return @message.to_json
    end
    if !key.include? "["
      return @message[key]
    end

    key.gsub! "[", ""
    elements = key.split("]")
    current = @message
    elements.each do |i|
      puts i
      current = current.fetch(i, {})
    end

    return current

  end

  def remove(key)
    @message = {}
  end

  def cancel()
    puts "Event is cancelled"
    @cancelled = true
  end

  def to_s
    @message.to_json
  end

  def to_str
    @message.to_json
  end
end


def load_data(file)
  begin
    s = File.read(file)
    return JSON.parse(s)
  rescue => exception
    s = File.read("spec/%s" % file)
    return JSON.parse(s)
  end
end