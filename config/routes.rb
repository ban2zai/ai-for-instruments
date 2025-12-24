AiForInstruments::Engine.routes.draw do
  post "/send_webhook" => "actions#send_webhook"
  post "/reset_limit" => "actions#reset_limit"
end