# frozen_string_literal: true

require 'sinatra'
require './lib/mqtt_client'
require './lib/line_client'
require './service/bot_service'
require './repository/answer_repository'

# Bot となる Web アプリケーション用のクラス
class MyBot < Sinatra::Base
  configure :production, :development do
    set :host_authorization, { permitted_hosts: [] }
  end

  configure do
    answer_repository = AnswerRepository.new('config/answer.json')
    set :answer_repository, answer_repository

    line_client = LINEClient.new
    set :line_client, line_client

    mqtt_client = MQTTClient.new
    set :mqtt_client, mqtt_client

    set :bot_service, BotService.new(
      answer: answer_repository.load,
      mqtt_client: mqtt_client
    )
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
      halt 400, 'Bad Request'
    end
    events.each do |event|
      case event
      when Line::Bot::V2::Webhook::MessageEvent
        case event.message
        when Line::Bot::V2::Webhook::TextMessageContent
          result = settings.bot_service.call(event.message.text)
          result.publishes.each { |payload| settings.mqtt_client.send_message(payload) }
          result.replies.each do |text|
            message = Line::Bot::V2::MessagingApi::TextMessage.new(text: text)
            settings.line_client.reply_message(event.reply_token, [message])
          end
        end
      end
    end
    'OK'
  end
end
