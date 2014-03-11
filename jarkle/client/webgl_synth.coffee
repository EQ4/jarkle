NOTES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']

NOTE_ON_MIDI_NUMBER = 144

ONLY_MASTERS = 'only masters'

class @WebGlSynth
  constructor: (@schema, @skeletonConfig, @vis, noteMap, @pubSub) ->
    Session.set 'infoMessage', null
    window.AudioContext = window.AudioContext or window.webkitAudioContext
    @synth = new Synth(new AudioContext(), noteMap, pubSub, @schema,
                       skeletonConfig)
    @playerManager = new PlayerManager(@schema)
    @currentPlayerId = ONLY_MASTERS

  handleNoteMessage: (noteMessage) =>
    userId = noteMessage.userId
    player = @playerManager.getPlayerFromUserId(userId, noteMessage.isMaster)
    if not @currentPlayerId? \
        or @currentPlayerId._id == userId \
        or noteMessage.isMaster
      @synth.handleMessage noteMessage, player.id
      @vis.handleMessage noteMessage, player.id

  _midiNoteNumberToNoteLetter: (midiNoteNumber) ->
    noteIndex = midiNoteNumber % NOTES.length
    return NOTES[noteIndex]

  stopAll: ->
    @synth.stopAll()
    @vis.stopAll()

  pause: ->
    @vis.paused = not @vis.paused

  handleDrumMidiMessage: (noteInfo) =>
    if noteInfo.note == RIDE_CYMBAL_1 and noteInfo.vel >= 120
      @nextPlayer()

  nextPlayer: ->
    @stopAll()
    nextPlayer = @playerManager.getNextActivePlayerId()
    if nextPlayer?
      ua = nextPlayer.profile.userAgent
      if ua.match(/Android/i)
        ua = 'Android'
      if ua.match(/Blackberry/i)
        ua = 'Blackberry'
      if ua.match(/iPhone/i)
        ua = 'iPhone'
      if ua.match(/iPad/i)
        ua = 'iPad'
      if ua.match(/iPod/i)
        ua = 'iPod'
      if ua.match(/IEMobile/i)
        ua = 'Windows phone'
      Session.set 'infoMessage', """
        #{nextPlayer.profile.name} on #{ua}
      """
      @pubSub.trigger CURRENT_PLAYER, nextPlayer
    @currentPlayerId = nextPlayer

  handleMidiMessage: (noteInfo) =>
    unless noteInfo.func != NOTE_ON_MIDI_NUMBER
      return
    noteLetter = @_midiNoteNumberToNoteLetter(noteInfo.note)
    switch noteLetter
      when 'B'
        Session.set 'infoMessage', 'Go to http://fds'
      when 'C'
        # Next player
        @nextPlayer()
      when 'D'
        # All players
        @currentPlayerId = null
        Session.set 'infoMessage', 'EVERYBODY'
        @pubSub.trigger CURRENT_PLAYER,
          _id: 'all'
      when 'E'
        # No players (apart from masters)
        Session.set 'infoMessage', null
        @currentPlayerId = ONLY_MASTERS
        @pubSub.trigger CURRENT_PLAYER,
          _id: @currentPlayerId
      when 'F'
        # Clear sounds
        @stopAll()

