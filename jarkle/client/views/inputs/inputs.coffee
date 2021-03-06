Template.inputs.rendered = ->
  trigger = @data.trigger
  target = @find '.inputs'

  @_mouse = new MouseInput trigger, target, @data.isMaster
  @_touch = TouchInput.create trigger, target, @data.isMaster, @data.maxTouches

  @_enableComp = Deps.autorun =>
    if Session.get 'enableInputs'
      @_mouse.enable()
      @_touch.enable()
    else
      @_mouse.disable()
      @_touch.disable()


Template.inputs.helpers
  style: ->
    unless Session.equals 'enableInputs', true
      'display: none;'


Template.inputs.destroyed = ->
  @_enableComp?.stop()
  @_touch?.disable()
  @_mouse?.disable()

