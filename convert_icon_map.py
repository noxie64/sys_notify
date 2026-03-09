#!/usr/bin/env python3

from sys import argv
from argparse import ArgumentParser
from os.path import exists, isdir, isfile
from re import fullmatch
from bs4 import BeautifulSoup, Comment, Tag
from cairosvg import svg2png

def main():
    parser = ArgumentParser(
            prog=argv[0],
            description="Convert an html-file with comment-labled svgs to pngs"
        )
    parser.add_argument('-i', '--input', help="Input-html-file")
    parser.add_argument('-s', '--size', help='Set png-size, in XxY')
    parser.add_argument('-c', '--color', help='Color value, everthing that would be valid in html')
    parser.add_argument('-o', '--output', help='Output dir for pngs')

    args = parser.parse_args()


    if not args.input or not isfile(args.input):
        print('Invalid input-file :(')
        exit(1)

    if not args.output or not isdir(args.output):
        print('Invalid output-dir :(')
        exit(1)

    size_group = fullmatch(r"(\d*)x(\d*)", args.size if args.size else '')

    if not size_group:
        print('Invalid size :(')
        exit(1)

    x = int(size_group.groups()[0])
    y = int(size_group.groups()[1])

    if not args.color:
        print('Please provide a color')
        exit(1)

    with open(args.input, 'r') as input:
        html = BeautifulSoup('\n'.join(input.readlines()), 'html.parser')

    file_map = {}
    body = html.find_all('body')
    if len(body) != 1:
        print('Invalid html!')
        exit(0)
    body = body[0]

    for i, tag in enumerate(body.find_all('png')):
        name = i

        if 'name' in tag.attrs:
              name = tag.attrs['name']

        keep_color = 'keepcolor' in tag.attrs
        out_dir = args.output

        if 'customout' in tag.attrs:
            if exists(str(tag['customout'])):
                out_dir = tag['customout']
            else:
                print(f'Invalid custom output-dir for {name}, using default!')

        svg_tag = tag.find_next('svg')
        if svg_tag == None:
            print('Invalid svg-data!')
            continue

        qualified_path = f'{out_dir}/{name}.png'

        _, _, v_x, v_y = [int(i) for i in  str(svg_tag['viewbox']).split(' ')]

        svg_tag['width'] = f'{x}px'
        svg_tag['height'] = f'{y}px'

        if not keep_color:
            svg_tag['fill'] = args.color
            svg_tag['stroke'] = args.color

        svg_tag['viewBox'] = f'0 0 {v_x} {v_y}'
        svg_tag['preserveAspectRatio'] = 'xMidYMid meet'

        file_map.update({qualified_path: str(svg_tag)})


    for qualified_path, svg_content in file_map.items():
        svg2png(bytestring=svg_content, write_to=qualified_path, output_width=x, output_height=y)

        print(f'Exported {qualified_path}...')

    print('Finished!')
if __name__ == '__main__':
    main()
