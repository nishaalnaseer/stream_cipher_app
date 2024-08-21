import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:stream_cipher_client/my_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'model.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stream Cipher Chat App',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Stream Cipher Chat App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool connected = false;
  String username = "";
  late Uri wsUrl = Uri.parse('ws://127.0.0.1:8000/chat?username=$username');
  late WebSocketChannel channel;
  List<Widget> textBubbles = [];
  List<Message> messages = [];
  var controller = TextEditingController();
  var controller2 = TextEditingController();
  String streamCipherKey = "HelloItsaMe!";
  String invisible1 = "\u200C";
  String invisible2 = "\u200D";
  String delimiter = "\u2060";

  @override
  void initState() {
    super.initState();
  }

  void webSocket() async {
    while (connected) {
      bool connected = true;

      try {
        channel = WebSocketChannel.connect(wsUrl);
        logger.log(Level.info, 'Starting Websocket Connection');
        await channel.ready;

        // Add a delay before continuing
        await Future.delayed(const Duration(seconds: 2));
      } on Exception catch (e) {

        // Add a delay before retrying
        await Future.delayed(const Duration(seconds: 5));
        continue;
      }

      try {
        channel.stream.listen((withStanChan) async {
          String withoutStanChan = removeStanChan(withStanChan);
          String message = encryptOrDecrypt(withoutStanChan);

          setState(() {
            messages.add(Message(alignRight: false, text: message));
          });
          logger.log(
            Level.info,
            "Message received, Message: $message, Ciphertext: $withoutStanChan"
            "plaintext: $withoutStanChan"
          );
        },
        onError: (err) async {
          connected = false;
          logger.log(Level.info, 'WebSocket connection err $err');
          await channel.sink.close();
        },
        onDone: () async {
          logger.log(Level.info, 'WebSocket connection onDone');
          await channel.sink.close();
          connected = false;
        },
        cancelOnError: true
        );
      } on Exception catch (e) {
        connected = false;
        try {
          await channel.sink.close();
        } on Exception {
          logger.log(Level.info, 'WebSocket connection Error');
        }
      }

      while(connected && connected) {
        await Future.delayed(const Duration(seconds: 2));
      }
      try {
        await channel.sink.close();
      } on Exception {

      }
    }
  }

  void startWebSocket() {
    if(!connected) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          var _controller = TextEditingController();
          return AlertDialog(
            title: const Text('Enter Username'),
            content: TextField(
              controller: _controller,
            ),

            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {

                  String name = _controller.text.trim();
                  if(name.isEmpty) {
                    return;
                  }
                  username = name;
                  setState(() {
                    connected = true;
                  });
                  webSocket();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void stopWebSocket() {
    if(connected) {
      channel.sink.close();
      connected = false;
    }
  }

  String encodeInvisibleCharacters(String message) {
    String applied = "";

    List<int> utfBytes = utf8.encode(message);

    for (int index = 0; index < utfBytes.length; index++) {
      var number = utfBytes[index];
      for (int bitIndex = 0; bitIndex < 8; bitIndex++) {
        int bit = (number >> (7 - bitIndex)) & 1;
        if (bit == 1) {
          applied += invisible1;
        } else {
          applied += invisible2;
        }
      }
      applied += delimiter;
    }

    return applied;
  }

  String decodeInvisibleCharacters(String encoded) {
    List<int> bytes = [];
    var number = 0;
    int bitCount = 0;

    for (int index = 0; index < encoded.length; index++) {
      String character = encoded[index];

      if (character == invisible1) {
        number = (number << 1) | 1;
        bitCount++;
      } else if (character == invisible2) {
        number = (number << 1) | 0;
        bitCount++;
      } else if (character == delimiter) {
        bytes.add(number);
        number = 0;
        bitCount = 0;
      }

      // Add the last byte if we reach the end of the string
      if (index == encoded.length - 1 && bitCount == 8) {
        bytes.add(number);
      }
    }

    return utf8.decode(bytes);
  }

  String applyStanChan(String message, String message2) {
    String invisibleCharacters = encodeInvisibleCharacters(message);
    return message2 + invisibleCharacters;
  }
  
  String removeStanChan(String encoded) {
    int invisibleCharacterStarting = 0;
    
    for(int index = encoded.length-1; -1 < index; index--) {
      String char = encoded[index];
      if(char != invisible1 && char != invisible2 && char != delimiter) {
        invisibleCharacterStarting = index+1;
        break;
      }
    }

    String invisibleCharacters = encoded.substring(invisibleCharacterStarting);
    
    return decodeInvisibleCharacters(invisibleCharacters);
  }

  String encryptOrDecrypt(String message) {
    String adjustedKey = "";
    for(int index = 0; index < message.length; index++) {
      String character = streamCipherKey[
        index % streamCipherKey.length
      ];
      adjustedKey += character;
    }

    List<int> bin1 = utf8.encode(message);
    List<int> bin2 = utf8.encode(adjustedKey);
    List<int> encryptedOrDecrypted = [];
    // print(message);

    for(int index = 0; index < bin1.length; index++) {
      var bin = bin1[index] ^ bin2[index];
      encryptedOrDecrypted.add(bin);
    }
    return utf8.decode(encryptedOrDecrypted);
  }

  void sendMessage() {
    if(!connected){
      return;
    }

    String text = controller.text.trim();
    String text2 = controller2.text.trim();
    if(text.isEmpty || text2.isEmpty) {
      return;
    }

    String message2 = text;
    String message1 = text2;

    String cipherText = encryptOrDecrypt(message2);
    String withStanChan = applyStanChan(cipherText, message1);
    String plainText = encryptOrDecrypt(cipherText);

    logger.log(
        Level.info,
        "Input Received: Cipher Text: $cipherText, Plain Text $plainText,"
            "Length of CipherText = ${cipherText.length}, "
            "Length with Steganography = ${withStanChan.length}"
    );

    messages.add(Message(alignRight: true, text: text));
    setState(() {

    });

    channel.sink.add("$username: $withStanChan");
    controller.clear();
    controller2.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: 500,
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index];
                  return Container(
                    padding: const EdgeInsets.all(5),
                    width: 500,

                    child: Align(
                      alignment: message.alignRight ?
                        Alignment.bottomRight : Alignment.centerLeft,
                      child: Text(message.text),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
              child: SizedBox(
                width: 400,
                child: TextField(
                  controller: controller2,
                  decoration: const InputDecoration(
                    hintText: "Message1"
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
              child: SizedBox(
                width: 400,
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                      hintText: "Message2"
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
              child: ElevatedButton(
                onPressed: () async {
                  sendMessage();
                },
                child: const Text(
                    "Send"
                ),
              ),
            )
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if(connected) {
              stopWebSocket();
            } else {
              startWebSocket();
            }
          });
        },
        tooltip: connected ? 'Disconnect' : "Connect",
        child: Icon(
            connected ? Icons.signal_cellular_connected_no_internet_4_bar
                : Icons.signal_cellular_connected_no_internet_0_bar
        ),
      ),
    );
  }
}
