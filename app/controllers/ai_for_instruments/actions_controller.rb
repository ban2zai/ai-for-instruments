module AiForInstruments
  class ActionsController < ::ApplicationController
    requires_plugin 'ai-for-instruments'

    before_action :ensure_logged_in

    def send_webhook
      topic = Topic.find_by(id: params[:topic_id])
      raise Discourse::NotFound unless topic

      guardian.ensure_can_see!(topic)

      # только владелец темы
      if topic.user_id != current_user.id
        return render json: { error: "not_topic_owner" }, status: 403
      end

      allowed_categories = SiteSetting.ai_for_instruments_categories
        .to_s
        .split("|")
        .map(&:to_i)

      if allowed_categories.any? && !allowed_categories.include?(topic.category_id)
        return render json: { error: "wrong_category" }, status: 400
      end
      store_key = "topic_#{topic.id}_ai_usage"
      
      # Если не админ, проверяем лимиты
      unless is_admin
        usage_data = ::PluginStore.get('ai-for-instruments', store_key) || {}
        today = Time.now.utc.to_date.to_s
        
        # Если дата в базе не совпадает с сегодня, начинаем с 0, иначе берем count
        current_count = (usage_data['date'] == today) ? usage_data['count'].to_i : 0
        max_runs = SiteSetting.ai_for_instruments_max_attempts

        if current_count >= max_runs
           return render_json_error(I18n.t("ai_for_instruments.limit_reached"), status: 429)
        end

        # Увеличиваем счетчик и обновляем дату на "сегодня"
        new_data = {
          'count' => current_count + 1,
          'date' => today
        }
        ::PluginStore.set('ai-for-instruments', store_key, new_data)
      end

      payload = {
        topic_id: topic.id,
        topic_title: topic.title,
        topic_url: topic.url,
        user_id: current_user.id,
        username: current_user.username,
        is_admin_trigger: is_admin,
        created_at: Time.now.utc.iso8601
      }

      secret = SiteSetting.ai_for_instruments_hmac_secret
      signature = OpenSSL::HMAC.hexdigest("SHA256", secret, payload.to_json)

      begin
        Excon.post(
          SiteSetting.ai_for_instruments_webhook_url,
          body: payload.to_json,
          headers: { "Content-Type" => "application/json", "X-Signature" => signature }
        )
      rescue => e
        # Откат счетчика при ошибке (опционально)
        unless is_admin
           new_data['count'] -= 1
           ::PluginStore.set('ai-for-instruments', store_key, new_data)
        end
        return render_json_error("Error connecting to AI service")
      end

      render json: { ok: true }
    end

    # --- Новый метод для сброса (Только Админ) ---
    def reset_limit
      return render json: { error: "unauthorized" }, status: 403 unless current_user.admin?

      topic_id = params.require(:topic_id)
      store_key = "topic_#{topic_id}_ai_usage"
      
      # Удаляем запись из стора
      ::PluginStore.remove('ai-for-instruments', store_key)

      render json: { ok: true }
    end
  end
end
