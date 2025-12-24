module AiForInstruments
  class ActionsController < ::ApplicationController
    requires_plugin 'ai-for-instruments'
    before_action :ensure_logged_in

    # POST /ai_for_instruments/send_webhook
    def send_webhook
      # 1. Поиск темы и проверка базовых прав просмотра
      topic = Topic.find_by(id: params[:topic_id])
      raise Discourse::NotFound unless topic
      guardian.ensure_can_see!(topic)

      # 2. Определение ролей
      is_admin = current_user.admin?
      is_owner = topic.user_id == current_user.id

      # Разрешаем только владельцу или админу
      unless is_owner || is_admin
        return render json: { error: "not_authorized" }, status: 403
      end

      # 3. Проверка разрешенных категорий
      allowed_categories = SiteSetting.ai_for_instruments_categories
        .to_s
        .split("|")
        .map(&:to_i)

      if allowed_categories.any? && !allowed_categories.include?(topic.category_id)
        return render json: { error: "wrong_category" }, status: 400
      end

      # 4. Логика ограничения количества запросов (Rate Limiting)
      # Админы игнорируют лимиты
      store_key = "topic_#{topic.id}_ai_usage"
      
      unless is_admin
        # Получаем данные из PluginStore
        usage_data = ::PluginStore.get('ai-for-instruments', store_key) || {}
        
        # Парсим время начала текущего окна (или берем 0, если запуска не было)
        window_start = usage_data['window_start'] ? Time.parse(usage_data['window_start']) : Time.at(0)
        
        # Получаем настройки из Settings
        reset_period = SiteSetting.ai_for_instruments_reset_hours.hours
        max_runs = SiteSetting.ai_for_instruments_max_attempts

        # Проверяем, не истекло ли временное окно
        if Time.now.utc > (window_start + reset_period)
          # Окно истекло -> Сбрас счетчика
          current_count = 0
          new_window_start = Time.now.utc # Начинаем новое окно прямо сейчас
        else
          # Окно активно -> Продолжаем считать
          current_count = usage_data['count'].to_i
          new_window_start = window_start # Оставляем старое время начала
        end

        # Если лимит исчерпан
        if current_count >= max_runs
          return render_json_error(
            I18n.t("ai_for_instruments.limit_reached"), 
            status: 429
          )
        end

        # Предварительно сохраняем инкремент счетчика
        # (Чтобы предотвратить спам-клики во время ожидания ответа от n8n)
        new_data = {
          'count' => current_count + 1,
          'window_start' => new_window_start.iso8601
        }
        ::PluginStore.set('ai-for-instruments', store_key, new_data)
      end

      # 5. Подготовка данных для n8n
      payload = {
        topic_id: topic.id,
        topic_title: topic.title,
        topic_url: topic.url,
        category_id: topic.category_id,
        user_id: current_user.id,
        username: current_user.username,
        is_admin_trigger: is_admin, # Полезно для логики внутри n8n
        created_at: Time.now.utc.iso8601
      }

      # 6. Подпись запроса (HMAC SHA256)
      secret = SiteSetting.ai_for_instruments_hmac_secret
      signature = OpenSSL::HMAC.hexdigest("SHA256", secret, payload.to_json)

      # 7. Отправка запроса
      begin
        Excon.post(
          SiteSetting.ai_for_instruments_webhook_url,
          body: payload.to_json,
          headers: {
            "Content-Type" => "application/json",
            "X-Signature" => signature
          }
        )
      rescue => e
        # Если произошла ошибка сети/n8n, откатываем счетчик назад,
        # чтобы пользователь не потерял попытку.
        unless is_admin
          # Считываем актуальное состояние (вдруг параллельно кто-то кликнул, хоть это и редкость)
          current_data = ::PluginStore.get('ai-for-instruments', store_key)
          if current_data
            current_data['count'] = [current_data['count'] - 1, 0].max # Не уходим в минус
            ::PluginStore.set('ai-for-instruments', store_key, current_data)
          end
        end
        
        # Логируем ошибку в консоль Rails для отладки
        Rails.logger.error("AI Plugin Error: #{e.message}")
        
        return render_json_error("Error connecting to AI service webhook")
      end

      render json: { ok: true }
    end

    # POST /ai_for_instruments/reset_limit
    # Метод для ручного сброса лимита админом
    def reset_limit
      # Строгая проверка на админа
      return render json: { error: "unauthorized" }, status: 403 unless current_user.admin?

      topic_id = params.require(:topic_id)
      store_key = "topic_#{topic_id}_ai_usage"
      
      # Полностью удаляем запись, сбрасывая и счетчик, и время окна
      ::PluginStore.remove('ai-for-instruments', store_key)

      render json: { ok: true }
    end
  end
end