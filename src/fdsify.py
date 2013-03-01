#!/usr/bin/env python

# Copyright 2013 Foxdog Studios Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from argparse import ArgumentParser
from functools import partial
from subprocess import check_call
from threading import Thread
import os
import sys
import tkinter as tk
from tkinter import font

class DbusSend:
    def __init__(self, path, user):
        self.path = path
        self.user = user

    def call(self, command):
        with open(os.devnull) as stdout:
            check_call((
                    '/usr/bin/sudo', '-u', self.user,
                    self.path,
                    '--print-reply',
                    '--dest=org.mpris.MediaPlayer2.spotify',
                    '/org/mpris/MediaPlayer2',
                    'org.mpris.MediaPlayer2.Player.%s' % (command,)
                ),
                stdout=stdout,
            )


class XDoTool:
    def __init__(self, path):
        self.path = path

    def call(self, wid, commands):
        wid = str(wid)
        args = [self.path]
        for cmd in commands:
            args.extend([cmd[0], '--window',  wid] + cmd[1:])
        check_call(args)

    def key(self, wid, *keys):
        cmd = [['key', key] for key in keys]
        self.call(wid, cmd)

    def type(self, wid, chars):
        self.call(wid, [['type', chars]])


class Spotify:
    def __init__(self, xdotool, dbus_send, wid):
        self.dbus_send = dbus_send
        self.xdotool = xdotool
        self.wid = wid

    def __str__(self):
        return 'Spotify(%s, %d)' % (self.dbus_send.user, self.wid,)

    def pause(self):
        self.dbus_send.call('Pause')

    def toggle(self):
        self.dbus_send.call('PlayPause')

    def change_volume(self, delta):
        if delta == 0:
            return
        key = 'Ctrl+%s' % ('Up' if delta > 0 else 'Down',)
        keys = [key] * abs(delta)
        self.xdotool.key(self.wid, *keys)

    def mute(self):
        self.change_volume(-10)

    def volume_down(self, delta):
        self.change_volume(-delta)

    def volume_up(self, delta):
        self.change_volume(delta)



class Decks:
    def __init__(self, left, right):
        self.left = left
        self.right = right

    def __str__(self):
        return 'Decks(%s, %s)' % (self.left, self.right)

    def crossfade(self, delta):
        d = 1 if delta > 0 else -1
        t1 = Thread(target=self.left.change_volume, args=(-delta,))
        t2 = Thread(target=self.right.change_volume, args=(delta,))
        t1.start()
        t2.start()
        t1.join()
        t2.join()

    def _quickfade(self, from_deck, to_deck):
        to_deck.pause()
        to_deck.volume_up(10)
        to_deck.toggle()
        from_deck.pause()
        from_deck.mute()
        from_deck.toggle()

    def quickfade_left(self):
        self._quickfade(self.right, self.left)

    def quickfade_right(self):
        self._quickfade(self.left, self.right)

    def mute(self):
        self.left.mute()
        self.right.mute()


INST ='''
          | Left |    Right |
-----------------------------
Crossfade |   <- |       -> |
Quickfade |    q |        w |
Vol. Up   | Home |   PageUp |
Vol. Down |  End | PageDown |
Mute      |    m |        , |
Auto. CF  |    a |        s |
Toggle    |    t |        y |
Pause     |    p |        [ |
'''[1:-1]

class FdsifyGui:
    def __init__(self, decks):
        self.root = tk.Tk()
        self.decks = decks


        bindings = [
            # Crossfade
            ['<Left>', decks.crossfade, -1],
            ['<Right>', decks.crossfade,  1],

            # Quickfase
            ['q', decks.quickfade_left],
            ['w', decks.quickfade_right],

            # Left deck volume
            ['<Home>', decks.left.volume_up, 1],
            ['<End>', decks.left.volume_down, 1],

            # Right deck volume
            ['<Prior>', decks.right.volume_up, 1],
            ['<Next>', decks.right.volume_down, 1],

            # Left/right mute
            ['m', decks.left.mute],
            [',', decks.right.mute],

            # Left/right autofade
            ['a', self._autofade_left],
            ['s', self._autofade_right],

            # Left/right toggle
            ['t', decks.left.toggle],
            ['y', decks.right.toggle],

            # Left/right pause
            ['p', decks.left.pause],
            ['[', decks.right.pause],
        ]

        for binding in bindings:
            event = binding[0]
            method = binding[1]
            args = binding[2:]
            callback = partial(self._callback, method, *args)
            self.root.bind_all(event, callback)

        self.root.configure(background='black')
        self.root.title('FDSify')
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)

        self.font = font.Font(root=self.root, family='mono')

        inst = tk.Label(master=self.root, background='black', font=self.font,
                        foreground='green', justify=tk.LEFT, text=INST)
        inst.grid(row=0, column=0, padx=5, pady=5, stick=tk.NSEW)

    def _callback(self, *args):
        # Ignore the event object at the last index.
        args[0](*args[1:-1])

    def _autofade_left(self):
        self.decks.crossfade(-10)

    def _autofade_right(self):
        self.decks.crossfade(10)

    def mainloop(self):
        self.root.mainloop()


def build_argument_parser():
    ap = ArgumentParser()
    add = ap.add_argument
    add('-d', '--dbussend', default='/usr/bin/dbus-send')
    add('-r', '--reset', action='store_true', default=False)
    add('-x', '--xdotool', default='/usr/bin/xdotool',
        help='The absolute path of the xdotool executable.')
    add('left_username', help='The owner of the left deck\'s unix username')
    add('left_wid', type=int,
        help='The WID of the main window of the Spotify instance to be the '
             'left deck.')
    add('right_username', help='The owner of the right deck\'s unix username')
    add('right_wid', type=int,
        help='The WID of the main window of the Spotify instance to be the '
             'right deck.')
    return ap


def main(argv=None):
    if argv is None:
        argv = sys.argv
    args = build_argument_parser().parse_args(args=argv[1:])

    xdotool = XDoTool(args.xdotool)
    left = Spotify(
            xdotool,
            DbusSend(args.dbussend, args.left_username),
            args.left_wid,
        )
    right = Spotify(
            xdotool,
            DbusSend(args.dbussend, args.right_username),
            args.right_wid,
        )
    decks = Decks(left, right)

    if args.reset:
        left.change_volume(10)
        right.change_volume(-10)
        left.toggle()

    tk.NoDefaultRoot()

    gui = FdsifyGui(decks)
    gui.mainloop()

    return 0


if __name__ == '__main__':
    exit(main())

