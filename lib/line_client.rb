# frozen_string_literal: true

require 'line-bot-api'
require './lib/http_proxy_client'

# LINE クライアントを管理するクラス
class LINEClient
  def initialize
    # V2 MessagingApi クライアント
    @api_client = Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV['LINE_CHANNEL_TOKEN']
    )
    # V2 WebhookParser
    @webhook_parser = Line::Bot::V2::WebhookParser.new(
      channel_secret: ENV['LINE_CHANNEL_SECRET']
    )
  end

  def parse_events_from(body, signature)
    @webhook_parser.parse(body: body, signature: signature)
  rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
    raise InvalidSignatureError
  end

  def reply_message(reply_token, messages)
    request = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
      reply_token: reply_token,
      messages: messages
    )
    @api_client.reply_message(reply_message_request: request)
  end

  class InvalidSignatureError < StandardError; end
end
