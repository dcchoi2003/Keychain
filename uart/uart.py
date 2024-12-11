# UART Communication with FPGA

import serial
from random import randint
import time

PORTNAME = "/dev/ttyUSB1"
BAUD = 115200

MSG_WIDTH = 8
KEY_WIDTH = 16

MAX_KEY_SIZE = pow(2, KEY_WIDTH)
MAX_MSG_SIZE = pow(2, MSG_WIDTH)

def send(ser, msg, key, mod):
    msg_str = msg.to_bytes(MSG_WIDTH, "little")
    key_str = key.to_bytes(KEY_WIDTH, "little")
    mod_str = mod.to_bytes(KEY_WIDTH, "little")

    ser.write(mod_str)
    ser.write(key_str)
    ser.write(msg_str)

def recv(ser):
    time.sleep(0.1)

    bytestr = ser.read(MSG_WIDTH + 2*KEY_WIDTH)

    return int.from_str(bytestr, "little")

if __name__ == "__main__":
    exponent = randint(1, MAX_KEY_SIZE)
    modulus = randint(1, MAX_MSG_SIZE)
    base = randint(1, modulus)

    ser = serial.Serial(PORTNAME, BAUD)

    print("Sending message ... ", end="", flush=True)
    send(ser, base, exponent, modulus)
    print("sent!")

    print("Awaiting response ... ", end="", flush=True)
    result = recv(ser)
    print("received!")
    print()

    print(f"{result} == {pow(base, exponent, modulus)}")
    assert result == pow(base, exponent, modulus)