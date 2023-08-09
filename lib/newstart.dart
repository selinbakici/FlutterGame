import 'gameScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {

  late Future<SharedPreferences> _prefsFuture;
  var test = 0;
  double _size = 300.0;
  bool _isShrinking = false;

  //Küçülme animasyonu fonksiyonu.
  void _shrink() {
    setState(() {
      _isShrinking = true;
      _size = 50.0;
    });
  }
  //Büyüme animasyonu fonksiyonu.
  void _grow() {
    setState(() {
      _isShrinking = false;
      _size = 300.0;
    });
  }

  _asyncMethod() async {
    //prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    _prefsFuture = SharedPreferences.getInstance();
  }
  //Asağıdaki kod, kaydedilen High Score verilerini bir listeye ekleyerek daha sonra widgetta kullanılması için hazır hale getirir.
  List<int> _getIntValuesFromPreferences(SharedPreferences prefs) {
    List<int> intValues = [];
    var number = prefs.getInt("AddedHighScore")?.toInt() ?? 0;
    for(int i = 0;i < number + 1;i++){
      if(prefs.getInt("HighScore ${i}").toString().isNotEmpty){
        var added = prefs.getInt("HighScore ${i}")?.toInt() ?? 0;
        intValues.add(added);
      }
    }
    return intValues;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC9C9C9),
      body: Column(
        children: [
          const SizedBox(height: 80),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'WordGame',
                style: TextStyle(fontSize: 50, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'High Score Table',
                style: TextStyle(fontSize: 20, color: Colors.black54),
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<SharedPreferences>(
              future: _prefsFuture,
              builder: (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: _getIntValuesFromPreferences(snapshot.data!).length.toString().isEmpty ? 0 : _getIntValuesFromPreferences(snapshot.data!).length,
                    itemBuilder: (context, index) {
                      int value = _getIntValuesFromPreferences(snapshot.data!)[index].toString().isEmpty ? 0 : _getIntValuesFromPreferences(snapshot.data!)[index];
                      return ListTile(
                        title: Center(child: Text(value.toString(),style: TextStyle(color: Colors.black54,fontSize: 40,),)),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              if (!_isShrinking) {
                _shrink();
                Timer(Duration(milliseconds: 250), () {
                  _grow();
                  Navigator.pushReplacementNamed(context, '/game');
                });
              }
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 250),
              width: _size,
              height: _size,
              child: Image.asset('images/plaback.png'),
            ),
          )
        ],
      ),
    );
  }
}
