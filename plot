#! /usr/bin/env python3
import argparse
import sys
import matplotlib.pyplot as plt
import re
from os import path
from itertools import cycle

parser = argparse.ArgumentParser()
parser.add_argument('infile', nargs='?')
parser.add_argument('--output')
parser.add_argument('-t', '--title')
parser.add_argument('-x', '--xlabel', default='')
parser.add_argument('-y', '--ylabel', default='')
parser.add_argument('--ybottom', help='Minimum value for the y axis', type=float)
parser.add_argument('--ytop', help='Maximum value for the y axis', type=float)
parser.add_argument('-l', '--labels', nargs='*')
parser.add_argument('-c', '--connect', default=False, action='store_true')
parser.add_argument('--no-grid', default=False, action='store_true')
parser.add_argument('--no-band', default=False, action='store_true')
parser.add_argument('-d', '--delimiter', default=' ')
parser.add_argument('-a', '--average', nargs='+', type=int, default=[1])
parser.add_argument('--relative-bounds', nargs='*', default=[], help='Relative values to use for lower bounds')
args = parser.parse_args()

args.no_grid

input = sys.stdin if args.infile is None else args.infile
data = [ line.split(args.delimiter) for line in input ]

def add_line_numbers(lines, repeat_amounts):
    line_no = 0
    i = 0
    repeat_amounts = cycle(repeat_amounts)
    repeat = next(repeat_amounts)
    for line in lines:
        if line[0] == '\n':
            line_no = 0
            i = 0
            repeat = next(repeat_amounts)
            continue

        line.insert(0, line_no)
        i += 1
        if i == repeat:
            line_no += 1
            i = 0

    return lines

if len(data[0]) == 1:
    data = add_line_numbers(data, args.average)

# Parse the inputs
xs = [[]]
ys = [[]]
for chunks in data:
    if chunks[0] == '\n':
        xs.append([])
        ys.append([])
    else:
        try:
            x = float(chunks[0])
            y = float(chunks[1])
        except ValueError:
            pass

        xs[-1].append(x)
        ys[-1].append(y)

xs = [ x for x in xs if len(x) > 0 ]
ys = [ y for y in ys if len(y) > 0 ]

if args.infile:
    args.title = args.title or '.'.join(args.infile.split('.')[0:-1])
else:
    args.title = args.title or path.basename(sys.argv[0])

args.output = args.output or re.sub(r'[^a-zA-Z0-9 ]', '', args.title).replace(' ', '-') + '.png'
if args.connect:
    avg = lambda l: sum(l)/len(l)
    bounds = []
    amounts_to_avg = cycle(args.average)
    for (i, x) in enumerate(xs):
        amt_to_avg = next(amounts_to_avg)
        print('about to average', amt_to_avg, 'points for line #', i)
        avg_xs = []
        avg_ys = []
        bounds.append([])
        for j in range(0, len(xs[i]), amt_to_avg):
            yvals = ys[i][j:j+amt_to_avg]
            y = avg(yvals)
            avg_xs.append(xs[i][j])
            avg_ys.append(y)
            bounds[-1].append((min(yvals), max(yvals)))

        xs[i] = avg_xs
        ys[i] = avg_ys

    amounts_to_avg = cycle(args.average)
    for (i, x) in enumerate(xs):
        print('line #', i, 'has', len(x), 'points')
        y = ys[i]
        label = args.labels[i] if args.labels else f'Dataset #{i}'
        plt.plot(x, y, label=label)

        if len(args.relative_bounds) > i:
            rel_bounds = ( float(v) for v in args.relative_bounds[i].split(',') )
            lower_bound = -next(rel_bounds)

            try:
                upper_bound = next(rel_bounds)
            except StopIteration:
                upper_bound = 0

            bounds[i] = [ (val+lower_bound, val+upper_bound) for val in y ]
            has_bounds = True
        else:
            has_bounds = not args.no_band and next(amounts_to_avg) > 0

        if has_bounds:
            plt.fill_between(x, *zip(*bounds[i]), alpha=0.35)

else:
    for (i, x) in enumerate(xs):
        y = ys[i]
        label = args.labels[i] if args.labels else f'Dataset #{i}'
        plt.scatter(x, y, label=label)

if args.labels is not None:
    plt.legend()

if args.ybottom is not None:
    plt.ylim(bottom=args.ybottom)

if args.ytop is not None:
    plt.ylim(top=args.ytop)

plt.title(args.title)
plt.xlabel(args.xlabel)
plt.ylabel(args.ylabel)
plt.grid(not args.no_grid)
plt.savefig(args.output)
print('generated ' + args.output)
