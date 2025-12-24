AiForInstruments::Engine.routes.draw do
  # actions#send_webhook означает: ActionsController, метод send_webhook
  post "/send_webhook" => "actions#send_webhook"
end