module HinStripe
  class Base
    include ::ActiveModel::Model
    include ::ActiveModel::Dirty
    include ::ActiveModelAttributes


    def self.define_attributes *names
      define_attribute_methods *names
      @attributes ||= []
      @attributes += names.map{|name| name.to_sym}
      names.each do |name|
        define_method(name) do
          instance_variable_get("@#{name}")
        end
        define_method("#{name}=") do |v|
          send("#{name}_will_change!")
          instance_variable_set("@#{name}", v)
        end
      end
    end

    def self.associations
      @associations || []
    end

    def self.define_association name, klass
      define_attribute_methods name
      attr_accessor(name)
      @associations ||= []
      @associations << name.to_sym
      define_method("#{name}") do
        instance_variable_get("@#{name}").try(:attributes).try(:compact)
      end
      define_method("#{name}=") do |v|
        send("#{name}_will_change!")
        instance_variable_set("@#{name}", v.is_a?(klass) ? v : klass.new(v.try(:slice, *klass.attr_names)))
      end
    end

    def self.validate_association *names
      names.each do |name|
        define_method("#{name}_validity") do
          association = instance_variable_get("@#{name}")
          association.errors.each{|k,v| errors.add("#{name}_#{k}", v)} if association.present? && association.invalid?
        end
        validate "#{name}_validity".to_sym
      end
    end

    def [] name
      instance_variable_get("@#{name}")
    end

    def assign_attributes attributes
      attributes.each do |k, v|
        if k.to_sym.in?(self.class.associations) && (association = instance_variable_get("@#{k}"))
          association.assign_attributes(v)
          send("#{k}_will_change!") if association.changed?
        else
          send("#{k}=", v)
        end
      end
    end

    def nested_changes_applied
      changes_applied
      self.class.associations.each do |a|
        instance_variable_get("@#{a}").try(:nested_changes_applied)
      end
    end
  end
end
