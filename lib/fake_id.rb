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

      id_mapping.each do |id_sym, id|
        fake_id_mappings[column_name][id] = id_sym

        class_eval <<-EVAL
          def #{id_sym}?
            self.#{column_id} == id
          end
          alias :#{id_sym} :#{id_sym}?

          named_scope :#{id_sym}, :conditions => "#{column_id} = #{id}"
          named_scope :not_#{id_sym}, :conditions => "#{column_id} <> #{id}"
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

        def self.#{column_id}s_for(*id_syms)
          [*id_syms].map {|id_sym| #{column_name}_mapping.invert[id_sym] }
        end

        def #{column_name}
          self.class.#{column_name}_mapping[self.#{column_id}]
        end

        def #{column_name}=(id_sym)
          self.#{column_id} = self.class.#{column_name}_mapping.invert[id_sym]
        end

        named_scope :#{column_name}_in, lambda { |*id_syms|
          {:conditions => ["#{column_id} IN (?)", #{column_id}s_for(*id_syms)]}
        }
        named_scope :#{column_name}_not_in, lambda { |*id_syms|
          {:conditions => ["#{column_id} NOT IN (?)", #{column_id}s_for(*id_syms)]}
        }

        named_scope :#{column_name}_is, lambda { |id_sym|
          {:conditions => ["#{column_id} = ?", #{column_name}_mapping.invert[id_sym]]}
        }
        named_scope :#{column_name}_is_not, lambda { |id_sym|
          {:conditions => ["#{column_id} <> ?", #{column_name}_mapping.invert[id_sym]]}
        }
      EVAL

    end

  end

end