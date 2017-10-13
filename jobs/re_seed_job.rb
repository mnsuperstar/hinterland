class ReSeedJob < ApplicationJob
  queue_as :default

  def perform
    require 'rake'
    ::Rake::Task.clear
    ::Rails.application.load_tasks
    ::Rake::Task['db:re_seed'].reenable
    ::Rake::Task['db:re_seed'].invoke
  end
end
