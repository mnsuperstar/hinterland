module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    index_name [Rails.application.engine_name, Rails.env, table_name].join('_')

    after_commit on: [:create] do
      schedule_indexing 'index'
    end

    after_commit on: [:update] do
      schedule_indexing 'update'
    end

    after_commit on: [:destroy] do
      schedule_indexing 'delete'
    end
  end

  module ClassMethods
    def elasticsearch *args
      __elasticsearch__.search *args
    end
  end

  def self.new_elasticsearch_client
    if ENV['ELASTICSEARCH_HOST'] && ENV['ELASTICSEARCH_HOST'].include?('amazonaws.com')
      require 'patron'
      require 'faraday_middleware/aws_signers_v4'

      Elasticsearch::Client.new url: ENV['ELASTICSEARCH_HOST'], transport_options: {
        headers: { content_type: 'application/json' }
      } do |f|
        begin
          f.response :logger if Rails.logger.level <= 1 # send to log if log_level :debug or :info
        rescue NoMethodError
          # ignore NoMethodError in /activesupport/lib/active_support/logger_silence.rb:23:in `level' while precompiling
        end
        f.request :aws_signers_v4,
                  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
                  service_name: 'es',
                  region: ENV['AWS_REGION'].presence || 'us-east-1'
        f.adapter :patron
      end
    else
      Elasticsearch::Client.new
    end
  end

  def schedule_indexing action
    return if scheduled_indexing.include?(action.to_s)
    if action == 'delete'
      ::IndexerJob.perform_later('delete', self.class.name, id)
    else
      ::IndexerJob.perform_later(action, self)
    end
    scheduled_indexing << action.to_s
  end

  def scheduled_indexing
    @scheduled_indexing ||= []
  end
end
