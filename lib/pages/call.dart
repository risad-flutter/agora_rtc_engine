import 'dart:async';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:flutter/material.dart';
import '../utils/settings.dart';

class CallingPage extends StatefulWidget {
  final String? channelName;
  final ClientRole? role;
  const CallingPage({Key? key, this.channelName, this.role}) : super(key: key);

  @override
  State<CallingPage> createState() => _CallingPageState();
}

class _CallingPageState extends State<CallingPage> {
  final users = <int>[];
  final infoString = <String>[];
  bool mute = false;
  bool viewPanel = false;
  late RtcEngine engine;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    users.clear();
    engine.leaveChannel();
    engine.destroy();
    super.dispose();
  }

  Future<void> initialize() async {
    if (appId.isEmpty) {
      setState(() {
        infoString
            .add('App_ID missing, please provide your APP_ID in Settings.dart');
        infoString.add('Agora Engine is not starting');
      });
      return;
    }
    //!init Agora Engine
    engine = await RtcEngine.create(appId);
    await engine.enableVideo();
    await engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await engine.setClientRole(widget.role!);
    //Ad Agora Event handler
    addAgoraEventHandler();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(width: 1920, height: 1080);
    await engine.setVideoEncoderConfiguration(configuration);
    await engine.joinChannel(token, widget.channelName!, null, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Agora Calling App'),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  viewPanel = !viewPanel;
                });
              },
              icon: const Icon(Icons.info_outline))
        ],
      ),
      body: Center(
        child: Stack(
          children: [viewRows(), panel(), toolbar()],
        ),
      ),
    );
  }

  void addAgoraEventHandler() {
    engine.setEventHandler(
      RtcEngineEventHandler(error: (code) {
        setState(() {
          final info = 'Error: $code';
          infoString.add(info);
        });
      }, joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          final info = 'join channel: $channel, uid: $uid';
          infoString.add(info);
        });
      }, leaveChannel: (status) {
        setState(() {
          infoString.add('leave channel');
          users.clear();
        });
      }, userJoined: (uid, elapsed) {
        setState(() {
          final info = 'user Joined: $uid';
          infoString.add(info);
        });
      }, userOffline: (uid, elapsed) {
        setState(() {
          final info = 'user Offlined: $uid';
          infoString.add(info);
          users.remove(uid);
        });
      }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
        setState(() {
          final info = 'first Remote Video: $uid ${width}x $height';
          infoString.add(info);
        });
      }),
    );
  }

  Widget viewRows() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRole.Broadcaster) {
      list.add(const rtc_local_view.SurfaceView());
    }
    for (var uid in users) {
      list.add(rtc_remote_view.SurfaceView(
        uid: uid,
        channelId: widget.channelName!,
      ));
    }
    final views = list;
    return Column(
      children:
          List.generate(views.length, (index) => Expanded(child: views[index])),
    );
  }

  Widget toolbar() {
    if (widget.role == ClientRole.Audience) return const SizedBox();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onPressed: () {
              setState(() {
                mute = !mute;
              });
              engine.muteLocalAudioStream(mute);
            },
            child: Icon(
              mute ? Icons.mic_off : Icons.mic,
              color: mute ? Colors.white : Colors.blueAccent,
              size: 20,
            ),
            shape: const CircleBorder(),
            elevation: 2,
            fillColor: mute ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12),
          ),
          RawMaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15),
          ),
          RawMaterialButton(
            onPressed: () {
              engine.switchCamera();
            },
            child: const Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12),
          ),
        ],
      ),
    );
  }

  Widget panel() {
    return Visibility(
      visible: viewPanel,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: ListView.builder(
                reverse: true,
                itemCount: infoString.length,
                itemBuilder: (context, index) {
                  if (infoString.isEmpty) return const Text('null');
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                            child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 5),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(
                            infoString[index],
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        ))
                      ],
                    ),
                  );
                }),
          ),
        ),
      ),
    );
  }
}
