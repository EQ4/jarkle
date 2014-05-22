# -*- coding: utf-8 -*-

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from argparse import ArgumentParser

import ddp

import midimule


def get_listener(args):
    parser = ArgumentParser()
    parser.add_argument('server_url')
    parser.add_argument('room_id')
    args = parser.parse_args(args=args)
    return RoomControls(args.server_url, args.room_id)


class RoomControls(midimule.MidiPortListener):
    def __init__(self, server_url, roomId):
        self._conn = ddp.DdpConnection(ddp.ServerUrl(server_url))
        self._next_id = 0
        self._roomId = roomId

    def on_before_open(self):
        self._conn.connect()

    def on_message(self, message, data=None):
        event, delta = message

        # Stop if this is not a 3-byte event
        if len(event) != 3:
            return

        status, data1, data2 = event

        # Stop if this is not a channel 1 note on event.
        if status != 144 or data2 != 100:
            return

        handler = {
            41: self._show_message,
            43: self._hide_message,
            45: self._enable_single_player,
            47: self._enable_all_players,
            48: self._disable_all_players,
        }.get(data1)

        # Stop if an operation is not assign to the note.
        if handler is None:
            return

        handler()

    def on_after_close(self):
        self._conn.disconnect()

    def _hide_message(self):
        self._call_methods('hideMessage')

    def _show_message(self):
        self._call_methods('showMessage')

    def _enable_single_player(self):
        self._call_methods('enableSinglePlayer')

    def _enable_all_players(self):
        self._call_methods('enableAllPlayers')

    def _disable_all_players(self):
        self._call_methods('disableAllPlayers')

    def _call_methods(self, name, *params):
        msg = ddp.MethodMessage(str(self._next_id), name, [self._roomId])
        self._next_id += 1
        self._conn.send(msg)

