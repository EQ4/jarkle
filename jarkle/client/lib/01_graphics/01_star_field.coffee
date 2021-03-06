class @StarField
  constructor: (settings) ->
    @_initSettings settings
    @_initStars()
    @_initMap()
    @_initMaterial()
    @_initSystem()

  _initSettings: (settings) ->
    @_fieldSize  = Settings.viewer.threeD.drawDistance

    settings = Settings.viewer.threeD.starField
    @_count      = settings.count
    @_mapUrl     = settings.map
    @_speed      = settings.speed
    @_starColor  = parseInt settings.starColor, 16
    @_starSize   = settings.starSize
    @_travelAxis = settings.travelAxis

  _initStars: ->
    @_stars = new THREE.Geometry
    @_stars.vertices = for i in [0...@_count]
      new THREE.Vector3(
        @_getRandomCoordinate(),
        @_getRandomCoordinate(),
        @_getRandomCoordinate()
      )

  _getRandomCoordinate: (scale = 1) ->
    scale * @_fieldSize * (Math.random() - 0.5)

  _initMap: ->
    @_map = THREE.ImageUtils.loadTexture @_mapUrl

  _initMaterial: ->
    @_material = new THREE.ParticleBasicMaterial
      blending: THREE.AdditiveBlending
      color: @_starColor
      map: @_map
      size: @_starSize
      transparent: true

  _initSystem: ->
    @_system = new THREE.ParticleSystem @_stars, @_material
    @_system.sortParticles = true

  addToScene: (scene) ->
    scene.add @_system

  animate: ->
    abs = Math.abs
    axis = @_travelAxis
    speed = @_speed
    limit = @_fieldSize / 2
    start = -sign(speed) * limit

    for star in @_stars.vertices
      if abs(star[axis] += speed) > limit
        star[axis] = start

    undefined

