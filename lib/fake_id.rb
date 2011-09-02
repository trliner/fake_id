module FakeId

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def fake_ids_for(column_name, id_mapping)
      column_id = (column_name.to_s + "_id").to_sym
      column_name_plural = column_name.to_s.pluralize

      # mappings are stored in a class level hash
      class_inheritable_hash :fake_id_mappings
      write_inheritable_attribute(:fake_id_mappings, {}) if fake_id_mappings.nil?
      fake_id_mappings[column_name] ||= {}

      id_mapping.each do |name, id|
        fake_id_mappings[column_name][id] = name

        class_eval <<-EVAL
          def #{name}?
            self.#{column_id} == id
          end
          alias :#{name} :#{name}?
        EVAL
      end

      class_eval <<-EVAL
        def self.#{column_name}_mapping
          self.fake_id_mappings[:#{column_name}]
        end

        def self.#{column_name_plural}
          #{column_name}_mapping.values
        end

        def self.lookup_#{column_name}(key)
          if key.to_sym == key
            #{column_name}_mapping.invert[key]
          else
            #{column_name}_mapping[key.to_i]
          end
        end

        def #{column_name}
          self.class.#{column_name}_mapping[self.#{column_id}]
        end

        def #{column_name}=(id_sym)
          self.#{column_id} = self.class.#{column_name}_mapping.invert[id_sym]
        end
      EVAL

    end

  end

end