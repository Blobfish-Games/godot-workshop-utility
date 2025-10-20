#!/usr/bin/python3

import sys
import re


def update_setting(lines, section, name, value):
    in_section = False
    section_marker = '[' + section + ']\n'
    property_marker = name + '='

    for i in range(len(lines)):
        line = lines[i]
        if not in_section:
            if line == section_marker:
                in_section = True
        else:
            if line.startswith('['):
                in_section = False
                break
            if line.startswith(property_marker):
                lines[i] = name + '=' + value + '\n'
                return True
    return False

def main():
    if len(sys.argv) < 5:
        print("Not enough arguments!")
        sys.exit(1)

    ini_file = sys.argv[1]
    section = sys.argv[2]
    name = sys.argv[3]
    value = sys.argv[4]

    with open(ini_file, 'rt') as fd:
        lines = fd.readlines()

    if not update_setting(lines, section, name, value):
        print("Didn't find property in file")
        sys.exit(1)

    with open(ini_file, 'wt') as fd:
        fd.write("".join(lines))

if __name__ == '__main__': main()
