import asyncio
import logging

# from starlette.websockets import WebSocket, WebSocketDisconnect
from fastapi import WebSocket
from icecream import ic
from starlette.websockets import WebSocketState
from websockets import ConnectionClosedError, WebSocketException

logger = logging.getLogger("websocket manager")


class MyWebSocket:
    def __init__(
            self, websocket: WebSocket, username: str
    ):
        self.websocket: WebSocket = websocket
        self.connected: bool = False
        self.username: str = username

    def get_ip(self):
        _host = f"{self.websocket.client.host}:{self.websocket.client.port}"
        return _host


class ConnectionManager:
    def __init__(self):
        self.connections: list[MyWebSocket] = []

    async def connect(self, myws: MyWebSocket):
        await myws.websocket.accept()
        self.connections.append(myws)
        myws.connected = True

    async def disconnect(self, myws: MyWebSocket):
        logger.info(f"Disconnecting user {myws.username}")
        self.connections.remove(myws)
        myws.connected = False

        if myws.websocket.client_state != WebSocketState.DISCONNECTED:
            await myws.websocket.close()

    async def send_message(self, myws: MyWebSocket, message: str):
        if myws.websocket.client_state.CONNECTED != WebSocketState.CONNECTED:
            return

        try:
            await myws.websocket.send_text(message)
        except (
                WebSocketException,
                RuntimeError,
                ConnectionClosedError
        ) as e:
            await self.disconnect(myws)
            logger.warning(f"Disconnect error handled! {e}")

    def broadcast(self, payload: str, sender: str):
        """
        Broadcast to all connected devices
        :param sender: the username of the sender
        :param payload: A json dump of the content
        :return:
        """

        ic(f"Broadcasting message {payload}")

        tasks = [
            self.send_message(
                myws, payload
            ) for myws in self.connections if myws.username != sender
        ]
        asyncio.gather(*tasks)

    def __len__(self):
        return len(self.connections)

    async def terminate_connections(self):
        tasks = []
        for myws in self.connections:
            myws.connected = False
            tasks.append(myws.websocket.close())

        await asyncio.gather(*tasks)

        self.connections = []


manager: ConnectionManager = ConnectionManager()
