import 'dart:io';
import 'package:device/targetDialog.dart';
import 'package:flutter/cupertino.dart';
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

      socket.listen((data) {
        print(data);
      },
      onDone: () {
        setState(() {
          _connected = false;
        });
      },
      onError: (error) {
        print(error);
        setState(() {
          _connected = false;
        });
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

  @override
  Widget build(BuildContext context) {
    List<ListTile> _actions = [
      ListTile(
        title: Text('Send Login Message'),
        onTap: () {
          _socket.write('##,imei:864893031530374,A');
        },
      ),
      ListTile(
        title: Text('Send Heartbeat Message'),
        onTap: () {
          _socket.write('864893031530374;');
        },
      ),
      ListTile(
        title: Text('Send Location Message'),
        onTap: () {
          _socket.write('imei:864893031530374,tracker,190602052746,,F,212746.00,A,0255.02212,S,04145.24224,W,14.852,4.53;');
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          Switch(
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
                }
              } else {
                targetDialog();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => targetDialog(),
          ),
        ],
      ),
      body: _connected ? ListView.separated(
        itemCount: _actions.length,
        separatorBuilder: (context, i) => Divider(),
        itemBuilder: (context, i) => _actions[i],
      ) : Center(
        child: Text('Inicialize o serviço.'),
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