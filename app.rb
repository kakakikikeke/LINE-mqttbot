# frozen_string_literal: true

require 'sinatra'
require 'line/bot'
require './lib/mqtt_client'

# IP を固定させるためのプロキシ情報を管理するクラス
class HTTPProxyClient
  def http(uri)
    proxy_class = Net::HTTP::Proxy(ENV['FIXIE_URL_HOST'],
                                   ENV['FIXIE_URL_POST'],
                                   ENV['FIXIE_URL_USER'],
                                   ENV['FIXIE_URL_PASSWORD'])
    http = proxy_class.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    http
  end

  def get(url, header = {})
    uri = URI(url)
    http(uri).get(uri.request_uri, header)
  end

  def post(url, payload, header = {})
    uri = URI(url)
    http(uri).post(uri.request_uri, payload, header)
  end
end

# Bot となる Web アプリケーション用のクラス
class MyBot < Sinatra::Base
  configure do
    # ボットの応答を設定
    file = File.read('config/answer.json')
    answer = JSON.parse(file)
    set :answer, answer
    # LINE クライアントを設定
    line_client ||= Line::Bot::Client.new do |config|
      config.httpclient = HTTPProxyClient.new
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
      config.channel_id = ENV['LINE_CHANNEL_ID']
    end
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
    unless settings.line_client.validate_signature(body, signature)
      error 400 do
        'Bad Request'
      end
    end
    events = settings.line_client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          msg = event.message['text']
          # publish
          publish(msg)
          # subscribe
          subscribe(msg)
          # fail
          failure
        end
      end
    end
    'OK'
  end

  private

  def publish(msg)
    settings.answer['pub_success'].each do |successes|
      skip unless msg.chomp == successes['message']

      send_to_mqtt(successes['payload'])
      message = {
        type: 'text',
        text: successes['responses'].sample
      }
      reply_to_line(message)
    end
  end

  def subscribe(msg)
    settings.answer['sub_success'].each do |successes|
      skip unless msg.chomp == successes['message']
      value = settings.mqtt_client.latest
      message = {
        type: 'text',
        text: successes['responses'].sample.gsub('{value}', value)
      }
      reply_to_line(message)
    end
  end

  def failure
    message = {
      type: 'text',
      text: settings.answer['fail'].sample
    }
    settings.line_client.reply_message(event['replyToken'], message)
  end

  def reply_to_line(message)
    settings.line_client.reply_message(event['replyToken'], message)
  end

  def send_to_mqtt(payload)
    settings.mqtt_client.send_message(payload)
  end
end
