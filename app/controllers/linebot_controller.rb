class LinebotController < ApplicationController
  require 'line/bot'

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)

    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: event.message['text']
          }
        end
      end
      client.reply_message(event['replyToken'], message)
    end
    head :ok
  end

private

# LINE Developers登録完了後に作成される環境変数の認証
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["5a5bf2f2dcf53e5f52f05098d7a58212"]
      config.channel_token = ENV["ufFCGpJ/iEq2Tb5HZojWgjTEUGeE4fbIp5p7FTX4WizhuLbyQ0mrrflww2Eb+BhA0cu6UEKt/BkOobfU2wIL9A1LebRYMDHGnTtp8VdeUd/JXmTD5FtifRzumGdtnp2aSV6u6RgJmgq0snL+9jfICQdB04t89/1O/w1cDnyilFU="]
    }
  end
end