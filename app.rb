# coding: utf-8
require 'sinatra'
require 'line/bot'
require './lib/mqtt_client.rb'

class HTTPProxyClient
  def http(uri)
    proxy_class = Net::HTTP::Proxy(ENV["FIXIE_URL_HOST"], ENV["FIXIE_URL_POST"], ENV["FIXIE_URL_USER"], ENV["FIXIE_URL_PASSWORD"])
    http = proxy_class.new(uri.host, uri.port)
    if uri.scheme == "https"
      http.use_ssl = true
    end

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

class MyBot < Sinatra::Base
  configure do
    file = File.read('config/answer.json')
    answer = JSON.parse(file)
    set :answer, answer
    line_client ||= Line::Bot::Client.new { |config|
      # for LINE
      config.httpclient = HTTPProxyClient.new
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      config.channel_id = ENV["LINE_CHANNEL_ID"]
    }
    set :line_client, line_client
    mqtt_client = MQTTClient.new
    set :mqtt_client, mqtt_client
  end

  get '/' do
    erb :hello
  end

  post '/callback' do
    body = request.body.read
    puts body
    puts headers
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless settings.line_client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = settings.line_client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          msg = event.message['text']
          puts msg
          puts msg.encoding
          # publish
          settings.answer['pub_success'].each { |successes|
            if (msg.chomp == successes['message'])
              settings.mqtt_client.sendMessage(successes['payload'])
              message = {
                type: 'text',
                text: successes['responses'].sample
              }
              settings.line_client.reply_message(event['replyToken'], message)
              return "OK"
            end
          }
          # subscribe
          settings.answer['sub_success'].each { |successes|
            if (msg.chomp == successes['message'])
              value = settings.mqtt_client.latest
              message = {
                type: 'text',
                text: successes['responses'].sample.gsub("{value}", value)
              }
              puts settings.line_client.reply_message(event['replyToken'], message)
              return "OK"
            end
          }
          # fail
          message = {
            type: 'text',
            text: settings.answer['fail'].sample
          }
          puts settings.line_client.reply_message(event['replyToken'], message)
        end
      end
    }
    "OK"
  end
end
