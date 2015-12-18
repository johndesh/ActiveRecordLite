require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || "#{name.downcase}_id".to_sym
    @class_name = options[:class_name] || name.to_s.capitalize
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @class_name = options[:class_name] || name.to_s.chop.capitalize
    @foreign_key = options[:foreign_key] || "#{self_class_name.downcase}_id".to_sym
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    assoc = BelongsToOptions.new(name, options)
    instance_variable_set(:@assoc_options, {name => assoc})
    define_method(name) do

      foreign_key = assoc.foreign_key
      primary_key = assoc.primary_key

      id = self.send(foreign_key)
      return nil if id.nil?
      assoc.model_class.where(primary_key => id).first
    end
  end

  def has_many(name, options = {})
    define_method(name) do
      assoc = HasManyOptions.new(name, self.class.to_s, options)
      foreign_key = assoc.foreign_key
      primary_key = assoc.primary_key
      self_id = self.send(primary_key)
      assoc.model_class.where(foreign_key => self_id)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
