require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL).first.map(&:to_sym)
      SELECT
        *
      FROM
        #{table_name}
      SQL
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        @attributes[column]
      end

      define_method("#{column}=") do |value|
        @attributes ||= {}
        @attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self.to_s.downcase}s"
  end

  def self.all
    parse_all(DBConnection.execute(<<-SQL))
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
  end

  def self.parse_all(results)
    results.map { |hash| new(hash) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = #{id}
    SQL

    parse_all(results).first
  end

  def initialize(params = {})
    params.each do |k, v|
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(k.to_sym)
      self.send("#{k}=", v)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def attribute_values_for_sql
    attribute_values.map{|val| val.is_a?(Integer) ? val : "'#{val}'"}
  end

  def insert
    cols = attributes.keys.join(', ')

    vals = attribute_values_for_sql.join(', ')

    DBConnection.execute(<<-SQL)
      INSERT INTO
        #{self.class.table_name} (#{cols})
      VALUES
        (#{vals})
      SQL
    self.id = DBConnection.last_insert_row_id
    self.class.all << self
  end

  def update
    cols = attributes.keys

    vals = attribute_values_for_sql

    cols = cols.map.with_index { |col, i| next if col == ":id"; "#{col} = #{vals[i]}" }.join(", ")

    DBConnection.execute(<<-SQL)
      UPDATE
        #{self.class.table_name}
      SET
        #{cols}
      WHERE
        id = #{self.id}
    SQL
  end

  def save
    attributes[:id].nil? ? self.insert : self.update
  end
end
