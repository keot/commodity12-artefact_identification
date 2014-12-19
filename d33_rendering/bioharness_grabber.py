#!/usr/bin/env python

import serial
import platform

import zephyr
from zephyr.testing import simulation_workflow

input_buffer = list()

def callback(value_name, value):
	global input_buffer

	if value_name == "ecg":
		input_buffer.append(int(value) )

	if len(input_buffer) >= 50:
		print ','.join(map(str, input_buffer) )
		del input_buffer[:]


def main():
	zephyr.configure_root_logger()
	
	serial_port_dict = {"Darwin": "/dev/cu.BHBHT001931-iSerialPort1",
						"Windows": 23,
						"Linux": "/dev/rfcomm0"}
	
	serial_port = serial_port_dict[platform.system()]
	ser = serial.Serial(serial_port)
	
	simulation_workflow([callback], ser)


if __name__ == "__main__":
	main()
