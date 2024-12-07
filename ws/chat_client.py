# WS Chat Client

import asyncio

from websockets.client import connect

URI = input("URI >> ")
print()

async def chat():
    async with connect(URI) as websocket:
        print(f"Connected to {URI}")
        print()
        while True:
            message = input("   Send a message >> ")
            await websocket.send(message)
            print()

            response = await websocket.recv()
            print(f"Other person says >> {response}")
            print()

if __name__ == "__main__":
    asyncio.run(chat())
