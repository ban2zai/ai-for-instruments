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