namespace :scheduler do
  desc "Heroku schedulerに呼ばれる処理"
  task :notice => :environment  do  #モデルにアクセスする場合
    require 'line/bot'
    require 'date'
    client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "02aadf741bad2100c0a0ddd60698c986" #ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = "KT7aBBeegjq29U+SE++Lcc0kvTojFwlXNkC8KUdUD1EzuSnq4FHwiriNyXKInvQjIbqm0YFXMXY+xTGNqGGLw2YPwLg14vL9ipGq7xZ7Cy6viSrPdqPY9J1KHMO55FzNwPAv8y2rpKPNQWOLzb1/MwdB04t89/1O/w1cDnyilFU=" #ENV["LINE_CHANNEL_TOKEN"]
    }
    #アクションのための条件指定
      @remind = Remind.find_by(date: Date.today.next_day(5))
      if @remind != nil
        date = @remind.date.strftime("%m/%d").gsub("0","")
        push = "おはよう！\n#{@remind.food}の賞味期限が\n5日後の#{date}になったよ。\n残さず食べてあげてー！"
        # メッセージ送信のためにユーザーを取得
      end

    user_id = @remind.user.line_id
    message = {
      type: 'text',
      text: push
    }
    response = client.push_message(user_id, message)
    "OK"
  end
end

