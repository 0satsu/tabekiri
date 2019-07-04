namespace :scheduler do
  desc "Heroku schedulerに呼ばれる処理"
  task :notice => :environment  do  #モデルにアクセスする場合
    require 'line/bot'
    require 'date'
    client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
    #アクションのための条件指定
    @reminds = Remind.all
    @reminds.each do |remind|
      if remind.date == (Date.today + remind.before) && remind.before != 0
        date = remind.date.strftime("%m/%d")  #.gsub("0","")
        push = "おはよう！\n#{remind.food}の賞味期限が\n#{remind.before}日後の【#{date}】になったよ。\n残さず食べてあげてー！"
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
    @reminds = Remind.where("date < ?", Date.tomorrow) 
    @reminds.destroy_all
    "OK"
  end
  task :theday => :environment do
    require 'line/bot'
    require 'date'
    client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
    @reminds = Remind.where(date: Date.today)
    if @reminds != nil
      @reminds.each do |remind|
        push = "あわわ...！\n#{remind.food}の賞味期限が今日までみたい😣💦\nまだ残ってたりしないかな？\n確認してみてねー！"
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

