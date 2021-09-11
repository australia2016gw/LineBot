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
    
    p "★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★"
 
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    
    p "★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★"
 
    events = client.parse_events_from(body)
    
    p "★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★"
 
    events.each do |event|
      p "★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★"
      case event
      when Line::Bot::Event::Message
        p event
        p event.type
        p event.message['latitude']
        p event.message['longitude']
        p "★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★"
        case event.type
        when Line::Bot::Event::MessageType::Location
　　　　　# LINEの位置情報から緯度経度を取得
　　　　　p "★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★"
          latitude = event.message['latitude']
          longitude = event.message['longitude']
          p "★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★"
          appId = ENV["API_KEY"]
          url= "http://api.openweathermap.org/data/2.5/forecast?lon=#{longitude}&lat=#{latitude}&APPID=#{appId}&units=metric&mode=xml"
          p url
          p "★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★"
          # XMLをパースしていく
          xml  = open( url ).read.toutf8
          doc = REXML::Document.new(xml)
          p doc
          p "★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★"
          xpath = 'weatherdata/forecast/time[1]/'
          nowWearther = doc.elements[xpath + 'symbol'].attributes['name']
          nowTemp = doc.elements[xpath + 'temperature'].attributes['value']
          case nowWearther
          # 条件が一致した場合、メッセージを返す処理。絵文字も入れています。
          when /.*(clear sky|few clouds).*/
            push = "現在地の天気は晴れです\u{2600}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          when /.*(scattered clouds|broken clouds|overcast clouds).*/
            push = "現在地の天気は曇りです\u{2601}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          when /.*(rain|thunderstorm|drizzle).*/
            push = "現在地の天気は雨です\u{2614}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          when /.*(snow).*/
            push = "現在地の天気は雪です\u{2744}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          when /.*(fog|mist|Haze).*/
            push = "現在地では霧が発生しています\u{1F32B}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          else
            push = "現在地では何かが発生していますが、\nご自身でお確かめください。\u{1F605}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          end
        end
        head :ok
      end
    end
  end
end
  