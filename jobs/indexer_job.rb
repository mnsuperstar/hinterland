class IndexerJob < ApplicationJob
  queue_as :elasticsearch

  ELASTICSEARCH_POOL = ConnectionPool.new(size: 5, timeout: 5) { Searchable.new_elasticsearch_client }

  def perform(operation, *args)
    case operation
      when /index|update/
        ELASTICSEARCH_POOL.with do |client|
          record = args[0]
          klass = record.class
          client.index index: klass.index_name, type: klass.document_type, id: record.id, body: record.as_indexed_json
        end
      when /delete/
        ELASTICSEARCH_POOL.with do |client|
          klass_name, id = args
          klass = klass_name.constantize
          client.delete index: klass.index_name, type: klass.document_type, id: id
        end
      else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    raise unless operation == 'delete'
  end
end
