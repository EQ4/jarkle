class @Visualizer3D
  constructor: (@_parent) ->
    @_animating = false
    @_updateDimensions()

    @_initResizeListener()

    cameraZ = Settings.viewer.threeD.drawDistance / 2
    cameraPosition = new THREE.Vector3(0, 0, cameraZ)

    @_initCamera(cameraPosition.clone())

    loader = new THREE.OBJMTLLoader
    @_initScene()
    @_initLights()
    @_initStarField()
    @_initDrumVisualization loader
    @_initCubes()
    @_initHeads()

    skeletonPosition = cameraPosition.clone()
    skeletonPosition.setZ(skeletonPosition.z * 0.9)
    @_initSkeletonVisualization loader, skeletonPosition

    @_onLoad()

    @_initRenderer()
    @_initControls()

    @_resize()
    @_render()


  # ==========================================================================
  # = Initialisation                                                         =
  # ==========================================================================

  _initResizeListener: ->
    @_resizeListener = new DomEventListener window,
      resize: @_onResize


  # ==========================================================================

  _initScene: ->
    @_scene = new THREE.Scene

  _initLights: ->
    @_scene.add new THREE.AmbientLight 0x888888
    @_scene.add new THREE.HemisphereLight 0xffeedd, 0xffeedd

  _initStarField: ->
    @_starField = new StarField
    @_starField.addToScene @_scene

  _initDrumVisualization: (loader) ->
    @_drumVisualization = new DrumVisualization loader

  _initCubes: ->
    @_cubes = new Cubes
    @_cubes.addToScene @_scene

  _initHeads: ->
    @_heads = new Head3DManager

  _initSkeletonVisualization: (loader, position) ->
    @_skeletonVisualization = new SkeletonVisualization loader, position
    @_skeletonListener = new PubsubNoteListener Singletons.getPubsub(), this

  _onLoad: ->
    THREE.DefaultLoadingManager.onLoad = =>
      @_drumVisualization.addToScene @_scene
      @_heads.addToScene @_scene
      @_skeletonVisualization.addToScene @_scene


  # ==========================================================================

  _initRenderer: ->
    @_renderer = new THREE.WebGLRenderer alpha: true
    @_parent.appendChild @_renderer.domElement

  _initCamera: (position) ->
    @_cameraManager = new CameraManager @_width, @_height, position

  _initControls: ->
    @_controls = new THREE.TrackballControls(
      @_cameraManager.getCamera(),
      @_renderer.domElement
    )
    @_controls.enabled = false


  # ==========================================================================
  # = Animation                                                              =
  # ==========================================================================

  _onAnimate: =>
    if @_animating
      requestAnimationFrame @_onAnimate
      @_animate()

  _animate: ->
    @_animateStarField()
    @_animateDrumVisualization()
    @_animateCubes()
    @_animateHeads()
    @_updateControls()
    @_render()

  _animateStarField: ->
    @_starField.animate()

  _animateDrumVisualization: ->
    @_drumVisualization?.animate()

  _animateCubes: ->
    @_cubes.animate()

  _animateHeads: ->
    @_heads.animate()

  _updateControls: ->
    @_controls.update()

  _render: ->
    @_renderer.render @_scene, @_cameraManager.getCamera()


  # ==========================================================================
  # = Inputs                                                                 =
  # ==========================================================================

  onInputStart: (input) =>
    @_cubes.onInputStart input
    @_heads.onInputStart input

  onInputMove: (input) =>
    @_cubes.onInputMove input
    @_heads.onInputMove input

  onInputStop: (input) =>
    @_cubes.onInputStop input
    @_heads.onInputStop input

  onDrumHit: (drumName) =>
    @_drumVisualization.onDrumHit drumName

  onSkeletons: (skeletons) =>
    @_skeletonVisualization.onSkeleton skeletons[0]?.skeleton

  onNoteStart: (note) =>
    if note.jointA?
      @_skeletonVisualization.onNoteStart note

  onNoteMove: (note) =>
    if note.jointA?
      @_skeletonVisualization.onNoteMove note

  onNoteStop: (note) =>
    if note.jointA?
      @_skeletonVisualization.onNoteStop note


  # ==========================================================================
  # = Resize                                                                 =
  # ==========================================================================

  _onResize: (event) =>
    @_updateDimensions()
    @_resize()

  _updateDimensions: ->
    @_width = window.innerWidth
    @_height = window.innerHeight

  _resize: ->
    @_resizeRenderer()
    @_cameraManager.resize @_width, @_height

  _resizeRenderer: ->
    @_renderer.setSize @_width, @_height


  # ==========================================================================
  # = Controls                                                               =
  # ==========================================================================

  enable: ->
    @_skeletonListener.enable()
    @_enableResizeListener()
    @_animating = true
    @_onAnimate()

  enableControls: ->
    @_controls.enabled = true

  _enableResizeListener: ->
    @_resizeListener.enable()

  disable: ->
    @_skeletonListener.disable()
    @disableControls()
    @_disableResizeListener()
    @_animating = false

  disableControls: ->
    @_controls.enabled = false

  _disableResizeListener: ->
    @_resizeListener.disable()

