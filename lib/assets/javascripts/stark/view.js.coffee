
"use strict"

window.Stark or= {}

class Stark.View extends Backbone.View

  # mixin logger
  _.extend @.prototype, Stark.Logger.prototype
  logger: "view"

  # [internal] Reference to the Stark::App instance
  app: null

  # [internal] Reference to the current Stark::State instance
  state: null

  # File name of the template rendered by this view
  template: null

  # Hash of links to create and bind.
  # The keys are selectors and the value is an array. The first element of the
  # array is the state name which will be activated when the link is clicked,
  # and the second value is a hash of data models to pass into the new state.
  #
  # Instead of a hash, a function may be passed which would be called onClick.
  # The result of this function should be a hash of models.
  #
  # Examples:
  #
  #   Simple links:
  #
  #     links: {
  #       "a.brand": [ "inventory" ]
  #       ".tab.monitoring a": [ "monitoring", { foo: "bar" } ]
  #     }
  #
  #   Using a function:
  #
  #     links: {
  #       ".monitoring_host_link": [ "mon_view_host", (el) ->
  #         return { host: @host }
  #       ]
  #     }
  #
  #   Using a function makes sure you get the correct context
  #
  links: null

  # List of events to subscribe to at the @app level
  app_events: null

  # List of models to bind to this view
  bindings: null

  # Set true to avoid redrawing on state changes
  reuse: false

  # List of sub-views
  views: null

  # List of post-render hooks
  after_render_hooks: null

  # Called from Backbone.View constructor
  initialize: (args) ->
    @_data = []
    @views = []
    @after_render_hooks = []
    if _.isObject(args)
      _.extend @, args
      for v in _.values(args)
        if v instanceof Stark.Model
          @_data.push(v)

    _.bindAll @
    return @

  # Cleanup any resources used by the view. Should remove all views and unbind any events
  dispose: ->
    @log "disposing of view ", @
    @$el.html("")
    @unbind_app_events()
    @undelegateEvents()
    @unbind_models()
    for v in @views
      v.dispose()
    @views = []


  # Rendering methods

  # Default implementation of Backbone.View's render() method. Simply renders
  # the @template into the element defined by @selector.
  #
  # Custom rendering should usually call super() before any additional
  # rendering.
  render: ->
    @$el.html(@render_html())

    @bind_app_events()
    @bind_link_events()
    @bind_models()
    @after_render()
    _.eachR @, @after_render_hooks, (hook) ->
      hook.call(@)

    return @

  # Actions to perform after rendering (e.g., attach custom events, jquery
  # plugins, etc)
  after_render: ->
    # noop

  # Redraw the view, taking care to first dispose of any events and subviews
  redraw: ->
    @dispose()
    @render()

  # Lookup @template in the global JST hash
  jst: (tpl) ->
    tpl ||= @template
    @log "render ", @, "file: ", tpl
    JST[tpl]

  # Create a Template object for the configured @template
  #
  # In practice, this can be overidden to use your preferred
  # template library, as long as it responds to #render(context),
  # where context is a reference to the view itself.
  create_template: ->
    new Template(@jst())

  # Render the configured @template to HTML
  render_html: ->
    return "" if not @template?
    @create_template().render(@)

  # Get or set the view's html.
  #
  # See also: jQuery.html()
  html: (args...) ->
    @$el.html(args...)

  # Set the given data/model on the view
  #
  # @param [String] key
  # @param [Object] val
  set: (key, val) ->
    @_data.push(val)
    @[key] = val


  # Events

  # Process @links hash and attach events
  bind_link_events: ->

    @log "bind_link_events", @

    if not @links?
      @log "binding events: ", @, @events
      @delegateEvents(@events)
      return

    link_events = @events || {}

    _.eachR @, @links, (link, sel) ->

      _.eachR @, @$(sel), (el) ->

        state = link[0]
        data = null
        if link.length > 1
          data = link[1]

        # setup delegate event
        link_events["click " + sel] = (e) ->
          if e.altKey || e.ctrlKey || e.metaKey || e.shiftKey
            return # let click go through (new tab, etc)

          # stop normal click event (navigate to href)
          # so we can instead do some internal routing (transition)
          e.preventDefault()
          @transition(state, @get_link_data(data, e.target))

        return if not @app.states[state]?

        # create url for the state with the required data from this view
        s = new @app.states[state]()
        _.extend s, @get_link_data(data, el)

        url = s.create_url()
        url = "/" + url if url.charAt(0) != '/'

        @$(el).attr("href", url)

    @log "binding events: ", @, link_events
    @delegateEvents(link_events)

  # Helper for resolving data to a set of actual values
  #
  # @param [Object] data    Data hash
  # @param [Element] el     Element which data should be generated for (in the function case)
  get_link_data: (data, el) ->
    ret = {}

    if not data?
      return ret

    if _.isArray(data)
      _.eachR @, data, (key) ->
        ret[key] = @[key]

    else if _.isFunction(data)
      data = data.call(@, el)
      _.eachR @, data, (val, key) ->
        ret[key] = val

    return ret

  # Bind all the models specified in @bindings
  bind_models: ->
    @log "binding models for view ", @
    return if not @bindings?
    for m in @bindings
      if @[m]?
        @unbind_model( @[m] )
        @bind_model( @[m] )

  # Bind a method to the given model, using this View as the context
  #
  # @param [Model] model
  bind_model: (model) ->
    model.bind_view(@)

  # Subscribe to all @app level events as defined in the @app_events var
  bind_app_events: ->
    _.eachR @, @app_events, (cb, key) ->
      @app.subscribe(key, cb, @)

  # Unsubscribe all @app level events (see #bind_app_events)
  unbind_app_events: ->
    _.eachR @, @app_events, (cb, key) ->
      @app.unsubscribe(key, cb, @)

  # Unbind all models from this view
  unbind_models: ->
    for m in @_data
      @unbind_model(m)

  # Unbind the given model from this view
  #
  # @param [Model] m
  unbind_model: (m) ->
    if _.isObject(m) && _.isFunction(m["unbind_view"])
      m.unbind_view(@)
    else if _.isArray(m)
      for mm in m
        @unbind_model(mm)


  # Methods dealing with partials, includes, etc.

  # A raw include of the contents of some other template. It will be bound with
  # the the same variables in this view.
  #
  # @param [String] tpl     Template to include
  include: (tpl) ->
    return new Template(@jst(tpl)).render(@)

  # Render a partial (sub) view into the given selector
  #
  # @param [Class] clazz      class name of view to render
  # @param [Object] data      context data for partial
  # @param [String] selector  optional CSS selector into which the partial view will be rendered
  #
  # @return [Object] view instance
  partial: (clazz, data, selector) ->
    v = @create_partial(clazz, data)
    if selector?
      v.setElement( @$(selector) )
    v.render()
    return v

  # Instantiate a partial class with the given data
  #
  # @param [Class] clazz
  # @param [Object] data
  #
  # @return [Object] view class instance
  create_partial: (clazz, data) ->
    data ||= {}
    data.app = @app
    data.state = @state

    v = null
    if _.isObject(clazz)
      v = new clazz(data)

    else if _.isString(clazz)
      # assume its a template name, create a generic instance
      v = new Stark.Partial(data)
      v.template = clazz

    @views.push(v)
    v.parent = @
    return v


  # Utility methods for use within view & view helpers

  # Proxy for Stark.state#transition
  transition: (state_name, state_data) ->
    @state.transition(state_name, state_data)

  # Fetch the values for the named attributes in this view.
  # This is a simple helper for retrieving values from forms.
  #
  # @param [String] names
  #
  # @return [Object] key/value pairs
  get_attributes: (names) ->
    ret = {}
    for name in arguments
      if name.indexOf(".") >= 0 or name.indexOf("#") >= 0
        ret[name] = @$(name).val()
      else
        ret[name] = @$("##{name}").val() || @$(".#{name}").val()

    return ret

  # Process a given string containing Markdown syntax
  #
  # @param [String] str
  #
  # @return [String] str converted to html
  markdown: (str) ->
    @_converter ||= new Markdown.Converter()
    @_converter.makeHtml(str)
