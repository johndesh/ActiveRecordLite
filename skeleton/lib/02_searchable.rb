require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    cond = params.map do |k, v|
      v.is_a?(Integer) ? "#{k} = #{v}" : "#{k} = '#{v}'"
    end.join(' AND ')

    parse_all(DBConnection.execute(<<-SQL))
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{cond}
    SQL
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable

end
