#!/usr/bin/env python3

from argparse import ArgumentParser
from subprocess import check_call
import os
import sys

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

    def _call(self, command, wid, *args):
        check_call((self.path, command, '--window', str(wid)) + args)

    def key(self, wid, key):
        self._call('key', wid, key)

    def type(self, wid, chars):
        self._call('type', wid, chars)


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
        key = 'Up' if delta > 0 else 'Down'
        for i in range(abs(delta)):
            self.xdotool.key(self.wid, 'Ctrl+%s' % (key,))

    def mute(self):
        self.change_volume(-10)


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


def build_argument_parser():
    ap = ArgumentParser()
    add = ap.add_argument
    add('-d', '--dbussend', default='/usr/bin/dbus-send')
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

    decks.left.toggle()


    return 0


if __name__ == '__main__':
    exit(main())

