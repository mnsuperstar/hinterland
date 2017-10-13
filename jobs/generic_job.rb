class GenericJob < ApplicationJob
  queue_as :default

  def perform(obj, method_name)
    obj.send(method_name)
  end
end
