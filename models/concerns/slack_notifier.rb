module SlackNotifier
  extend ActiveSupport::Concern

  module ClassMethods
    def slack_notify_on *args
      options = args.extract_options!
      after_commit on: args do
        action = transaction_record_state(:new_record) ? :create :
                  destroyed? ? :destroy : :update
        send_slack_notification(options.merge(action: action))
      end
    end
  end

  def send_slack_notification action:, action_text: action, object: self, object_name: object.to_s, actor: nil
    return if ENV['SLACK_WEBHOOK_URL'].blank?

    actor ||= RequestStore.store[:current_user]
    actor = actor.is_a?(Symbol) && respond_to?(actor) ? send(actor) : actor
    object_url = Rails.application.routes.url_helpers.send("admin_#{object.class.table_name.singularize}_url", object, host: ENV['ROOT_DOMAIN']) rescue nil
    actor_url = Rails.application.routes.url_helpers.send("admin_#{actor.class.table_name.singularize}_url", actor, host: ENV['ROOT_DOMAIN']) rescue nil

    actor_name = actor ? actor.email : nil
    object_name = respond_to?(object_name) ? send(object_name) : id
    action_text = action_text[action] if action_text.is_a?(Hash)

    actor_name = "<#{[actor_url, actor_name.presence].compact.join('|')}>" if actor_url
    object_name = "<#{[object_url, object_name.presence].compact.join('|')}>" if object_url

    message = "#{actor_name || 'Someone'} #{action_text} #{object_name}"
    SlackNotifierJob.perform_later(message)
  end
end
