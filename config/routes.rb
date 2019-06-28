Rails.application.routes.draw do
  #メッセージが来た時、友達追加・解除がされた時にcallbackアクションを呼び出す
  post '/callback' => 'linebot#callback'
end
