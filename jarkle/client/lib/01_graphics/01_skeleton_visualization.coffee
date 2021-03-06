JOINTS = [
  'head'
  'neck'
  'leftShoulder'
  'rightShoulder'
  'leftElbow'
  'rightElbow'
  'leftHand'
  'rightHand'
  'torso'
  'leftHip'
  'rightHip'
  'leftKnee'
  'rightKnee'
  'leftFoot'
  'rightFoot'
]


LIMBS = [
  ['head'         , 'neck'         ]
  ['leftHand'     , 'leftElbow'    ]
  ['leftElbow'    , 'leftShoulder' ]
  ['rightHand'    , 'rightElbow'   ]
  ['rightElbow'   , 'rightShoulder']
  ['rightShoulder', 'leftShoulder' ]
  ['leftShoulder' , 'torso'        ]
  ['rightShoulder', 'torso'        ]
  ['torso'        , 'leftHip'      ]
  ['torso'        , 'rightHip'     ]
  ['leftHip'      , 'leftKnee'     ]
  ['leftKnee'     , 'leftFoot'     ]
  ['rightHip'     , 'rightKnee'    ]
  ['rightKnee'    , 'rightFoot'    ]
]


class @SkeletonVisualization
  constructor: (loader, @_position) ->
    options = @_initOptions()
    @_initHead loader, options
    @_initBoxes()
    @_initLines()

  _initOptions: ->
    @_scale = 0.1
    @_boxSize = 5
    @_boxOffColor = 0xff0000
    @_boxOnColor = 0xffffff
    @_boxLines = 0x00ff00
    Settings.viewer.threeD.skeleton

  _initHead: (loader, options) ->
    loader.load options.obj, options.mtl, (head) =>
      @_head = head
      head.traverse (descendant) ->
        descendant.visible = false

  _initBoxes: ->
    geometry = new THREE.BoxGeometry @_boxSize, @_boxSize, @_boxSize
    @_boxOffMaterial = new THREE.MeshBasicMaterial color: @_boxOffColor
    @_boxOnMaterial = new THREE.MeshBasicMaterial color: @_boxOnColor
    @_boxes = {}
    for joint in JOINTS
      box = new THREE.Mesh geometry, @_boxOffMaterial
      box.visible = false
      @_boxes[joint] = box

  _initLines: ->
    material = new THREE.LineBasicMaterial
      color: @_boxLines
      linewidth: 1000
    @_lines = for [jointA, jointB] in LIMBS
      geometry = new THREE.Geometry()
      geometry.vertices.push @_boxes[jointA].position
      geometry.vertices.push @_boxes[jointB].position
      line = new THREE.Line geometry, material
      line.visisble = false
      line

  addToScene: (scene) ->
    scene.add @_head
    for joint, box of @_boxes
      scene.add box
    for line in @_lines
      scene.add line

  onSkeleton: (skeleton) ->
    if skeleton?
      @_updateSkeleton skeleton
      @_updateHeadIfLoaded skeleton
    else
      @_setVisibility false

  _updateSkeleton: (skeleton) ->
    for joint, position of skeleton
      @_updateObject @_boxes[joint], position
    for line in @_lines
      line.visible = true
      line.geometry.verticesNeedUpdate = true

  _updateHeadIfLoaded: (skeleton) ->
    @_updateObject @_head, skeleton.head if @_head?

  _updateObject: (object, position) ->
    object.position.x = @_position.x + position.x * @_scale
    object.position.y = @_position.y + position.y * @_scale
    object.position.z = @_position.z + position.z * -@_scale
    if object.scaleMultiplier?
      object.scale.set(
        object.scaleMultiplier,
        object.scaleMultiplier,
        object.scaleMultiplier
      )
    object.traverse (descendant) ->
      descendant.visible = true

  _setVisibility: (visible) ->
    @_head?.traverse (object) ->
      object.visible = visible
    for join, box of @_boxes
      box.visible = visible
    for line in @_lines
      line.visible = visible

  onNoteStart: (note) ->
    @onNoteMove note

  onNoteMove: (note) ->
    @_setBoxState true, note

  onNoteStop: (note) ->
    @_setBoxState false, note

  _setBoxState: (isOn, note) ->
    material = if isOn
      @_boxOnMaterial
    else
      @_boxOffMaterial
    for joint in [note.jointA, note.jointB]
      @_boxes[joint].material = material


