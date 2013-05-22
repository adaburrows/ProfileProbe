module ProcFS

  class PropertyBag < Hash

    def initialize(property_hash = {})
      super(nil)
      property_hash.each do |name, value|
        store(name, value)
      end
    end

    def method_missing(name, *args)
      self[name]
    end

    def -(rhs)
      delta = false
      property_bag_delta = self.class.new

      each do |name, value|
        if value != rhs[name]
          ancestry = value.class.ancestors
          if (ancestry.include? ::ProcFS::PropertyBag or ancestry.include? ::ProcFS::IdStateList)
            property_bag_delta[name] = value - rhs[name]
          else
            property_bag_delta[name] = value
          end
          delta = true
        end
      end

      return property_bag_delta if delta
      return nil
    end

    def to_s
      ret_vals = []
      each do |name, value|
        ancestry = self.class.ancestors
        if (ancestry.include? ::ProcFS::PropertyBag or ancestry.include? ::ProcFS::IdStateList)
          value_string = value.to_s.gsub("\n", "\n  ").prepend("\n  ")
        else
          value_string = value.to_s
        end
        ret_vals << "#{name}: #{value_string}" unless value.nil?
      end
      ret_vals.join("\n")
    end

  end

end