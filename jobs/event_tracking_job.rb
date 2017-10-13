class EventTrackingJob < ApplicationJob
  queue_as :default

  def perform(subject, event, options = {})
    subject_id = subject_name = 'someone'
    if subject.is_a? User
      subject_id = subject.id
      subject_name = subject.user_type
    end
    tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
    event = "#{subject_name.titleize} #{event}"
    tracker.track(subject_id, event, options)
  end
end
