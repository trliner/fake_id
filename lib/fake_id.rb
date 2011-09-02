module FakeId

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def fake_ids_for(column_name, id_mapping)
      column_id = (column_name.to_s + "_id").to_sym

      # mappings are stored in a class level hash
      class_inheritable_hash :fake_id_mappings
      write_inheritable_attribute(:fake_id_mappings, {}) if fake_id_mappings.nil?
      fake_id_mappings[column_name] ||= {}

      id_mapping.each do |name, id|
        fake_id_mappings[column_name][id] = name
      end

      class_eval <<-EVAL
        def #{column_name}
          self.class.fake_id_mappings[:#{column_name}][self.#{column_id}]
        end

        def #{column_name}=(id_sym)
          self.#{column_id} = self.class.fake_id_mappings[:#{column_name}].invert[id_sym]
        end

        def self.#{column_name.to_s.pluralize}
          self.fake_id_mappings[:#{column_name}].values
        end
      EVAL

    end

  end

end