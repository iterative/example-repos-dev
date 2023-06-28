import io
import os
import random
import sys
import xml.etree.ElementTree

# This file is not part of the project but is used to generate a slice of
# data from the full SO dump https://archive.org/details/stackexchange


if len(sys.argv) != 3:
    sys.stderr.write("Arguments error. Usage:\n")
    sys.stderr.write("\tpython analyze.py data-file output-file\n")
    sys.exit(1)


target = 40000
split = 0.3


def lines_matched_test(fd, test):
    for line in fd:
        try:
            attr = xml.etree.ElementTree.fromstring(line).attrib
            if test(attr.get("Tags", "")):
                yield line
        except Exception as ex:
            sys.stderr.write(f"Skipping the broken line: {ex}\n")


def process_posts(fd_in, fd_not, fd_out):
    count = 0
    in_lines = lines_matched_test(fd_in, lambda x: "<r>" in x)
    not_lines = lines_matched_test(fd_not, lambda x: "<r>" not in x)
    while count < target:
        line = next(not_lines) if random.random() > split else next(in_lines)
        fd_out.write(line)
        count += 1


with io.open(sys.argv[1], encoding="utf8") as fd_in:
    with io.open(sys.argv[1], encoding="utf8") as fd_not:
        with io.open(sys.argv[2], "w", encoding="utf8") as fd_out:
            process_posts(fd_in, fd_not, fd_out)
