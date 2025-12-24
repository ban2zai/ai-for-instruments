class AiForInstrumentsController < ApplicationController
  requires_plugin 'ai-for-instruments'

  before_action :ensure_logged_in

  def send_topic
    topic = Topic.find_by(id: params[:topic_id])
    raise Discourse::NotFound unless topic

    guardian.ensure_can_see!(topic)

    if topic.user_id != current_user.id
      return render json: { error: "not_topic_owner" }, status: 403
    end

    category_id = SiteSetting.ai_for_instruments_category.to_i
    if category_id.positive? && topic.category_id != category_id
      return render json: { error: "wrong_category" }, status: 400
    end

    payload = {
      topic_id: topic.id,
      topic_title: topic.title,
      topic_url: topic.url,
      user_id: current_user.id,
      username: current_user.username,
      created_at: Time.now.utc.iso8601
    }

    secret = SiteSetting.ai_for_instruments_hmac_secret
    signature = OpenSSL::HMAC.hexdigest(
      "SHA256",
      secret,
      payload.to_json
    )

    Excon.post(
      SiteSetting.ai_for_instruments_webhook_url,
      body: payload.to_json,
      headers: {
        "Content-Type" => "application/json",
        "X-Signature" => signature
      }
    )

    render json: { ok: true }
  end
end
