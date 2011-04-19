
require 'http_client'

class Agent < ActiveRecord::Base

    # validations
    validates_presence_of :port, :uuid, :public_key
    validates_uniqueness_of :uuid, :public_key

    include HttpClient

    def run_cmd(cmd)

        req = JsonRequest.new("exec", cmd.to_hash)
        res = http_post_json(agent_uri, req.to_json)
        # p res

    end

    def agent_uri
        "http://#{self.ip}:#{self.port}/"
    end

end
