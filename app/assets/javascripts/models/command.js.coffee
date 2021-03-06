
namespace 'Bixby.model', (exports, top) ->

  class exports.Command extends Stark.Model
    Backprop.create_strings @, "repo", "name", "bundle", "command"
    Backprop.create @, "options"

    params: [ { name: "command", set_id: true } ]

    urlRoot: ->
      "/rest/commands"


  class exports.CommandList extends Stark.Collection
    model: exports.Command
    params: [ "repo" ]
    url: ->
      s = "/rest/commands"
      s += "?repo_id=#{@repo_id}" if @repo_id
      s
