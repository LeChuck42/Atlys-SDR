#!/usr/bin/env python3

import sys

if len(sys.argv) > 2:
	application_path = sys.argv[1]
	startaddr = sys.argv[2]
	output_path = sys.argv[3]
else:
	application_path = "../firmware/sdr_test/Debug/sdr_test.bin"
	startaddr = "800000"
	output_path = application_path + ".asc"

with open(application_path, "rb") as f:
	app_image = f.read()
	
with open(output_path, "w") as out:
	out.write("@" + startaddr + "\n")
	for b in app_image:
		out.write(format(b, '02x') + '\n')
