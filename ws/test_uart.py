# WS Chat Client

import asyncio
import serial
import sys

# set according to your system!
SERIAL_PORTNAME = "/dev/cu.usbserial-88742923009F1"
BAUD = 115200

MODULUS = 1 # 
MODULUS_SIZE = 64 # in bits
PUBLIC_KEY = 1 #
NO_KEY = 1 #
KEY_SIZE = 16 # in bits


def comm_fpga(action, message):

    ser = serial.Serial(SERIAL_PORTNAME,BAUD)

    # data format: action (4 bits) + modulus (MODULUS_SIZE bits) + key (KEY_SIZE bits) + message (KEY_SIZE bits)

    # classify as encode or decode
    if action == "encode":
        ser.write(0xF)
        message = bytes(str.center(message, KEY_SIZE), 'utf-8')
        key = PUBLIC_KEY.to_bytes(KEY_SIZE//8, "little")
    else:
        ser.write(0x0)
        key = NO_KEY.to_bytes(KEY_SIZE//8, "little")

    modulus = MODULUS.to_bytes(MODULUS_SIZE//8, "little")

    message = modulus + key + message

    print("The message is: ", message)

    ser.write(message)

    # receive date from FPGA

    result = ser.read(size=KEY_SIZE) # this needs to be fixed, either extend output when sending from FPGA or have an end marker
    return result


message = input("Input message: ")

encoded = comm_fpga("encode", message)

print("Encoded: ", encoded)

decoded = comm_fpga("decode", encoded)

print("Decoded: ", decoded)