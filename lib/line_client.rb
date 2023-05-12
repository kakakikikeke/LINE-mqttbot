# frozen_string_literal: true

require 'line/bot'
require './lib/http_proxy_client'

# LINE クライアントを管理するクラス
class LINEClient
  def initialize(proxy)
    @client = Line::Bot::Client.new do |config|
      config.httpclient = HTTPProxyClient.new if proxy
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
      config.channel_id = ENV['LINE_CHANNEL_ID']
    end
  end

  def validate_signature(content, channel_signature)
    @client.validate_signature(content, channel_signature)
  end

  def parse_events_from(request_body)
    @client.parse_events_from(request_body)
  end

  def reply_message(token, message)
    @client.reply_message(token, message)
  end
end
