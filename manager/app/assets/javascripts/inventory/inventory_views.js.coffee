
namespace "Bixby.view.inventory", (exports, top) ->

  class exports.Layout extends Stark.View
    el: "#content"
    template: "inventory/layout"

  class exports.HostTable extends Stark.View
    el: "div.inventory_content"
    template: "inventory/host_table"
    links: {
      ".monitoring_host_link": [ "mon_view_host", (el) ->
        return { host: @hosts.get( $(el).attr("host_id") ) }
      ]
    }
