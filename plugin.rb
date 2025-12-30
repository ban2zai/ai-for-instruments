# name: ai-for-instruments
# about: Send topics with instruments to n8n for AI documentation
# version: 0.1
# authors: ban2zai
# url: https://github.com/ban2zai/ai-for-instruments/

enabled_site_setting :ai_for_instruments_categories

load File.expand_path('../lib/ai_for_instruments/engine.rb', __FILE__)

Discourse::Application.routes.append do
  mount ::AiForInstruments::Engine, at: "/ai_for_instruments"
end

AiForInstruments::Engine.routes.draw do
  post "/send_webhook" => "actions#send_webhook"
  post "/reset_limit" => "actions#reset_limit"
  post "/chat" => "actions#chat"
  get "/chat_history" => "actions#chat_history"
  post "/clear_chat" => "actions#clear_chat"
end

after_initialize do
  add_to_serializer(:post, :ai_requests_left) do
    # Считаем только для первого поста
    return nil if object.post_number != 1
    
    store_key = "topic_#{object.topic_id}_ai_usage"
    usage_data = ::PluginStore.get('ai-for-instruments', store_key) || {}
    
    # Получаем настройки
    max_runs = SiteSetting.ai_for_instruments_max_attempts
    reset_hours = SiteSetting.ai_for_instruments_reset_hours
    
    # Логика времени
    last_window_start = usage_data['window_start'] ? Time.parse(usage_data['window_start']) : Time.at(0)
    time_passed = Time.now.utc - last_window_start
    
    # Если прошло больше времени, чем задано в настройках (в секундах)
    if time_passed > reset_hours.hours
      # Считаем, что счетчик сбросился
      used_count = 0
    else
      # Иначе берем текущее значение
      used_count = usage_data['count'].to_i
    end
    
    left = max_runs - used_count
    left < 0 ? 0 : left
  end
end
