# name: ai-for-instruments
# about: Send topics with instruments to n8n for AI documentation
# version: 0.1
# authors: Timur
# url: https://github.com/ban2zai/discourse-ai-for-instruments/

enabled_site_setting :ai_for_instruments_enabled

after_initialize do
  load File.expand_path('../app/controllers/ai_for_instruments_controller.rb', __FILE__)
end
