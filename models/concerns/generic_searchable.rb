module GenericSearchable
  extend ActiveSupport::Concern

  included do
    include Searchable

    mapping do
      klass = type.classify.constantize
      klass.searchable_mappings.each do |c, o|
        indexes c, o
      end
    end
  end

  module ClassMethods
    def searchable_mappings
      Hash[*searchable_columns.map do |c|
        [c, { type: defined_enums.include?(c) ? 'string' : searchable_column_type(columns_hash[c].type) }]
      end.flatten(1)]
    end

    def searchable_columns
      column_names
    end

    private

    def searchable_column_type c
      special_mappings = HashWithIndifferentAccess.new(
        datetime: 'date',
        decimal: 'double',
        text: 'string',
        time: 'date'
      )
      special_mappings[c] || c
    end
  end
end