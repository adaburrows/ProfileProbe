module ProcFS
  
  module HasIdAndStateHashes

    attr_accessor :state_hash, :id_hash

    def generate_id_hash(id_data)
      ::Digest::MD5.hexdigest(id_data)
    end

    def generate_state_hash(state_data)
      ::Digest::MD5.hexdigest(state_data)
    end

    def compute_hashes
      @id_hash    = generate_id_hash(get_id_for_hash)
      @state_hash = generate_state_hash(get_state_for_hash)
    end

  end

end
