#!/bin/sh
avrdude -c usbasp -p t2313 -U flash:w:PS2Adapter.hex
avrdude -c usbasp -p t2313 -U lfuse:w:0xc0:m -U hfuse:w:0xdf:m -U efuse:w:0xff:m 
