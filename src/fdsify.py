#!/usr/bin/env python3

from argparse import ArgumentParser
from functools import partial
from subprocess import check_call
import sys
import tkinter as tk

class XDoTool:
    def __init__(self, path):
        self.path = path

    def _call(self, command, wid, *args):
        check_call((self.path, command, '--window', str(wid)) + args)

    def key(self, wid, key):
        self._call('key', wid, key)

    def type(self, wid, chars):
        self._call('type', wid, chars)


class Spotify:
    def __init__(self, xdotool, wid):
        self.xdotool = xdotool
        self.wid = wid

    def __str__(self):
        return 'Spotify(%d)' % (self.wid,)

    def toggle(self):
        self.xdotool.key(self.wid, 'space')

    def change_volume(self, delta):
        if delta == 0:
            return
        key = 'Ctrl+%s' % ('Up' if delta > 0 else 'Down',)
        for i in range(abs(delta)):
            self.xdotool.key(self.wid, key)

    def mute(self):
        self.change_volume(-10)

    def volumn_down(self, delta):
        self.change_volume(-delta)

    def volumn_up(self, delta):
        self.change_volume(delta)



class Decks:
    def __init__(self, left, right):
        self.left = left
        self.right = right

    def __str__(self):
        return 'Decks(%s, %s)' % (self.left, self.right)

    def crossfade(self, delta):
        d = 1 if delta > 0 else -1
        for i in range(abs(delta)):
            self.left.change_volume(-d)
            self.right.change_volume(d)

    def mute(self):
        self.left.mute()
        self.right.mute()


class FdsifyGui:
    def __init__(self, decks):
        self.root = tk.Tk()
        self.decks = decks

        self.root.title('FDSify')

        bindings = [
            # Crossfade
            ['<Left>', decks.crossfade, -1],
            ['<Right>', decks.crossfade,  1],

            # Left deck volume
            ['<Home>', decks.left.volumn_up, 1],
            ['<End>', decks.left.volumn_down, 1],

            # Right deck volume
            ['<Prior>', decks.right.volumn_up, 1],
            ['<Next>', decks.right.volumn_down, 1],

            # Left/right mute
            ['n', decks.left.mute],
            ['m', decks.right.mute],

            # Left/right autofade
            ['a', self._autofade_left],
            ['s', self._autofade_right],
        ]

        for binding in bindings:
            event = binding[0]
            method = binding[1]
            args = binding[2:]
            callback = partial(self._callback, method, *args)
            self.root.bind_all(event, callback)

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
    add('-r', '--reset', action='store_true', default=False)
    add('-x', '--xdotool', default='/usr/bin/xdotool',
        help='The absolute path of the xdotool executable.')
    add('left', type=int,
        help='The WID of the main window of the Spotify instance to be the '
             'left deck.')
    add('right', type=int,
        help='The WID of the main window of the Spotify instance to be the '
             'right deck.')
    return ap


def main(argv=None):
    if argv is None:
        argv = sys.argv
    args = build_argument_parser().parse_args(args=argv[1:])

    xdotool = XDoTool(args.xdotool)
    left = Spotify(xdotool, args.left)
    right = Spotify(xdotool, args.right)
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

