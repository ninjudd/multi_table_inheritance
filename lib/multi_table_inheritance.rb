module MultiTableInheritance
  module ActiveRecord
    def multi_table_inheritance
      set_table_name(name.underscore.pluralize)
    end
  end

  module PostgreSQLAdapter
    def create_table(table_name, options = {})
      if options[:inherits_from]
        options[:id] = false
        options[:options] ||= ''
        options[:options] << "INHERITS (#{options[:inherits_from]})"
      end
      super(table_name, options)
    end
  end
end

ActiveRecord::Base.extend(MultiTableInheritance::ActiveRecord)
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send(:include, MultiTableInheritance::PostgreSQLAdapter)
