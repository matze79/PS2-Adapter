#!/bin/sh
avrdude -c usbasp -p t2313 -U lfuse:w:0xfd:m -U hfuse:w:0xdf:m -U efuse:w:0xfe:m
avrdude -c usbasp -p t2313 -U flash:w:ps2adapter-noboot-tiny2313.hex
