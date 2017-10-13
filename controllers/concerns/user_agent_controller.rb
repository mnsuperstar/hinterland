module UserAgentController
  private

  def user_agent
    {}.tap do |h|
      if action_name == 'create'
        user_agent = UserAgent.parse(request.user_agent)
        h.merge!(browser: user_agent.browser, platform: user_agent.platform)
      end
    end
  end
end
