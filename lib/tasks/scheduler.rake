namespace :scheduler do
  desc "Heroku schedulerに呼ばれる処理"
  task :notice => :environment  do  #モデルにアクセスする場合
    require 'line/bot'
    require 'date'
    client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "02aadf741bad2100c0a0ddd60698c986"
      config.channel_token = "KT7aBBeegjq29U+SE++Lcc0kvTojFwlXNkC8KUdUD1EzuSnq4FHwiriNyXKInvQjIbqm0YFXMXY+xTGNqGGLw2YPwLg14vL9ipGq7xZ7Cy6viSrPdqPY9J1KHMO55FzNwPAv8y2rpKPNQWOLzb1/MwdB04t89/1O/w1cDnyilFU="
    }
    #アクションのための条件指定
    @reminds = Remind.all
    @reminds.each do |remind|
      if remind.date == (Date.tomorrow + remind.before)  #UTCのせいでtoday = 前日になるため
        date = remind.date.strftime("%m/%d")  #.gsub("0","")
        push = "おはよう！\n#{remind.food}の賞味期限が\n5日後の【#{date}】になったよ。\n残さず食べてあげてー！"
        # メッセージ送信のためにユーザーを取得
        user_id = remind.user.line_id
        message = {
          type: 'text',
          text: push
        }
        response = client.push_message(user_id, message)
      end
    end
    "OK"
  end
  task :refresh => :environment do
    require 'line/bot'
    require 'date'
    @reminds = Remind.where("date < ?", Date.tomorrow)  #UTCのせいでtoday = 前日になるため
    @reminds.destroy_all
    "OK"
  end
  task :theday => :environment do
    require 'line/bot'
    require 'date'
    client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "02aadf741bad2100c0a0ddd60698c986"
      config.channel_token = "KT7aBBeegjq29U+SE++Lcc0kvTojFwlXNkC8KUdUD1EzuSnq4FHwiriNyXKInvQjIbqm0YFXMXY+xTGNqGGLw2YPwLg14vL9ipGq7xZ7Cy6viSrPdqPY9J1KHMO55FzNwPAv8y2rpKPNQWOLzb1/MwdB04t89/1O/w1cDnyilFU="
    }
    @reminds = Remind.where(date: Date.tomorrow)
    if @reminds != nil
      @reminds.each do |remind|
        push = "あわわ...！\n#{remind.food}の賞味期限が今日までみたい！\nまだ残ってたりしないかな？\n確認してみてねー！"
        # メッセージ送信のためにユーザーを取得
        user_id = remind.user.line_id
        message = {
          type: 'text',
          text: push
        }
        response = client.push_message(user_id, message)
      end
    end
    "OK"
  end
end

