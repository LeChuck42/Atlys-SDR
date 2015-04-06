#!/usr/bin/env python3

import sys

if len(sys.argv) > 2:
	application_path = sys.argv[1]
	output_path = sys.argv[2]
else:
	application_path = "../firmware/sdr_test/Debug/sdr_test.bin"
	output_path = application_path + ".asc"

with open(application_path, "rb") as f:
	app_image = f.read()
	
with open(output_path, "w") as out:
	out.write("@800000\n")
	for b in app_image:
		out.write(format(b, '02x') + '\n')