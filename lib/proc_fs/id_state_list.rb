module ProcFS

  class IdStateList

    include Enumerable
    include ::ProcFS::HasPrintableHash
    include ::ProcFS::HasIdAndStateHashes

    attr_accessor :id_index, :state_index

    def initialize(passthrough_id_index = {}, passthrough_state_index = {})
      @separator = "\n"
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

    ## Function diffs state across two lists sharing the same ids
    ## All list elements must implement a `-` operator that returns nil
    ## of their values are the same, otherwise, it should only return
    ## the diffs
    def -(rhs_list)
      delta_id_index = {}
      delta_state_index = {}

      rhs_list.each do |id, element|
        begin
          delta = @id_index[id] - element
        rescue
          puts "*** Attempted to subtract #{element.id} from nil"
          delta = nil
        end
        unless delta.nil?
          delta_id_index[id] = delta
          delta_state_index[delta.state_hash] = delta
        end
      end

      return self.class.new(delta_id_index, delta_state_index)
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

  end

end