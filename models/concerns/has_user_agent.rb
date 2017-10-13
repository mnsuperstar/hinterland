module HasUserAgent
  extend ActiveSupport::Concern

  included do
    has_one :agent, as: :creator
    after_commit :set_agent, only: [:create]
    attr_accessor :browser, :platform
  end

  private

  def set_agent
    if browser.present? || platform.present?
      Agent.create(creator: self, browser: browser, platform: platform)
    end
  end
end
