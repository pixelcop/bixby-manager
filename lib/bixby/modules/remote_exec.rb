
module Bixby

class RemoteExec < API

  module Methods

    include HttpClient
    include Crypto

    # Execute a command on an Agent, automatically provisioning it if necessary
    #
    # @param [Agent] agent
    # @param [CommandSpec] command
    #
    # @return [CommandResponse]
    def exec(agent, command)

      command = create_spec(command)

      ret = exec_api(agent, "shell_exec", command.to_hash)

      if ret.success? || ret.code != 404 then
        return CommandResponse.from_json_response(ret)
      end

      # try to provision it, then try again
      ret = Provisioning.new.provision(agent, command)
      if not ret.success? then
        return CommandResponse.from_json_response(ret) # TODO raise err?
      end

      # try to exec again
      ret = exec_api(agent, "shell_exec", command.to_hash)
      return CommandResponse.from_json_response(ret)
    end

    # Convert various inputs to a CommandSpec wrapper
    #
    # @param [Object] command Can be a Hash/Command/String/CommandSpec
    # @return [CommandSpec]
    def create_spec(command)
      if command.kind_of? CommandSpec then
        command
      elsif command.kind_of? Command then
        command.to_command_spec
      elsif command.kind_of? Hash then
        CommandSpec.new(command)
      elsif command.kind_of? String then
        CommandSpec.from_json(command)
      elsif command.kind_of? Fixnum then
        Command.find(command).to_command_spec
      else
        command
      end
    end

    # Execute the given API request on an Agent
    #
    # @param [Agent] agent
    # @param [String] operation
    # @param [*Array] params
    #
    # @return [JsonResponse]
    def exec_api(agent, operation, params)
      begin
        uri = agent.uri
        post = JsonRequest.new(operation, params)
        debug { "uri: " + uri }
        debug { post.to_s }

        if crypto_enabled? then
          ret = http_post(uri, encrypt_for_agent(agent, post.to_json))
          res = decrypt_from_agent(agent, ret)
        else
          res = http_post_json(uri, post.to_json)
        end

        ret = JsonResponse.from_json(res)
        debug { ret.to_s }
        return ret

      rescue Curl::Err::CurlError => ex
        ret = JsonResponse.new("fail", ex.message, ex.backtrace)
        debug { ret.to_s }
        return ret
      end
    end

    # Execute the given API download request (download a file from an Agent)
    # TODO: not yet implemented!
    #
    # @param [String] uri
    # @param [JsonRequest] json_req     Request to download a file
    # @param [String] download_path     Location to download requested file to
    #
    # @return [JsonResponse]
    def exec_api_download(uri, json_req, download_path)
      raise "not yet implemented"
      begin
        http_post_download(uri, json_req.to_json, download_path)
        return JsonResponse.new("success")
      rescue Curl::Err::CurlError => ex
        return JsonResponse.new("fail", ex.message, ex.backtrace)
      end
    end

  end

end # RemoteExec

class API
  include RemoteExec::Methods
end

end # Bixby
