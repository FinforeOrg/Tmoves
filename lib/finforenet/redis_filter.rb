module Finforenet
  module RedisFilter

    def self.get_key(category)
      "#{category}_list".downcase
    end

    def self.get_array_ids(category)
      $redis.lrange get_key(category), 0, 1000
    end

    def self.del_data(category)
      $redis.del get_key(category)
    end
    
    def self.push_data(category,value)
      $redis.watch get_key(category)
      tmp_arr = get_array_ids(category)
      if tmp_arr.include?(value)
        return false
      else
        $redis.multi do
          $redis.lpop get_key(category) if (tmp_arr.length > 999)
          $redis.rpush get_key(category), value
        end
        return true
      end
    end

  end
end
