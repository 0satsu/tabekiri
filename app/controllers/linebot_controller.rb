class LinebotController < ApplicationController
  require 'line/bot' # gem 'line-bot-api'
  require 'open-uri' #note
  require 'kconv' #note
  require 'rexml/document' #note

  # callbackアクションのCSRFトークン認証を無効 #note
  protect_from_forgery :except => [:callback]
  
  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)
    events.each do |event|
      case event
      # メッセージが送信された場合の対応（機能①）
      when Line::Bot::Event::Message
        case event.type
        # ユーザーからテキスト形式のメッセージが送られて来た場合
        when Line::Bot::Event::MessageType::Text
          # event.message['text']：ユーザーから送られたメッセージ
          input = event.message['text']
          set_data = input.split(" ")
          food = set_data[0]
          dead_line = set_data[1]
          if set_data.length == 2 && dead_line.match(/\d{2}\/\d{2}/ != nil)
            push = "#{food}は#{dead_line}までだね！\n覚えたよ〜"
          else
            push = "商品と日付(mm/dd)をいれてね！\n日付は4桁だよ。"
          end
          # テキスト以外（画像等）のメッセージが送られた場合
        else
          push = "テキスト以外はわからないよ〜(；；)"
        end

          #送信するメッセージを定義
          message = {
            type: 'text',
            text: push
          }
          client.reply_message(event['replyToken'], message)
      # LINEお友達追された場合（機能②）
      when Line::Bot::Event::Follow
        # 登録したユーザーのidをユーザーテーブルに格納
        line_id = event['source']['userId']
        User.create(line_id: line_id)
        # LINEお友達解除された場合（機能③）
      when Line::Bot::Event::Unfollow
        # お友達解除したユーザーのデータをユーザーテーブルから削除
        line_id = event['source']['userId']
        User.find_by(line_id: line_id).destroy
      end


    end

    # Don't forget to return a successful response
    "OK"
  end


  private
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

end
