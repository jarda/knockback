module("knockback-inject.js")

ko = if not window.ko and (typeof(require) isnt 'undefined') then require('knockout') else window.ko
kb = if not window.kb and (typeof(require) isnt 'undefined') then require('knockback') else window.kb
_ = kb._

test("TEST DEPENDENCY MISSING", ->
  ok(!!ko, 'ko')
  ok(!!_, '_')
  ok(!!kb.Model, 'kb.Model')
  ok(!!kb.Collection, 'kb.Collection')
  ok(!!kb, 'kb')
)

window.appCreate = (view_model) -> view_model.app_create = true

window.app = (view_model) ->
  @app = true
  kb.statistics.register('app', @)
  @destroy = => kb.statistics.unregister('app', @)
  return @ # return self

window.appCallbacks = (view_model) ->
  @app = true
  kb.statistics.register('app', @)
  @destroy = => kb.statistics.unregister('app', @)

  @beforeBinding = => @before_was_called = true
  @afterBinding = => @after_was_called = true

  return @ # return self

class window.SuperClass
  constructor: ->
    @super_class = true
    kb.statistics.register('SuperClass', @)
  destroy: ->
    kb.statistics.unregister('SuperClass', @)

class window.SubClass extends SuperClass
  constructor: ->
    super
    @sub_class = true

test("1. kb-inject", ->
  kb.statistics = new kb.Statistics() # turn on stats

  # no attributes
  inject_el = $('<div kb-inject></div>')[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  equal(injected[0].el, inject_el, "no attr: app was injected")
  ko.removeNode(inject_el)

  # properties
  window.hello = true
  inject_el = $('<div kb-inject="hello: hello"><span data-bind="visible: hello"></span></div>')[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  equal(injected[0].el, inject_el, "Properties: app was injected")
  equal(view_model.hello, window.hello, "Properties: hello was injected")
  equal(view_model.hello, true, "Properties: hello is true")
  ko.removeNode(inject_el)

  # ViewModel solo
  inject_el = $('<div kb-inject="app"><span data-bind="visible: app"></span></div>')[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  equal(injected[0].el, inject_el, "ViewModel Solo: app was injected")
  ok(view_model instanceof window.app, "ViewModel Solo: view_model type app")
  equal(view_model.app, true, "ViewModel Solo: app is true")
  ko.removeNode(inject_el)

  # mutiliple ViewModel solos
  inject_el = $("""
    <div>
      <div kb-inject="app"><span data-bind="visible: app"></span></div>
      <div kb-inject="app"><span data-bind="visible: app"></span></div>
    </div>""")[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  view_model1 = injected[1].view_model
  equal(injected[0].el, inject_el.children[0], "ViewModel Solo: app was injected")
  ok(view_model instanceof window.app, "ViewModel Solo: view_model type app")
  equal(view_model.app, true, "ViewModel Solo: app is true")
  equal(injected[1].el, inject_el.children[1], "ViewModel Solo: app was injected")
  ok(injected[1].view_model instanceof window.app, "ViewModel Solo: view_model type app")
  equal(injected[1].view_model.app, true, "ViewModel Solo: app is true")
  ko.removeNode(inject_el)

  # Create function with callbacks
  inject_el = $('<div kb-inject="create: appCreate"><span data-bind="visible: app_create"></span></div>')[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  equal(injected[0].el, inject_el, "Create: app was injected")
  ok(not (view_model instanceof window.appCreate), "Create: view_model not type appCreate")
  ok(_.isObject(view_model), "Create: view_model is basic type")
  equal(view_model.app_create, true, "Create + Callbacks: view model was injected")
  ko.removeNode(inject_el)

  # ViewModel property
  inject_el = $('<div kb-inject="view_model: app"><span data-bind="visible: app"></span></div>')[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  equal(injected[0].el, inject_el, "ViewModel Property: app was injected")
  ok(view_model instanceof window.app, "ViewModel Property: view_model type app")
  equal(view_model.app, true, "ViewModel Property: hello is true")
  ko.removeNode(inject_el)

  # ViewModel property and Create should take ViewModel
  inject_el = $('<div kb-inject="view_model: app, create: appCreate"><span data-bind="visible: app"></span><span data-bind="visible: app_create"></span></div>')[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  equal(injected[0].el, inject_el, "Create: app was injected")
  ok(not (view_model instanceof window.appCreate), "Create: view_model not type appCreate")
  ok(_.isObject(view_model), "Create: view_model is basic type")
  ok(view_model instanceof window.app, "ViewModel Property: view_model type app")
  equal(view_model.app, true, "Create + Callbacks: view model was injected - ViewModel")
  equal(view_model.app_create, true, "Create + Callbacks: view model was injected - ViewModel, Create")
  ko.removeNode(inject_el)

  # Create and ViewModel property should take ViewModel
  inject_el = $('<div kb-inject="create: appCreate, view_model: app"><span data-bind="visible: app"></span><span data-bind="visible: app_create"></span></div>')[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  equal(injected[0].el, inject_el, "Create: app was injected")
  ok(not (view_model instanceof window.appCreate), "Create: view_model not type appCreate")
  ok(_.isObject(view_model), "Create: view_model is basic type")
  ok(view_model instanceof window.app, "ViewModel Property: view_model type app")
  equal(view_model.app, true, "Create + Callbacks: view model was injected - ViewModel")
  equal(view_model.app_create, true, "Create + Callbacks: view model was injected - Create, ViewModel")
  ko.removeNode(inject_el)

  # ViewModel Object
  inject_el = $('<div kb-inject="hello: true"><span data-bind="visible: hello"></span></div>')[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  equal(injected[0].el, inject_el, "ViewModel Object: app was injected")
  equal(view_model.hello, true, "ViewModel Object: hello is true")
  ko.removeNode(inject_el)

  # Mix of things
  inject_el = $("""
      <div kb-inject="view_model: SuperClass, sub_class: {view_model: SubClass}, created: {create: appCreate}, hello: true, embed: {hello: true}">
        <span data-bind="visible: super_class"></span>
        <span data-bind="visible: sub_class.sub_class"></span>
        <span data-bind="visible: created.app_create"></span>
        <span data-bind="visible: embed.hello"></span>
        <span data-bind="visible: hello"></span>
      </div>""")[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  equal(injected[0].el, inject_el, "ViewModel Object: app was injected")
  ok((view_model instanceof SuperClass), "Mix: is SuperClass")
  equal(view_model.super_class, true, "Mix: has super_class")
  ok((view_model.sub_class instanceof SubClass), "Mix: is SubClass")
  equal(view_model.sub_class.sub_class, true, "Mix: has sub_class")
  ok(not (view_model.created instanceof appCreate), "Mix: is not create")
  equal(view_model.created.app_create, true, "Mix: has create")
  equal(view_model.embed.hello, true, "Mix: embedded hello is true")
  equal(view_model.hello, true, "Mix: hello is true")
  ko.removeNode(inject_el)

  # Properties with callbacks
  before_was_called = false
  after_was_called = false
  window.beforeBinding = (view_model) -> before_was_called = view_model.hello
  window.afterBinding = (view_model) -> after_was_called = view_model.hello
  inject_el = $('<div kb-inject="hello: true, options: {beforeBinding: beforeBinding, afterBinding: afterBinding}"><span data-bind="visible: hello"></span></div>')[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  equal(injected[0].el, inject_el, "Properties + Callbacks: app was injected")
  equal(view_model.hello, true, "Properties + Callbacks: view model was injected")
  ok(before_was_called, "Properties + Callbacks: before_was_called was called")
  ok(after_was_called, "Properties + Callbacks: after_was_called was called")
  ko.removeNode(inject_el)

  # Create function with callbacks
  before_was_called = false
  after_was_called = false
  window.beforeBinding = (view_model) -> before_was_called = view_model.hello
  window.afterBinding = (view_model) -> after_was_called = view_model.hello
  inject_el = $('<div kb-inject="create: appCreate, hello: true, beforeBinding: beforeBinding, afterBinding: afterBinding"><span data-bind="visible: app_create"></span></div>')[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  equal(injected[0].el, inject_el, "Create + Callbacks: app was injected")
  ok(not (view_model instanceof window.appCreate), "Create: view_model not type appCreate")
  ok(_.isObject(view_model), "Create: view_model is basic type")
  equal(view_model.app_create, true, "Create + Callbacks: view model was injected")
  ok(before_was_called, "Create + Callbacks: before_was_called was called")
  ok(after_was_called, "Create + Callbacks: after_was_called was called")
  ko.removeNode(inject_el)

  # ViewModel property with callbacks
  inject_el = $('<div kb-inject="view_model: appCallbacks, hello: true"><span data-bind="visible: app"></span></div>')[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  equal(injected[0].el, inject_el, "ViewModel Property + Callbacks: app was injected")
  ok((view_model instanceof window.appCallbacks), "Create: view_model type appCallbacks")
  equal(view_model.app, true, "ViewModel Property + Callbacks: view model was injected")
  ok(view_model.before_was_called, "ViewModel Property + Callbacks: before_was_called was called")
  ok(view_model.after_was_called, "ViewModel Property + Callbacks: after_was_called was called")
  ko.removeNode(inject_el)

  # ViewModel Object with callbacks
  before_was_called = false
  after_was_called = false
  window.beforeBinding = (view_model) -> before_was_called = view_model.hello
  window.afterBinding = (view_model) -> after_was_called = view_model.hello
  inject_el = $('<div kb-inject="hello: true, options: {beforeBinding: beforeBinding, afterBinding: afterBinding}"><span data-bind="visible: hello"></span></div>')[0]
  $('body').append(inject_el)
  injected = kb.injectViewModels()
  view_model = injected[0].view_model
  equal(injected[0].el, inject_el, "ViewModel Object + Callbacks: app was injected")
  equal(view_model.hello, true, "ViewModel Object + Callbacks: view model was injected")
  ok(before_was_called, "ViewModel Object + Callbacks: before_was_called was called")
  ok(after_was_called, "ViewModel Object + Callbacks: after_was_called was called")
  ko.removeNode(inject_el)

  equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
)

test("2. data-bind inject recusive", ->
  kb.statistics = new kb.Statistics() # turn on stats

  previous = kb.RECUSIVE_AUTO_INJECT; kb.RECUSIVE_AUTO_INJECT = true

  was_auto_injected = 0
  class window.AutoInject
    constructor: ->
      was_auto_injected++
    destroy: ->
      was_auto_injected--

  # no attributes
  ok(!was_auto_injected, "Not auto injected")
  inject_el = $('<div kb-inject="AutoInject"></div>')[0]
  ko.applyBindings({}, inject_el)
  equal(was_auto_injected, 1, "Was auto injected")
  ko.removeNode(inject_el)
  ok(!was_auto_injected, "Not auto injected")

  # no attributes
  ok(!was_auto_injected, "Not auto injected")
  inject_el = $('<div kb-inject="AutoInject"><div><div kb-inject="AutoInject"></div></div></div>')[0]
  ko.applyBindings({}, inject_el)
  equal(was_auto_injected, 2, "Was auto injected")
  ko.removeNode(inject_el)
  ok(!was_auto_injected, "Not auto injected")

  kb.RECUSIVE_AUTO_INJECT = previous

  equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
)

test("3. data-bind inject", ->
  kb.statistics = new kb.Statistics() # turn on stats

  # properties
  inject_el = $('<div data-bind="inject: {hello: true}"><span data-bind="visible: hello"></span></div>')[0]
  view_model = {}
  kb.applyBindings(view_model, inject_el)
  equal(view_model.hello, true, "Properties: hello is true")
  ko.removeNode(inject_el)

  # Create solo
  inject_el = $('<div data-bind="inject: appCreate"><span data-bind="visible: app"></span></div>')[0]
  view_model = {}
  kb.applyBindings(view_model, inject_el)
  equal(view_model.app_create, true, "Create property: app_create is true")
  ko.removeNode(inject_el)

  # Create property
  inject_el = $('<div data-bind="inject: {create: appCreate}"><span data-bind="visible: app_create"></span></div>')[0]
  view_model = {}
  kb.applyBindings(view_model, inject_el)
  equal(view_model.app_create, true, "Create property: app_create is true")
  ko.removeNode(inject_el)

  # Function
  window.testFunction = (view_model) -> view_model.hello = true
  inject_el = $('<div data-bind="inject: {embedded: testFunction}"><span data-bind="click: embedded.testFunction"></span></div>')[0]
  view_model = {}
  kb.applyBindings(view_model, inject_el)
  equal(view_model.embedded, window.testFunction, "Function: is type testFunction")
  ko.removeNode(inject_el)

  # Create function
  inject_el = $('<div data-bind="inject: {embedded: {create: appCreate}}"><span data-bind="visible: embedded.app_create"></span></div>')[0]
  view_model = {}
  kb.applyBindings(view_model, inject_el)
  ok(not (view_model.embedded instanceof window.appCreate), "Create: view_model not type appCreate")
  ok(_.isObject(view_model.embedded), "Create: view_model is basic type")
  equal(view_model.embedded.app_create, true, "Create: view model was injected")
  ko.removeNode(inject_el)

  # ViewModel property
  inject_el = $('<div data-bind="inject: {embedded: {view_model: app}}"><span data-bind="visible: embedded.app"></span></div>')[0]
  view_model = {}
  kb.applyBindings(view_model, inject_el)
  ok(view_model.embedded instanceof window.app, "ViewModel Property: view_model type app")
  equal(view_model.embedded.app, true, "ViewModel Property: hello is true")
  ko.removeNode(inject_el)

  # ViewModel Object
  inject_el = $('<div data-bind="inject: {hello: true}"><span data-bind="visible: hello"></span></div>')[0]
  view_model = {}
  kb.applyBindings(view_model, inject_el)
  equal(view_model.hello, true, "ViewModel Object: hello is true")
  ko.removeNode(inject_el)

  # Mix of things
  inject_el = $("""
      <div data-bind="inject: {new_context: {view_model: SuperClass, sub_class: {view_model: SubClass}, created: {create: appCreate}, hello: true, embed: {hello: true}}}">
        <span data-bind="visible: new_context.super_class"></span>
        <span data-bind="visible: new_context.sub_class.sub_class"></span>
        <span data-bind="visible: new_context.created.app_create"></span>
        <span data-bind="visible: new_context.embed.hello"></span>
        <span data-bind="visible: new_context.hello"></span>
      </div>""")[0]
  view_model = {}
  kb.applyBindings(view_model, inject_el)
  ok((view_model.new_context instanceof SuperClass), "Mix: is SuperClass")
  equal(view_model.new_context.super_class, true, "Mix: has super_class")
  ok((view_model.new_context.sub_class instanceof SubClass), "Mix: is SubClass")
  equal(view_model.new_context.sub_class.sub_class, true, "Mix: has sub_class")
  ok(not (view_model.new_context.created instanceof appCreate), "Mix: is not create")
  equal(view_model.new_context.created.app_create, true, "Mix: has create")
  equal(view_model.new_context.embed.hello, true, "Mix: embedded hello is true")
  equal(view_model.new_context.hello, true, "Mix: hello is true")
  ko.removeNode(inject_el)

  equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
)