#!/usr/bin/env python3

from argparse import ArgumentParser
from subprocess import check_call
import sys

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
        key = 'Up' if delta > 0 else 'Down'
        for i in range(abs(delta)):
            self.xdotool.key(self.wid, 'Ctrl+%s' % (key,))

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


def build_argument_parser():
    ap = ArgumentParser()
    add = ap.add_argument
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

    decks.crossfade(-10)

    return 0


if __name__ == '__main__':
    exit(main())

