module ActiveModelAttributes
  extend ActiveSupport::Concern

  class_methods do
    def attr_names
      @attributes
    end

    private

    def attr_accessor(*vars)
      @attributes ||= []
      @attributes += vars.map{|v| v.to_sym}
      super
    end
  end

  def attributes
    Hash[*self.class.attr_names.map{|a| [a, public_send(a)]}.flatten(1)]
  end

  def attributes= val
    val.each do |a, v|
      public_send("#{a}=", v) if a.to_sym.in?(self.class.attr_names)
    end
  end
end
