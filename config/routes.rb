Discourse::Application.routes.draw do
  post "/ai-for-instruments/send" => "ai_for_instruments#send_topic"
end
