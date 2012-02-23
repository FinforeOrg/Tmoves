require 'memcache'
CACHE = MemCache.new :namespace => 'memcache_streaming',
                     :c_threshold => 10_000,
                     :compression => true,
                     :debug => false,
                     :readonly => false,
                     :urlencode => false
CACHE.servers = 'localhost:11211'