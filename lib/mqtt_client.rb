require 'mqtt'
require 'eventmachine'

class MQTTClient
  def initialize
    host = ENV["MQTT_HOST"]
    port = ENV["MQTT_PORT"]
    sub_topic = ENV["MQTT_SUB_TOPIC"] || ENV["MQTT_TOPIC"]
    username = ENV["MQTT_USERNAME"]
    password = ENV["MQTT_PASSWORD"]
    @qos = ENV["MQTT_QOS"].to_i || 0
    @topic = ENV["MQTT_TOPIC"]
    @sub_topic = ENV["MQTT_SUB_TOPIC"] || ENV["MQTT_TOPIC"]
    @client = MQTT::Client.connect(
      :host => host,
      :port => port,
      :username => username,
      :password => password
    )
    @latest = ""
    EM::defer do
      receiveMessage
    end
  end

  def sendMessage(payload)
    @client.publish(@topic, payload, false, @qos)
  end

  def receiveMessage()
    @client.get(@sub_topic) do |topic, message|
      @latest = message
    end
  end

  attr_accessor :latest
end
