module ProcFS

  class PropertyBag < Hash

    include ::ProcFS::HasPrintableHash

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

    def to_hash
      my_hash = {}
      each do |name, value|
        ancestry = value.class.ancestors
        if (ancestry.include? ::ProcFS::PropertyBag or ancestry.include? ::ProcFS::IdStateList)
          my_hash[name] = value.to_hash
        else
          my_hash[name] = value
        end
      end
      return my_hash
    end

  end

end