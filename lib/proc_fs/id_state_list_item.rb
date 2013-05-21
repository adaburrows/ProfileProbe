module ProcFS

  class IdStateListItem

    include ::ProcFS::HasIdAndStateHashes

    attr_accessor :id, :state_hash, :id_hash

    def initialize(*args)
      @id_hash    = generate_id_hash(get_id_for_hash)
      @state_hash = generate_state_hash(get_state_for_hash)
    end

    def get_id_for_hash
      self.id
    end

    def get_state_for_hash
      ""
    end

  end

end