import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import './call.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({
    Key? key,
  }) : super(key: key);

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final channerController = TextEditingController();
  bool validateEror = false;
  ClientRole? role = ClientRole.Broadcaster;
  @override
  void dispose() {
    channerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(
              height: 40,
            ),
            Image.network(
                'https://www.kindpng.com/picc/m/40-404965_whatsapp-video-calling-icon-video-call-whatsapp-png.png'),
            const SizedBox(
              height: 20,
            ),
            TextFormField(
              controller: channerController,
              decoration: InputDecoration(
                errorText: validateEror ? 'Channer Name is Mandatory' : null,
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(width: 1),
                ),
              ),
            ),
            RadioListTile(
              title: const Text('Broadcaster'),
              onChanged: (ClientRole? value) {
                role = value;
                setState(() {});
              },
              value: ClientRole.Broadcaster,
              groupValue: role,
            ),
            RadioListTile(
              title: const Text('Audience'),
              onChanged: (ClientRole? value) {
                role = value;
                setState(() {});
              },
              value: ClientRole.Audience,
              groupValue: role,
            ),
            ElevatedButton(
              onPressed: onJoin,
              child: const Text(
                'Join',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> onJoin() async {
    setState(() {
      channerController.text.isEmpty
          ? validateEror = true
          : validateEror = false;
    });
    if (channerController.text.isNotEmpty) {
      await handleCameraAndMic(Permission.camera);
      await handleCameraAndMic(Permission.microphone);
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CallingPage(
                    channelName: channerController.text,
                    role: role,
                  )));
    }
  }

  Future<void> handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    log(status.toString());
  }
}
