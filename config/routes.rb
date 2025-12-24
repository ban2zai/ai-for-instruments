AiForInstruments::Engine.routes.draw do
  post "/send_webhook" => "ai_for_instruments#send_webhook"
end

Discourse::Application.routes.append do
  mount ::AiForInstruments::Engine, at: "/ai_for_instruments"
end
