# ==============================================================================
# = Methods                                                                    =
# ==============================================================================

Meteor.methods
  joinRoom: (roomId, isMaster) ->
    check roomId, String
    check isMaster, Boolean
    RoomControls.joinRoom roomId, @connection.id, isMaster
    undefined

  leaveRooms: ->
    RoomControls.leaveRooms @connection.id
    undefined

  showMessage: (roomId) ->
    check roomId, String
    RoomControls.showMessage roomId
    undefined

  hideMessage: (roomId) ->
    check roomId, String
    RoomControls.hideMessage roomId
    undefined

  enableSinglePlayer: (roomId) ->
    check roomId, String
    RoomControls.enableSinglePlayer roomId
    undefined

  enableAllPlayers: (roomId) ->
    check roomId, String
    RoomControls.enableAllPlayers roomId
    undefined

  disableAllPlayers: (roomId) ->
    check roomId, String
    RoomControls.disableAllPlayers roomId
    undefined


# ==============================================================================
# = Queue                                                                      =
# ==============================================================================

queue = new PowerQueue
  isPaused: true


Meteor.startup ->
  queue.add (done) ->
    Players.remove {}
    Rooms.remove {}
    done()
  queue.run()


class @RoomControls
  add = (func) ->
    queue.add (done) ->
      func()
      done()

  @joinRoom: (roomId, playerId, isMaster) ->
    add -> joinRoom roomId, playerId, isMaster

  @leaveRooms: (playerId) ->
    add -> leaveRooms playerId

  @showMessage: (roomId) ->
    add -> showMessage roomId

  @hideMessage: (roomId) ->
    add -> hideMessage roomId

  @enableSinglePlayer: (roomId) ->
    add -> enableSinglePlayer roomId

  @enableAllPlayers: (roomId) ->
    add -> enableAllPlayers roomId

  @disableAllPlayers: (roomId) ->
    add -> disableAllPlayers roomId


# ==============================================================================
# = Room controls                                                              =
# ==============================================================================

# Player documents
#
#   allEnabled {Boolean} True if everyone in the room is enabled.
#
#   isEnabled {Boolean} If true, the player can use their controller.
#
#   isMaster {Boolean} If true, the player can always use their
#                      controller.
#
#   name {String} The player's name.
#
#
#   roomId {String} The ID of the room they are currently in.
#
#   singleAt  {Number} The Unix time that this person was last
#                      singularly enabled. If not present, this player
#                      has never been singularly enabled.
#
#
# Room documents
#
#   allEnabled {Boolean} If true, everyone in the room can use their
#                        controller. If false or does not exist, only
#                        masters or singularly enabled players can
#                        use their controllers.
#
#   enabledPlayerId {String} The ID of the player that has been
#                            singularly enabled. If this field does not
#                            exists, no player is singularly enabled.
#
#   message {String} The message to show at the top of viewer of the
#                    room. If this field does not exists, no message
#                    is to be shown.
#
#   roomId {String} The name of the room.


joinRoom = (roomId, playerId, isMaster) ->
  # Enable the player if they are a master or that is the default
  # state.
  room = Rooms.findOne
    roomId: roomId
  ,
    fields:
      allEnabled: true
  allEnabled = room?.allEnabled ? false

  isEnabled = if isMaster or ServerSettings.players.enableOnJoin
    true
  else
    # The joining player should be enabled if all players in the room
    # are enabled.
    allEnabled

  Players.upsert
    playerId: playerId
  ,
    $set:
      allEnabled: allEnabled
      isEnabled: isEnabled
      isMaster: isMaster
      name: generateName()
      roomId: roomId
    $unset:
      singledAt: ''

  # Ensure that the room exists so that it shows up in the lobby.
  Rooms.upsert
    roomId: roomId
  ,
    $set:
      roomId: roomId


leaveRooms = (playerId) ->
  player = Players.findOne
    playerId: playerId

  return unless player?

  # If the player is the singularly enabled player in a room, select
  # another player.
  Rooms.find(enabledPlayerId: playerId).forEach (room) ->
    enableSinglePlayer room.roomId

  # Remove the player.
  Players.remove
    playerId: playerId

  # If the room is now empty, remove it.
  if Players.find(roomId: player.roomId).count() == 0
    Rooms.remove
      roomId: player.roomId


showMessage = (roomId) ->
  Rooms.upsert
    roomId: roomId
  ,
    $set:
      message: ServerSettings.viewer.message


hideMessage = (roomId) ->
  Rooms.update
    roomId: roomId
  ,
    $unset:
      message: ''


enableSinglePlayer = (roomId) ->
  # Find a player that has never been singularly enabled or the
  # player that was singularly enabled longest ago.
  player = Players.findOne
    isMaster: false
    roomId: roomId
  ,
    sort: [
      ['singledAt', 'asc']
    ]

  if player?
    # Disable all players in the room.
    Players.update
      isEnabled: true
      roomId: roomId
    ,
      $set:
        isEnabled: false
    ,
      multi: true

    # Enable the player.
    Players.update
      playerId: player.playerId
    ,
      $set:
        isEnabled: true
        singledAt: Date.now()

    # Update the room.
    Rooms.upsert
      roomId: roomId
    ,
      $set:
        allEnabled: false
        enabledPlayerId: player.playerId
        message: player.name

  else
    # Show a message indicating the were no players to enable.
    Rooms.upsert
      roomId: roomId
    ,
      $set:
        allEnabled: false
        message: 'No players :('
      $unset:
        enabledPlayerId: ''

  Players.update
    allEnabled: true
    roomId: roomId
  ,
    $set:
      allEnabled: false
  ,
    multi: true


enableAllPlayers = (roomId) ->
  Players.update
    roomId: roomId
  ,
    $set:
      allEnabled: true
      isEnabled: true
  ,
    multi: true

  Rooms.upsert
    roomId: roomId
  ,
    $set:
      allEnabled: true
      message: 'Everyone'
    $unset:
      enabledPlayerId: ''


disableAllPlayers = (roomId) ->
  Players.update
    isEnabled: true
    isMaster: false
    roomId: roomId
  ,
    $set:
      isEnabled: false
  ,
    multi: true

  Players.update
    allEnabled: true
    roomId: roomId
  ,
    $set:
      allEnabled: false
  ,
    multi: true

  Rooms.upsert
    roomId: roomId
  ,
    $set:
      allEnabled: false
    $unset:
      enabledPlayerId: ''
      message: ''

