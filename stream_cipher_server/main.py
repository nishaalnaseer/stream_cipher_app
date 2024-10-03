from fastapi import FastAPI
from fastapi.websockets import WebSocket
from manager import MyWebSocket, manager
from icecream import ic
from stanChan import *


app = FastAPI()


@app.websocket("/chat")
async def get_wait_list(
        websocket: WebSocket, username: str
):
    myws = MyWebSocket(websocket, username)
    await manager.connect(myws)
    ic(f"Connected {username}")
    # connected_text =
    message = f"User {username} has connected"
    encrypted = encrypt_or_decrypt(message)
    stanChanApplied = applyStanChan(encrypted)
    manager.broadcast(
        stanChanApplied,
        username
    )

    while myws.connected:
        try:
            stanChanEncoded = await websocket.receive_text()
            # cipher = removeStanChan(stanChanEncoded)

            # message = myws.encrypt_or_decrypt(cipher)
            manager.broadcast(
                stanChanEncoded,
                username
            )
            ic(
                f"Message received: {stanChanEncoded}\n from {username}"
            )
        except Exception as e:
            ic(str(e))
            break


if __name__ == '__main__':
    import uvicorn
    uvicorn.run("main:app")
