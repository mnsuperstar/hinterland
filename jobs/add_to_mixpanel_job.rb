class AddToMixpanelJob < ApplicationJob
  queue_as :default

  def perform user_id
    user = User.find_by(id: user_id)
    MixpanelPeople.new.add(user) if user
  end
end
