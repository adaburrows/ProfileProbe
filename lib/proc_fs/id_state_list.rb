module ProcFS

  class IdStateList

    include Enumerable
    include ::ProcFS::HasPrintableHash
    include ::ProcFS::HasIdAndStateHashes

    attr_accessor :id_index, :state_index

    def initialize(passthrough_id_index = {}, passthrough_state_index = {})
      @id_index = passthrough_id_index
      @state_index = passthrough_state_index
      @id_hash = generate_id_hash(@id_index.keys.join)
      @state_hash = generate_state_hash(@state_index.keys.join)
    end

    def each
      @id_index.each do |id, element|
        yield id, element
      end
    end

    def each_by_id
      @id_index.each do |id, list_element|
        yield id, list_element
      end
    end

    def each_by_state
      @state_index.each do |hash, list_element|
        yield hash, list_element
      end
    end

    def fetch(id)
      @id_index[id]
    end

    def [](id)
      @id_index[id]
    end

    def to_hash
      hash_copy = Hash[@id_index]
      hash_copy[:id_hash] = @id_hash
      hash_copy[:state_hash] = @state_hash
    end

    def filter_by_id(id_list)
      filtered_id_index = {}
      filtered_state_index = {}

      id_list.each do |id|
        element = @id_index[id]
        unless element.nil?
          filtered_id_index[element.id] = element
          filtered_state_index[element.state_hash] = element
        end
      end

      return self.class.new(filtered_id_index, filtered_state_index)
    end

    def filter_by_list(property, value_list)
      filtered_id_index = {}
      filtered_state_index = {}

      @id_index.each do |id, element|
        value_list.each do |value|
          if element[property] and value == element[property]
            filtered_id_index[id] = element
            filtered_state_index[element.state_hash] = element
          end
        end
      end

      return self.class.new(filtered_id_index, filtered_state_index)
    end

    def filter_by_regex(property, regex_list)
      filtered_id_index = {}
      filtered_state_index = {}

      @id_index.each do |id, element|
        regex_list.each do |rx|
          element[property]
          if element[property] and rx =~ element[property]
            filtered_id_index[id] = element
            filtered_state_index[element.state_hash] = element
          end
        end
      end

      return self.class.new(filtered_id_index, filtered_state_index)
    end

    ## All list elements must implement a `-` operator that returns nil
    ## of their values are the same, otherwise, it should only return
    ## the diffs
    def -(rhs_list)
        lhs_list = self
        diff = nil

        unless lhs_list == rhs_list
          delta_struct = {
            :lhs_state  => lhs_list.state_hash,
            :rhs_state  => rhs_list.state_hash
          }

          lhs_only_id_list = lhs_list.diff_ids rhs_list
          rhs_only_id_list = rhs_list.diff_ids lhs_list
          lhs_only_states_raw = lhs_list.diff_states rhs_list
          rhs_only_states_raw = rhs_list.diff_states lhs_list
          lhs_only_states = lhs_only_states_raw.diff_ids lhs_only_id_list
          rhs_only_states = rhs_only_states_raw.diff_ids rhs_only_id_list

          delta_id_index = {}
          delta_state_index = {}

          lhs_only_states.each do |id, lhs|
            delta = lhs - rhs_only_states[id]
            unless delta.nil?
              delta_id_index[id] = delta
              delta_state_index[delta.state_hash] = delta
            end
          end

          deltas = self.class.new(delta_id_index, delta_state_index)

          delta_struct[:lhs_only] = lhs_only_id_list unless lhs_only_id_list.empty?
          delta_struct[:rhs_only] = rhs_only_id_list unless rhs_only_id_list.empty?
          delta_struct[:deltas] = deltas unless deltas.empty?

          diff = ::ProcFS::PropertyBag.new(delta_struct)
        end

        return diff
    end

    def diff_ids(rhs_list)
      delta_id_index = {}
      delta_state_index = {}

      rhs_ids = rhs_list.id_index.keys
      lhs_ids = @id_index.keys

      delta_ids = lhs_ids - rhs_ids

      delta_ids.each do |id|
        list_element = @id_index[id]
        delta_id_index[id] = list_element
        delta_state_index[list_element.state_hash] = list_element
      end

      return self.class.new(delta_id_index, delta_state_index)
    end

    def diff_states(rhs_list)
      delta_id_index = {}
      delta_state_index = {}

      rhs_state_hashes = rhs_list.state_index.keys
      lhs_state_hashes = @state_index.keys

      delta_state_hashes = lhs_state_hashes - rhs_state_hashes

      delta_state_hashes.each do |hash|
        list_element = @state_index[hash]
        delta_id_index[list_element.id] = list_element
        delta_state_index[hash] = list_element
      end

      return self.class.new(delta_id_index, delta_state_index)
    end

    def empty?
      @id_index.empty?
    end

    def has_same_items(rhs_list)
      @id_hash == rhs_list.id_hash
    end

    def ==(rhs_list)
      @state_hash == rhs_list.state_hash
    end

    def to_hash
      my_hash = {}
      @id_index.each do |name, value|
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