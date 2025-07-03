import copy
import json
import plistlib
import re
import typing as t
from argparse import ArgumentParser


class XCColorTheme:
    def __init__(
        self, path: str | None = None, data: t.Dict[str, t.Any] | None = None
    ):
        self.path = path
        self.data = data
        if path and not self.data:
            with open(path, 'rb') as f:
                self.data = plistlib.load(f)

    def save(self, to: str | None = None):
        with open(to or self.path, 'wb') as f:
            plistlib.dump(self.transform_data(self.data, from_hex=True), f)

    @staticmethod
    def from_json(path: str) -> 'XCColorTheme':
        with open(path, 'rb') as f:
            data = json.load(f)
        return XCColorTheme(data=data)

    def to_json(self, path: str):
        with open(path, 'w') as f:
            json.dump(self.transform_data(self.data, to_hex=True), f, indent=2)

    def transform_data(self, data, from_hex=None, to_hex=None):
        def perform(ds: dict):
            for k, v in ds.items():
                if isinstance(v, str):
                    if to_hex and re.match(r'^([\d.]+\s+){2,3}[\d.]+$', v):
                        ds[k] = self.rgba_to_hex(v)
                    if from_hex and re.match(r'^#[a-zA-Z\d]{3,}$', v):
                        ds[k] = self.hex_to_rgba(v)
                elif isinstance(v, dict):
                    perform(v)

        cpy = copy.deepcopy(data)
        perform(cpy)
        return cpy

    def hex_to_rgba(self, hex: str):
        if hex.startswith('#'):
            hex = hex[1:]
        if len(hex) <= 6:
            hex += 'ff'
        return ' '.join(str(int(hex[i : i + 2], 16) / 255) for i in range(0, len(hex), 2))

    def rgba_to_hex(self, rgba: str):
        cmps = [int(float(x) * 255) for x in rgba.split(' ')]
        hex = ''.join(f'{x:02x}' for x in cmps)
        if len(hex) == 8 and hex.endswith('ff'):
            hex = hex[:6]
        return f'#{hex}'


def main():
    parser = ArgumentParser()
    parser.add_argument('-i', '--in', dest='infile')
    parser.add_argument('-o', '--out', dest='outfile')
    args = parser.parse_args()
    if args.infile.endswith('.json'):
        XCColorTheme.from_json(args.infile).save(to=args.outfile)
    else:
        XCColorTheme(path=args.infile).to_json(args.outfile)


if __name__ == '__main__':
    main()
