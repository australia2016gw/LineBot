class LinebotController < ApplicationController
  require 'line/bot'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'
 
  protect_from_forgery :except => [:callback]
 
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
 
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
        when Line::Bot::Event::MessageType::Location
          latitude = event.message['latitude']
          longitude = event.message['longitude']
          appId = ENV["API_KEY"]
          url= "http://api.openweathermap.org/data/2.5/forecast?lon=#{longitude}&lat=#{latitude}&APPID=#{appId}&units=metric&mode=xml"
          # XMLをパースしていく
          xml  = open( url ).read.toutf8
          doc = REXML::Document.new(xml)
          p "xml"
          p xml
          xpath = 'weatherdata/forecast/time[1]/'
          nowWearther = doc.elements[xpath + 'symbol'].attributes['name']
          nowTemp = doc.elements[xpath + 'temperature'].attributes['value']
          nowHumidity = doc.elements[xpath + 'humidity'].attributes['value']
          case nowWearther
          # 条件が一致した場合、メッセージを返す処理。絵文字も入れています。
          when /.*(clear sky|few clouds).*/
            push = "現在地の天気は晴れです\u{2600}\n\n現在の気温は#{nowTemp}℃です\u{1F321}\n\n現在の湿度は#{nowHumidity}%です\u{1F4A7}"
          when /.*(scattered clouds|broken clouds|overcast clouds).*/
            push = "現在地の天気は曇りです\u{2601}\n\n現在の気温は#{nowTemp}℃です\u{1F321}\n\n現在の湿度は#{nowHumidity}%です\u{1F4A7}"
          when /.*(rain|thunderstorm|drizzle).*/
            push = "現在地の天気は雨です\u{2614}\n\n現在の気温は#{nowTemp}℃です\u{1F321}\n\n現在の湿度は#{nowHumidity}%です\u{1F4A7}"
          when /.*(snow).*/
            push = "現在地の天気は雪です\u{2744}\n\n現在の気温は#{nowTemp}℃です\u{1F321}\n\n現在の湿度は#{nowHumidity}%です\u{1F4A7}"
          when /.*(fog|mist|Haze).*/
            push = "現在地では霧が発生しています\u{1F32B}\n\n現在の気温は#{nowTemp}℃です\u{1F321}\n\n現在の湿度は#{nowHumidity}%です\u{1F4A7}"
          else
            push = "現在地では何かが発生していますが、\nご自身でお確かめください。\u{1F605}\n\n現在の気温は#{nowTemp}℃です\u{1F321}\n\n現在の湿度は#{nowHumidity}%です\u{1F4A7}"
          end
          message = {
            type: 'text',
            text: push
          }
          client.reply_message(event['replyToken'], message)
        end
        head :ok
      end
    end
  end
end
  