# WS Chat Client

import asyncio
import serial
import sys

# set according to your system!
SERIAL_PORTNAME = "/dev/ttyUSB1"
BAUD = 115200

from websockets.client import connect

URI = input("URI >> ")
print()

def comm_fpga(action, message):

    return message

    ser = serial.Serial(SERIAL_PORTNAME,BAUD)

    # alert FPGA that computer is sending data
    ser.write(0xFF)

    # classify as encode or decode
    if action == "encode":
        ser.write(0xFF)
    else:
        ser.write(0x00)

    # send data to FPGA
    for character in message:
        ser.write( character.to_bytes(1,'little') )

    # receive date from FPGA

    result = ser.read_all()
    return result


async def chat():
    async with connect(URI) as websocket:
        print(f"Connected to {URI}")
        print()
        while True:
            message = input("   Send a message >> ")
            message = comm_fpga("encode", message)

            await websocket.send(message)
            print()

            response = await websocket.recv()
            response = comm_fpga("decode", response)
            print(f"Other person says >> {response}")
            print()

if __name__ == "__main__":
    asyncio.run(chat())
