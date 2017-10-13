# == Schema Information
#
# Table name: sendgrid_events
#
#  id         :integer          not null, primary key
#  from       :string
#  to         :string
#  subject    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  data       :text
#

class SendgridEvent < ApplicationRecord
  serialize :data, Hash

  after_commit :process_event, on: [:create]

  def self.create_from_webhook params
    attributes = params.slice(:from, :to, :subject)
    attributes[:data] = params.except :'attachment-info', :attachmentX
    create attributes
  end

  def sender
    User.find_by(email: from.scan(/([^@\s<"']+@(?:[^@\s>"']+\.)+[^\W]+)/).flatten.first.downcase)
  end

  def sender_email
    sender.try(:email_alias) || from
  end

  def recipient_emails
    to.present? ? scan_email_aliases(to) : []
  end

  def recipients
    User.where(email_alias: recipient_emails)
  end

  def body
    data[:text].presence || data[:html]
  end

  private

  def process_event
    if recipients.exists?
      SendgridEventJob.perform_later(self) if recipients.exists?
    end
  end

  def scan_email_aliases string
    r = Regexp.new("([^\\W]+@#{ENV.fetch('EMAIL_ALIAS_DOMAIN', 'reply.gohinterlands.com').gsub('.', '\.')})")
    string.scan(r).flatten.uniq.map(&:downcase)
  end
end
