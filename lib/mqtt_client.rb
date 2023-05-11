# frozen_string_literal: true

require 'mqtt'
require 'eventmachine'

# MQTT クライアントを管理するクラス
class MQTTClient
  def initialize
    @qos = ENV['MQTT_QOS'].to_i || 0
    @topic = ENV['MQTT_TOPIC']
    @sub_topic = ENV['MQTT_SUB_TOPIC'] || ENV['MQTT_TOPIC']
    @client = MQTT::Client.connect(
      host: ENV['MQTT_HOST'], port: ENV['MQTT_PORT'],
      username: ENV['MQTT_USERNAME'], password: ENV['MQTT_PASSWORD']
    )
    @latest = ''
    run_backend_worker
  end

  def send_message(payload)
    @client.publish(@topic, payload, false, @qos)
  end

  private

  def run_backend_worker
    EM.defer do
      receive_message
    end
  end

  def receive_message
    @client.get(@sub_topic) do |_, message|
      @latest = message
    end
  end

  attr_accessor :latest
end
