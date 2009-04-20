module MultiTableInheritance
  module ActiveRecord
    def multi_table_inheritance(opts = {})
      set_table_name(name.underscore.pluralize)
      base_class.send(:extend, MultiTableInheritance::ActiveRecord::ClassMethods)
      base_class.send(:include, MultiTableInheritance::ActiveRecord::InstanceMethods)
      base_class.multi_table_inheritance_opts(self, opts)
    end

    module ClassMethods
      def multi_table_inheritance_opts(sub_class, opt)
        @multi_table_inheritance_opts ||= {}
        if opt.kind_of?(Hash)
          @multi_table_inheritance_opts[sub_class] = opt
        else
          @multi_table_inheritance_opts[sub_class][opt]
        end
      end
      
      def default_select(qualified)
        if qualified
          "#{quoted_table_name}.*, #{quoted_table_name}.tableoid"
        else
          '*, tableoid'
        end
      end

      def construct_finder_sql(options)
        sql = super(options)
        sql.sub(' *', ' *, tableoid').sub(/(\w+\.)\*/, '\1.*, \1.tableoid')
      end
      
      def instantiate(record)
        record_class = oid_to_class(record['tableoid'])
        if record_class != self
          if base_class.multi_table_inheritance_opts(record_class, :add_fields)
            record_class.find(record['id'])
          else
            record_class.instantiate(record)
          end
        else
          super
        end
      end

      def oid_to_class(oid)
        return self unless oid
        @oid_to_class ||={}
        @oid_to_class[oid] ||= connection.select_value("select relname from pg_class where oid = #{oid}").classify.constantize
      end
    end

    module InstanceMethods
      def type
        self.class.oid_to_class(attributes['tableoid']).name
      end
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
