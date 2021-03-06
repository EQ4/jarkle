class @Head3DAppearances
  constructor: (@_loader, @_appearances) ->
    @_initHeads()
    @_initCycle()
    @_initInputs()

  _initHeads: ->
    options = Settings.viewer.threeD.heads
    @_heads = {}
    for {name: name, obj: objUrl, mtl: mtlUrl} in @_appearances
      head = new Head3DAppearance @_loader, objUrl, mtlUrl, options
      @_heads[name] = head

  _initCycle: ->
    @_cycle = cycle _.shuffle _.keys @_heads

  _initInputs: ->
    @_inputs = {}

  addToScene: (scene) ->
    for name, head of @_heads
      head.addToScene scene

  animate: ->
    for name, head of @_heads
      head.animate()

  onInputStart: (input) ->
    @_assignHead input
    @_getHead(input).onInputStart input

  onInputMove: (input) ->
    @_getHead(input)?.onInputMove input

  onInputStop: (input) ->
    @_getHead(input)?.onInputStop input

  _assignHead: (input) ->
    userId = input.userId
    unless @_inputs[userId]?
      @_inputs[userId] = @_heads[@_cycle()]

  _getHead: (input) ->
    @_inputs[input.userId]

