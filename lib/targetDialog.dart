import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TargetDialog extends StatelessWidget {
  final TextEditingController targetTextEditingController;
  static final targetFormKey = GlobalKey<FormState>();

  TargetDialog({Key key, @required this.targetTextEditingController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String host;
    int port;

    return AlertDialog(
      title: Text('Endereço do servidor:'),
      content: Form(
        key: targetFormKey,
        child: TextFormField(
          controller: targetTextEditingController,
          autofocus: true,
          autocorrect: false,
          validator: (value) {
            if (value.isEmpty) {
              return 'Digite um endereço válido.';
            }

            final data = value.split(':');

            if (data.length != 2) {
              return 'Digite um endereço válido.';
            }

            try {
              host = InternetAddress(data[0]).host;
            } catch (e) {
              return 'Digite um endereço válido.';
            }

            try {
              port = int.parse(data[1]);
            } catch (e) {
              return 'Digite um endereço válido.';
            }

            return null;
          },
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Cancelar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text('OK'),
          onPressed: () {
            if (targetFormKey.currentState.validate()) {
              Navigator.pop(context, {
                'host': host,
                'port': port,
              });
            }
          },
        ),
      ],
    );
  } 
}

/*
this._prefs.then((res) async {
  final host = await res.setString('host', this.host);
  final port = await res.setInt('port', this.port);

  if (host && port) {
    Navigator.of(context).pop();
  }
});
*/