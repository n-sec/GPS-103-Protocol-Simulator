import 'dart:async';
import 'dart:io';
import 'package:device/targetDialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'GPS103 Protocol Emulator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _prefs = SharedPreferences.getInstance();
  final _targetTextEditingController = TextEditingController();
  bool _connected = false;
  bool _heartbeat = true;
  bool _liveLocation = true;
  Timer _heartbeatTimer;
  Timer _liveLocationTimer;
  Socket _socket;
  String _host;
  int _port;

  @override
  void initState() {
    super.initState();

    _prefs.then((prefs) {
      _host = prefs.getString('host');
      _port = prefs.getInt('port');

      if (_host != null && _port != null) {
        _targetTextEditingController.text = '${this._host}:${this._port}';
      }
    });
  }

  void socketConnect() {
    Socket.connect(_host, _port).then((socket) {
      _socket = socket;

      setState(() {
        _connected = true;
      });

      heartbeat();
      liveLocation();

      socket.listen((data) {
        print(data);
      },
      onError: (error) {
        print(error);
        setState(() {
          _connected = false;
        });
        _heartbeatTimer.cancel();
        _liveLocationTimer.cancel();
      });
    });
  }

  void targetDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => TargetDialog(
        targetTextEditingController: _targetTextEditingController,
      ),
    );

    if (result != null) {
      _host = result['host'];
      _port = result['port'];

      _prefs.then((prefs) {
        prefs.setString('host', _host);
        prefs.setInt('port', _port);
      });
    }
  }

  void heartbeat() {
    if (_connected && _heartbeat) {
      Timer.periodic(Duration(seconds: 30), (timer) {
        _heartbeatTimer = timer;
        print('${DateTime.now()}: Heartbeat');
      });
    }
  }

  void liveLocation() {
    if (_connected && _liveLocation) {
      Timer.periodic(Duration(seconds: 10), (timer) {
        _liveLocationTimer = timer;
        print('${DateTime.now()}: Live Location');
        location();
      });
    }
  }

  void location() {
    Object location = 'imei:864893031530374,tracker,190602052746,,F,212746.00,A,0255.02212,S,04145.24224,W,14.852,4.53;';
    _socket.write(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => targetDialog(),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          SwitchListTile(
            title: Text('Service'),
            value: _connected,
            onChanged: (service) {
              if (_host != null && _port != null) {
                if (service) {
                  socketConnect();
                } else {
                  _socket.destroy();

                  setState(() {
                    _connected = false;
                  });

                  _heartbeatTimer.cancel();
                }
              } else {
                targetDialog();
              }
            },
          ),
          Divider(),
          SwitchListTile(
            title: Text('Heartbeat'),
            value: _connected ? _heartbeat : false,
            onChanged: _connected ? (value) {
              if (value) {
                setState(() {
                  _heartbeat = true;
                });
                heartbeat();
              } else {
                setState(() {
                  _heartbeat = false;
                });
                _heartbeatTimer.cancel();
              }
            } : null,
          ),
          Divider(),
          SwitchListTile(
            title: Text('Live Location'),
            value: _connected ? _liveLocation : false,
            onChanged: _connected ? (value) {
              if (value) {
                setState(() {
                  _liveLocation = true;
                });
              } else {
                setState(() {
                  _liveLocation = false;
                });
                  _liveLocationTimer.cancel();
              }
            } : null,
          ),
        ],
      ),
    );
  }
}

/*
[::ffff:177.221.240.119:54553][sending]: ##,imei:864893031530374,A;
[::ffff:177.221.240.119:54553][receiving]: LOAD
[::ffff:177.221.240.119:54553][sending]: imei:864893031530374,acc on,190602052741,,F,212741.00,A,0255.04532,S,04145.24370,W,17.146,4.72;
[::ffff:177.221.240.119:54553][sending]: imei:864893031530374,tracker,190602052746,,F,212746.00,A,0255.02212,S,04145.24224,W,14.852,4.53;
*/