module ProcFS

  class IdStateListItem < ::ProcFS::PropertyBag

    include ::ProcFS::HasIdAndStateHashes

    attr_accessor :id, :state_hash, :id_hash

    def initialize(property_hash = {})
      super(property_hash)
      @id = property_hash[:id] || ""
      compute_hashes
    end

    def -(rhs)
      list_item_delta = super(rhs)
      unless list_item_delta.nil?
        list_item_delta.id = @id
        list_item_delta.id_hash = @id_hash
        list_item_delta.state_hash = @state_hash
      end
      list_item_delta
    end

    def get_id_for_hash
      self.id
    end

    def get_state_for_hash
      values.join
    end

    def compute_hashes
      @id_hash    = generate_id_hash(get_id_for_hash)
      @state_hash = generate_state_hash(get_state_for_hash)
    end

  end

end