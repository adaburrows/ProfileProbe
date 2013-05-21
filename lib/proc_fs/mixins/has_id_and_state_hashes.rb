module ProcFS
  
  module HasIdAndStateHashes

    def generate_id_hash(id_data)
      ::Digest::MD5.hexdigest(id_data)
    end

    def generate_state_hash(state_data)
      ::Digest::MD5.hexdigest(state_data)
    end

  end

end
