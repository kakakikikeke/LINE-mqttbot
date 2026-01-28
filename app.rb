# frozen_string_literal: true

require 'sinatra'
require './lib/mqtt_client'
require './lib/line_client'

# Bot となる Web アプリケーション用のクラス
class MyBot < Sinatra::Base
  configure :production, :development do
    set :host_authorization, { permitted_hosts: [] }
  end

  configure do
    # ボットの応答を設定
    file = File.read('config/answer.json')
    answer = JSON.parse(file)
    set :answer, answer
    # LINE クライアントを設定
    line_client = LINEClient.new
    set :line_client, line_client
    # MQTT クライアントを設定
    mqtt_client = MQTTClient.new
    set :mqtt_client, mqtt_client
  end

  get '/' do
    erb :hello
  end

  # LINE からのコールバックを受け取るメソッド
  post '/callback' do
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    begin
      events = settings.line_client.parse_events_from(body, signature)
    rescue LINEClient::InvalidSignatureError
      error 400 do
        'Bad Request'
      end
    end
    events.each do |event|
      case event
      when Line::Bot::V2::Webhook::MessageEvent
        case event.message
        when Line::Bot::V2::Webhook::TextMessageContent
          msg = event.message.text
          # publish
          publish(msg, event)
          # subscribe
          subscribe(msg, event)
          # fail
          failure(event)
        end
      end
    end
    'OK'
  end

  private

  def publish(msg, event)
    settings.answer['pub_success'].each do |successes|
      next unless msg.chomp == successes['message']

      send_to_mqtt(successes['payload'])
      message = Line::Bot::V2::MessagingApi::TextMessage.new(
        text: successes['responses'].sample
      )
      reply_to_line(message, event)
    end
  end

  def subscribe(msg, event)
    settings.answer['sub_success'].each do |successes|
      next unless msg.chomp == successes['message']

      value = settings.mqtt_client.latest
      message = Line::Bot::V2::MessagingApi::TextMessage.new(
        text: successes['responses'].sample.gsub('{value}', value)
      )
      reply_to_line(message, event)
    end
  end

  def failure(event)
    message = Line::Bot::V2::MessagingApi::TextMessage.new(
      text: settings.answer['fail'].sample
    )
    reply_to_line(message, event)
  end

  def reply_to_line(message, event)
    settings.line_client.reply_message(event.reply_token, [message])
  end

  def send_to_mqtt(payload)
    settings.mqtt_client.send_message(payload)
  end
end
