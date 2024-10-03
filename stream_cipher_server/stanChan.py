from typing import List

from icecream import ic

INVISIBLE1 = "\u200C"
INVISIBLE2 = "\u200D"
DELIMITER = "\u2060"
BIGWORDS = "" \
    "In the forest, a wise owl guided lost travelers, illuminating their path " \
    "with moonlight and wisdom, leading them home safely."
STREAM_CIPHER_KEY = "HelloItsaMe!"


def encodeInvisibleCharacters(message: str) -> str:
    encoded = ""
    utfBytes = message.encode("utf-8")
    for byte in utfBytes:
        for index in range(8):
            bit = (byte >> (7 - index)) & 1
            if bit == 1:
                encoded += INVISIBLE1
            elif bit == 0:
                encoded += INVISIBLE2

        encoded += DELIMITER

    return encoded


def decodeInvisibleCharacters(encoded: str) -> str:
    _bytes: List[int] = []
    number: int = 0
    bitCount: int = 0

    for char in encoded:
        if char == INVISIBLE1:
            number = (number << 1) | 1
            bitCount += 1
        elif char == INVISIBLE2:
            number = (number << 1) | 0
            bitCount += 1
        else:
            _bytes.append(number)
            number = 0
            bitCount = 0

    index = 0
    for byte in _bytes:
        if byte == 0:
            index += 1
        else:
            break

    _bytes = _bytes[index:]

    return bytes(_bytes).decode("utf-8")


def applyStanChan(message: str) -> str:
    return BIGWORDS + encodeInvisibleCharacters(message)


def removeStanChan(encoded: str) -> str:
    invisibleCharacterStarting = 0
    for index in range(len(encoded)-1, -1, -1):
        char = encoded[index]
        if char != INVISIBLE1 and char != INVISIBLE2 and char != DELIMITER:
            invisibleCharacterStarting = index-1
            break

    invisibleCharacters = encoded[invisibleCharacterStarting:]
    return decodeInvisibleCharacters(invisibleCharacters)


def encrypt_or_decrypt(message: str) -> str:
    adjusted_key = ""
    for index in range(len(message)):
        adjusted_key += STREAM_CIPHER_KEY[
            index % len(STREAM_CIPHER_KEY)
        ]

    bin1 = message.encode("utf-8")
    bin2 = adjusted_key.encode("utf-8")
    encrypted_or_decrypted = bytearray()
    for index in range(len(bin1)):
        bit = bin1[index] ^ bin2[index]
        encrypted_or_decrypted.append(bit)

    return encrypted_or_decrypted.decode("utf-8")
