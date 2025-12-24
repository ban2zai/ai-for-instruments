# name: ai-for-instruments
# about: Send topics with instruments to n8n for AI documentation
# version: 0.1
# authors: ban2zai
# url: https://github.com/ban2zai/ai-for-instruments/

enabled_site_setting :ai_for_instruments_categories

# 1. Загружаем определение Engine
load File.expand_path('../lib/ai_for_instruments/engine.rb', __FILE__)

# 2. Монтируем Engine к основному приложению Discourse
Discourse::Application.routes.append do
  mount ::AiForInstruments::Engine, at: "/ai_for_instruments"
end

after_initialize do
  # Добавляем поле 'ai_requests_left' в модель поста (JSON), который уходит на фронт
  add_to_serializer(:post, :ai_requests_left) do
    # Логика расчета остатка
    # Выполняем только для первого поста темы, чтобы не нагружать базу лишними запросами
    return nil if object.post_number != 1
    
    # 1. Получаем данные из хранилища
    store_key = "topic_#{object.topic_id}_ai_usage"
    usage_data = ::PluginStore.get('ai-for-instruments', store_key) || {}
    
    # 2. Проверяем дату (UTC). Если дата сменилась — считаем, что использовано 0
    today = Time.now.utc.to_date.to_s
    used_today = (usage_data['date'] == today) ? usage_data['count'].to_i : 0
    
    # 3. Считаем остаток
    max_runs = SiteSetting.ai_for_instruments_max_attempts
    left = max_runs - used_today
    left < 0 ? 0 : left
  end
end