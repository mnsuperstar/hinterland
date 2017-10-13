class AvataxJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |e|
    raise e unless e.message == 'Tax Error: The tax document could not be found.'
  end

  def perform(method, taxable)
    taxable.send(method)
  end
end
