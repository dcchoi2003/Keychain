# WS Chat Server

import asyncio

from websockets.server import serve

async def chat(websocket):
    while True:
        message = await websocket.recv()
        print(f"Other person says >> {message}")
        print()

        response = input("Send a message >> ")
        await websocket.send(response)
        print()

async def main():
    async with serve(chat, "localhost", 8765):
        await asyncio.get_running_loop().create_future()

if __name__ == "__main__":
    asyncio.run(main())
