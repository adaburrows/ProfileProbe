module ProcFS

  module HasPrintableHash

    attr_accessor :separator

    def to_s
      ret_vals = []
      entry_separator = separator || "\n"
      self.each do |name, value|
        ancestry = self.class.ancestors
        if (ancestry.include? ::ProcFS::PropertyBag or ancestry.include? ::ProcFS::IdStateList)
          value_string = value.to_s.gsub("\n", "\n  ").prepend("\n  ")
        else
          value_string = value.to_s
        end
        ret_vals << "#{name}: #{value_string}" unless value.nil?
      end
      ret_vals.join(entry_separator)
    end

  end

end