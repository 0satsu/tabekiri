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
      #error 400 do 'Bad Request' end
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
          set_data = input.split("\n")
          line_id = event['source']['userId']
          user = User.find_by(line_id: line_id)
          if set_data.length == 2
            if set_data[1].match(/\d{1,2}\/\d{1,2}/) != nil
              food = set_data[0]
              dead_line = set_data[1]
              dead_line2 = dead_line.split("/").map(&:to_i)
              date = Date.new(2019,dead_line2[0],dead_line2[1])
              @post = Remind.new(food: food, date: date, user_id: user.id)
              if user.reminds.find_by(food: @post.food) == nil
                @post.save
                push = "#{food}は#{dead_line}までだね！\n覚えたよ〜\n当日と、その何日前にお知らせする？\n数字をいれてね！"
              else
                push = "もう同じ品目があるみたい(>_<)\n 一覧を確認してみて！\n登録するときは、前のを消してから登録してね。"
              end
            elsif set_data[0].match(/(ぜんぶ|全部)/) != nil && set_data[1].match(/(消して|けして|削除|さくじょ|消去|しょうきょ)/)  != nil
              push = "ほんとに全部けして大丈夫？\n 「はい/いいえ」で入れてね。"
            elsif  set_data[1].match(/.*(削除|さくじょ|消して|けして|消去|しょうきょ).*/) != nil
              @food = Remind.find_by(food: set_data[0])
              unless @food == nil 
                @food.destroy
                push = "#{@food.food}を削除したよ！"
              else
                push = "「#{set_data[0]}」は保存されてないみたい。一覧で確認してね！"
              end
            elsif set_data[1].match(/.*\d.*/) != nil
              push = "日付は「〇/〇」の形でいれてね！"
            else
              push = "ごめんね、登録できなかったみたい(>_<)\nもういちど試してみてね。"
            end
          elsif input.match(/\d/) != nil && user.last_message.match(/.*\d{1,2}\/\d{1,2}.*/)
            @last_remind = user.reminds.last
            before = input.to_i
            @last_remind.update(before: before)
            day = @last_remind.date - before
            push = "#{before}日前の#{day.strftime("%m/%d")}だね。\n了解♪"
          elsif input.match(/.*(全部|ぜんぶ|一覧|いちらん).*/) != nil
            index = ""
            @index = Remind.where(user_id: user.id).order("date ASC")
            @index.each do |remind|
              index += "\n#{remind.food}:  #{remind.date.strftime("%m/%d")}"
            end
            push = "登録一覧だよ〜#{index}"
          elsif  user.last_message.match(/(全部|ぜんぶ)\R(けして|消して|削除|さくじょ|消去|しょうきょ)/)
            if input.match(/はい/)
              @reminds = user.reminds
              @reminds.destroy_all unless @reminds == nil
              push = "ぜんぶ消したよ！"
            else input.match(/いいえ/)
              push = "キャンセルしたよ！"
            end
          elsif input.match(/.*(レシピ|レシピ検索|れしぴ).*/) != nil
            push = "材料を入力してね！\n(例: 「にんじん　じゃがいも」)"
          elsif user.last_message.match(/.*(レシピ|レシピ検索|れしぴ).*/) != nil
            messages = search_and_create_message(input)
            client.reply_message(event['replyToken'], messages)
          else
            push = "【登録】\n商品\n日付(〇〇/▲▲)\n【削除】\n商品\n「削除」or「消して」\nと改行していれてね！\n【一覧】\n「全部」or「一覧」って入れるとみれるよ♪"
          end
          user.update(last_message: input)
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
      config.channel_secret = "02aadf741bad2100c0a0ddd60698c986"
      config.channel_token = "KT7aBBeegjq29U+SE++Lcc0kvTojFwlXNkC8KUdUD1EzuSnq4FHwiriNyXKInvQjIbqm0YFXMXY+xTGNqGGLw2YPwLg14vL9ipGq7xZ7Cy6viSrPdqPY9J1KHMO55FzNwPAv8y2rpKPNQWOLzb1/MwdB04t89/1O/w1cDnyilFU="
    }
  end

  def search_and_create_message(input)
    RakutenWebService.configuration do |c|
      c.application_id = "1021639347585417175"
      c.affiliate_id = "18c0b761.464c0e88.18c0b762.382d9a07"
    end
    # 楽天の商品検索APIで画像がある商品の中で、入力値で検索して上から3件を取得する
    # 商品検索+ランキングでの取得はできないため標準の並び順で上から3件取得する
    category = RakutenWebService::Recipe::Category.instance_variable_set(:@categories, nil)
    binding.pry
    res =  RakutenWebService::Recipe.ranking(10)
    items = []
    # 取得したデータを使いやすいように配列に格納し直す
    items = res.map{|item| item}
    make_reply_content(items)
  end

  def make_reply_content(items)
    {
      "type": 'flex',
      "altText": 'This is a Flex Message',
      "contents":
      {
        "type": 'carousel',
        "contents": [
          make_part(items[0]),
          make_part(items[1]),
          make_part(items[2])
        ]
      }
    }
  end

  def make_part(item)
    title = item['recipeTitle']
    url = item['recipeUrl']
    image = item['smallImageUrl'].first
    {
      "type": "bubble",
      "hero": {
        "type": "image",
        "size": "full",
        "aspectRatio": "20:13",
        "aspectMode": "cover",
        "url": image
      },
      "body":
      {
        "type": "box",
        "layout": "vertical",
        "spacing": "sm",
        "contents": [
          {
            "type": "text",
            "text": title,
            "wrap": true,
            "weight": "bold",
            "size": "lg"
          },                   ]
      },
      "footer": {
        "type": "box",
        "layout": "vertical",
        "spacing": "sm",
        "contents": [
          {
            "type": "button",
            "style": "primary",
            "action": {
              "type": "uri",
              "label": "レシピ詳細ページへ",
              "uri": url
            }
          }
        ]
      }
    }
  end


end
