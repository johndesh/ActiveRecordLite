require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      self_id = self.send(through_options.foreign_key)
      through = through_options.model_class.where(through_options.primary_key => id).first
      through_id = through.send(source_options.foreign_key)

      source_options.model_class.where(source_options.primary_key => through_id).first
    end
  end
end
