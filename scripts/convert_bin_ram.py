#!/usr/bin/env python3

import sys

application_path = sys.argv[1]
output_path = sys.argv[2]

with open(application_path, "rb") as f:
	app_image = f.read()
	
with open(output_path, "w") as out:
	out.write("@000000\n")
	bytecnt = 0
	wordcnt = 0
	linestr = ""
	wordstr = ""
	for b in app_image:
		wordstr += format(b, '02x')
		bytecnt += 1
		if bytecnt >= 4:
			linestr = wordstr + linestr
			bytecnt = 0
			wordstr = ""
			wordcnt += 1
			if wordcnt >= 4:
				out.write(linestr+"\n")
				linecnt = 0
				linestr = ""
				wordcnt = 0