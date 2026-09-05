# frozen_string_literal: true

# LINE と MQTT の連携に関する業務ルールを実行するアプリケーションサービス
class BotService
  Result = Struct.new(:publishes, :replies, keyword_init: true)

  def initialize(answer:, mqtt_client:)
    @answer = answer
    @mqtt_client = mqtt_client
  end

  def call(message)
    normalized_message = message.chomp
    Result.new(
      publishes: publish_payloads(normalized_message),
      replies: reply_messages(normalized_message)
    )
  end

  private

  def publish_payloads(message)
    publishes = []

    @answer['pub_success'].each do |success|
      next unless message == success['message']

      publishes << success['payload']
    end
    publishes
  end

  def reply_messages(message)
    replies = publish_replies(message) + subscribe_replies(message)
    replies << @answer['fail'].sample
    replies
  end

  def publish_replies(message)
    @answer['pub_success'].filter_map do |success|
      next unless message == success['message']

      success['responses'].sample
    end
  end

  def subscribe_replies(message)
    @answer['sub_success'].filter_map do |success|
      next unless message == success['message']

      value = @mqtt_client.latest
      success['responses'].sample.gsub('{value}', value)
    end
  end
end
