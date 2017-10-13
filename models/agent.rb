# == Schema Information
#
# Table name: agents
#
#  id           :integer          not null, primary key
#  creator_type :string
#  creator_id   :integer
#  browser      :string
#  platform     :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Agent < ApplicationRecord
  belongs_to :creator, polymorphic: true

  def self.count_user_agents_browser type
    user_agents = Agent.where(creator_type: type.classify).group_by(&:browser)
    user_agents.each do |agent|
      user_agents[agent.first] = agent.size
    end
    user_agents
  end

  def self.count_user_agents_platform type
    user_agents = Agent.where(creator_type: type.classify).group_by(&:platform)
    user_agents.each do |agent|
      user_agents[agent.first] = agent.size
    end
    user_agents
  end
end
