module HasUid
  extend ActiveSupport::Concern

  included do
    before_save :ensure_uid
  end

  module ClassMethods
    def find_by_uid(uid)
      where(uid: uid).first
    end

    def find_by_uid!(uid)
      where(uid: uid).first!
    end
  end

  def ensure_uid
    self.uid = generate_uid if uid.blank?
  end

  private

  def generate_uid
    loop do
      uid = SecureRandom.uuid
      break uid unless self.class.where(uid: uid).exists?
    end
  end
end
