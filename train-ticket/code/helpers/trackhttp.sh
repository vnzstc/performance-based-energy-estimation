#!/bin/bash

##########################################
# Generate Filter tool:
# https://www.wireshark.org/tools/string-cf.html
# 
# GET Filter:
# tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420
# POST Filter: 
# tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504f5354 && tcp[((tcp[12:1] & 0xf0) >> 2) + 4:1] = 0x20
# PUT Filter:
# tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x50555420
# DELETE Filter:
# tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x44454c45 && tcp[((tcp[12:1] & 0xf0) >> 2) + 4:2] = 0x5445 && tcp[((tcp[12:1] & 0xf0) >> 2) + 6:1] = 0x20
# HEAD Filter:
# tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x48454144 && tcp[((tcp[12:1] & 0xf0) >> 2) + 4:1] = 0x20
# HTTP RESPONSE Filter:
# tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x48545450 && tcp[((tcp[12:1] & 0xf0) >> 2) + 4:2] = 0x2f31 && tcp[((tcp[12:1] & 0xf0) >> 2) + 6:1] = 0x2e

tcpdump -i any -Avvvnn "tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420 
                 || (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504f5354 && tcp[((tcp[12:1] & 0xf0) >> 2) + 4:1] = 0x20) 
                 || (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x50555420) 
		 || (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x44454c45 && tcp[((tcp[12:1] & 0xf0) >> 2) + 4:2] = 0x5445 && tcp[((tcp[12:1] & 0xf0) >> 2) + 6:1] = 0x20) 
		 || (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x48454144 && tcp[((tcp[12:1] & 0xf0) >> 2) + 4:1] = 0x20) 
		 || (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x48545450 && tcp[((tcp[12:1] & 0xf0) >> 2) + 4:2] = 0x2f31 && tcp[((tcp[12:1] & 0xf0) >> 2) + 6:1] = 0x2e)" -w test.pcap
