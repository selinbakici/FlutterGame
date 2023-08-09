import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';


class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {

  double _redSize = 75.0;
  double _greenSize = 75.0;
  double _pauseSize = 75.0;
  bool _isShrinking = false;

  //Küçülme animasyonu fonksiyonu.
  void _shrink(bool which,num pause) {
    setState(() {
      _isShrinking = true;
      if(which && pause == 1){
        _redSize = 50.0;
      }else if(pause == 0){
        _pauseSize = 50.0;
      } else{
        _greenSize = 50.0;
      }
    });
  }
  //Büyüme animasyonu fonksiyonu.
  void _grow(bool which,num pause) {
    setState(() {
      _isShrinking = false;
      if(which && pause == 1){
        _redSize = 75.0;
      }else if(pause == 0){
        _pauseSize = 75.0;
      } else{
        _greenSize = 75.0;
      }
    });
  }
  //Bu fonksiyon türkçe kelime verilerini bir listeye ekleyip kullanılabilir hale getirir.
  //Yaklaşık 80.000 kelime var ve tüm kelimeler proje için uygun.
  Future<List<String>> _loadLines() async {
    List<String> questions = [];
    await rootBundle.loadString("assets/turkishword.txt").then((q) {
      for (String i in LineSplitter().convert(q)) {
        questions.add(i);
      }
    });
    return questions;
  }

  var iceCheck = 0;
  final List<List<Text>> _grid = [];
  List<String> wordsList = [];
  final _scrollController = ScrollController();
  Timer? _timer;
  var started = 0;
  var gameStarted = false;
  List<String> checkString = [];
  List<String> lettersLocation = [];
  late SharedPreferences prefs;
  var score = 0;
  var callTheAddRow = 0;
  var iceLetter = 0;
  var top = true;
  var bottom = true;
  var GameEnd = false;
  var flag = true;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      _asyncMethod();
    });
    _initGrid();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _addRow());
    _startFalling();
    _startAddingRandomLetters();
  }

  _asyncMethod() async {
    prefs = await SharedPreferences.getInstance();
    wordsList = await _loadLines();
  }

  @override
  void dispose() {
    // Cancel the timer if it's still active
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  //Bu fonksiyon, rastgele türkçe harf döndürür.
  String getRandomTurkishLetter() {
    final Random random = Random();
    if(gameStarted){
      final Random random = Random();
      const String letters = "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ";
      return letters.split('')[random.nextInt(28)].toString();
    }else{
      const String soundletters = "AEIİOÖUÜ";
      const String notsoundletters = "BCÇDFGĞHJKLMNPRSŞTVYZ";
      if(flag){
        flag = !flag;
        return soundletters.split('')[random.nextInt(7)].toString();
      }else{
        flag = !flag;
        return notsoundletters.split('')[random.nextInt(20)].toString();
      }
    }
  }

  //10x8 lik bir alan yaratır.
  void _initGrid() {
    //Kolon
    const rowLength = 8;
    //Satır
    const rowCount = 10;
    //Tüm alanı başta boş doldurur bu sayede 10x8 lik alanı yaratır alttaki for döngüsüyle.
    for (var i = 0; i < rowCount; i++) {
      final row = <Text>[];
      for (var j = 0; j < rowLength; j++) {
        
        //Bos olucak
        row.add(Text(''));
      }
      _grid.add(row);
    }
  }

  //Bu fonksiyon alana sadece bir satır harf ekler.
  //Rastgele harfleri birleştirerek bir satır oluşturur ve bunu alana ekler.
  void _justOneRow() async {
    final random = Random();
    final row = <Text>[];
    for (var j = 0; j < _grid[0].length; j++) {
      final letter = Text(getRandomTurkishLetter(),
        style: TextStyle(color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),fontSize: 25),);
      row.add(letter);
    }

    setState(() {
      if (_grid.first.any((element) => element.data!.isNotEmpty)) {
        _grid.removeLast();
      }

      for (var i = _grid.length - 1; i >= 1; i--) {
        for (var j = 0; j < _grid[i].length; j++) {
          if (_grid[i][j].data!.isEmpty && _grid[i - 1][j].data!.isNotEmpty) {
            _grid[i][j] = _grid[i - 1][j];
            _grid[i - 1][j] = Text('');
          }
        }
      }


      _grid[0] = row;
    });
  }

  //Bu fonksiyon alana sadece bir satır harf ekler.
  //Rastgele harfleri birleştirerek bir satır oluşturur ve bunu alana ekler.
  void _addRow() async{
    if(started < 3){
      _deletingTheLettersFromPrefs();
      final random = Random();
      final row = <Text>[];
      for (var j = 0; j < _grid[0].length; j++) {
        final letter = Text(getRandomTurkishLetter(),
          style: TextStyle(color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),fontSize: 25),);
        row.add(letter);
      }

      setState(() {
        if (_grid.first.any((element) => element.data!.isNotEmpty)) {
          _grid.removeLast();
        }

        // Shift all boxes down by one cell
        for (var i = _grid.length - 1; i >= 1; i--) {
          for (var j = 0; j < _grid[i].length; j++) {
            if (_grid[i][j].data!.isEmpty && _grid[i - 1][j].data!.isNotEmpty) {
              _grid[i][j] = _grid[i - 1][j];
              _grid[i - 1][j] = Text('');
            }
          }
        }

        // Add the new row to the top
        _grid[0] = row;
      });
      started++;
    }else{
      gameStarted = true;
    }
  }

  //Asagidaki kod her 300 millisaniyede bir çalışır ve eğer bir harfin altındaki harf boşsa onu bir birim aşağı kaydırır(Düşme Efekti).
  void _startFalling() {
    const fallDuration = Duration(milliseconds: 300);
    Timer.periodic(fallDuration, (_) {
      setState(() {
        //Bahsettiğim düşme efekti aşağıdaki for döngüsü ile yaratılıyor.
        for (var i = _grid.length - 1; i >= 1; i--) {
          for (var j = 0; j < _grid[i].length; j++) {
            if (_grid[i][j].data!.isEmpty && _grid[i - 1][j].data!.isNotEmpty) {
              _grid[i][j] = _grid[i - 1][j];
              _grid[i - 1][j] = Text('');
            }
          }
        }
        //Alttaki kodda ise buz harf kodu çalışıyor.
        //Kod bir buz harf ile karşılaştığı zaman. Eğer altında ve üstünde bir harf varsa onlarıda buz harf yapar.
        for(var k = _grid.length - 1; k >= 1; k--){
          for(var l = 0; l < _grid[k].length; l++){
            try{
              if (_grid[k][l].data!.isNotEmpty && _grid[k][l].data!.split(" ")[1] == "." && _grid[k + 1][l].data!.isNotEmpty && bottom) {
                _grid[k + 1][l] = Text(_grid[k + 1][l].data.toString() + " `", style: TextStyle(color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),fontSize: 25,backgroundColor: Colors.white),);
                bottom = false;
              }
              if (_grid[k][l].data!.isNotEmpty && _grid[k][l].data!.split(" ")[1] == "." && _grid[k - 1][l].data!.isNotEmpty && top) {
                _grid[k - 1][l] = Text(_grid[k - 1][l].data.toString() + " ,", style: TextStyle(color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),fontSize: 25,backgroundColor: Colors.white),);
                top = false;
              }
            }catch(e){
              //print(e);
            }
          }
        }
      });
      //Here,We are checking if the game is end or not.
      //If one letter
      if((_grid[0][0].data!.isNotEmpty || _grid[0][1].data!.isNotEmpty || _grid[0][2].data!.isNotEmpty || _grid[0][3].data!.isNotEmpty || _grid[0][4].data!.isNotEmpty || _grid[0][5].data!.isNotEmpty || _grid[0][6].data!.isNotEmpty || _grid[0][7].data!.isNotEmpty) && !GameEnd){
        GameEnd = true;
        Fluttertoast.showToast(
            msg: "Game Over!!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
        );
        if(prefs.getInt("AddedHighScore").toString().isNotEmpty){
          var number = prefs.getInt("AddedHighScore")?.toInt() ?? 0;
          prefs.setInt("AddedHighScore",number + 1);
          prefs.setInt("HighScore ${prefs.getInt("AddedHighScore")}", score);
        }else{
          prefs.setInt("AddedHighScore",1);
          prefs.setInt("HighScore ${1}", score);
        }
        SystemNavigator.pop();
      }
    });
  }

  //Bu fonksiyon, alana sadece bir harf ekler.
  //Rastgele bir harfi alır ve en üst satırdan bir alan seçerek onu oraya ekler.
  void _addRandomLetter() {
    if(gameStarted){
      const rowLength = 8;
      var newLetter;
      final random = Random();
      if(iceLetter == 15){
        newLetter = Text(getRandomTurkishLetter() + " .",
          style: TextStyle(color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),fontSize: 25,backgroundColor: Colors.white),);
        iceLetter++;
      }else{
         newLetter = Text(getRandomTurkishLetter(),
          style: TextStyle(color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),fontSize: 25),);
         iceLetter++;
      }


      setState(() {
        _grid[0][random.nextInt(rowLength)] = newLetter;
      });
    }
  }


  void _startAddingRandomLetters() {
    const interval = Duration(seconds: 5);
    Timer.periodic(interval, (_) => _addRandomLetter());
  }

  void _changeTimerInterval(Duration newInterval) {
    var _interval = newInterval;
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _addRandomLetter());
  }

  //Her doğru tahmine göre skoru günceller.
  void _calculatingScore(){
    for (var i = 0; i < checkString.length; i++) {
      switch(checkString[i]){
        case "A":
          score++;
          break;
        case "B":
          score+=3;
          break;
        case "C":
          score+=4;
          break;
        case "Ç":
          score+=4;
          break;
        case "D":
          score+=3;
          break;
        case "E":
          score+=1;
          break;
        case "F":
          score+=7;
          break;
        case "G":
          score+=5;
          break;
        case "Ğ":
          score+=8;
          break;
        case "H":
          score+=5;
          break;
        case "I":
          score+=2;
          break;
        case "İ":
          score+=1;
          break;
        case "J":
          score+=10;
          break;
        case "K":
          score+=1;
          break;
        case "L":
          score+=1;
          break;
        case "M":
          score+=2;
          break;
        case "N":
          score+=1;
          break;
        case "O":
          score+=2;
          break;
        case "Ö":
          score+=7;
          break;
        case "P":
          score+=5;
          break;
        case "R":
          score+=1;
          break;
        case "S":
          score+=2;
          break;
        case "Ş":
          score+=4;
          break;
        case "T":
          score+=1;
          break;
        case "U":
          score+=2;
          break;
        case "Ü":
          score+=3;
          break;
        case "V":
          score+=7;
          break;
        case "Y":
          score+=3;
          break;
        case "Z":
          score+=4;
          break;
      }

    }

    if(score >= 100 && score < 200){
      _changeTimerInterval(Duration(seconds: 4));
      print("4 saniye");
    }else if(score >= 200 && score < 300){
      _changeTimerInterval(Duration(seconds: 3));
      print("3 saniye");
    }else if(score >= 300 && score < 400){
      _changeTimerInterval(Duration(seconds: 2));
      print("2 saniye");
    }else if(score >= 400){
      _changeTimerInterval(Duration(seconds: 1));
      print("1 saniye");
    }

  }

  BoxDecoration getBoxDecoration(num row,num col) {
    try {
      // code that might throw an exception
      return BoxDecoration(
        color: prefs.getBool(row.toString()+col.toString()) == true ? Colors.red: Color(0xFFC9C9C9),
      );
    } catch (e) {
      // handle the exception
      return BoxDecoration(
        color: Color(0xFFC9C9C9),
      );
    }
  }

  //Harfleri alandan siler.
  //Eğer kullanıcı doğru kelime tahmin ederse aşağıdaki kod çalışır kelimenin içindekileri silmek için.
  void _deletingTheLetters(){
    for (var i = 0; i < lettersLocation.length; i++) {
      var RowLocation = int.parse(lettersLocation[i].split(" ")[0]);
      var ColLocation = int.parse(lettersLocation[i].split(" ")[1]);
      _grid[RowLocation][ColLocation] = Text('');
    }
    //prefs.clear();
    checkString.clear();
    lettersLocation.clear();
  }

  //Kod bazı kelimeleri telefona kaydeder oradan silmesi için çalışan bir fonksiyon.
  //Kaydetme nedeni: işaretlenen harfler kırmızıyla gösterilir.
  void _deletingTheLettersFromPrefs(){
    for (var i = _grid.length - 1; i >= 1; i--) {
      for (var j = 0; j < _grid[i].length; j++) {
        var RowLocation = i.toString();
        var ColLocation = j.toString();
        prefs.remove(RowLocation+ColLocation);
      }
    }
    // for (var i = 0; i < lettersLocation.length; i++) {
    //   var RowLocation = lettersLocation[i].split(" ")[0];
    //   var ColLocation = lettersLocation[i].split(" ")[1];
    //   prefs.remove(RowLocation+ColLocation);
    // }
  }

  //Kullanıcının doğru tahmin edip etmediğini kontrol eder.
  bool _correctCheck(String answer){
    for(int i = 0;i<wordsList.length;i++){
      if(answer == wordsList[i].toUpperCase()){
        return true;
        break;
      }
    }
    return false;
  }


  //Gorunus
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC9C9C9),
      body: ListView(
        controller: _scrollController,
        children: [
          Row(
            children: [
              GestureDetector(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  width: _pauseSize,
                  height: _pauseSize,
                  child: Image.asset('images/pauseback.png'),
                ),
                onTap: () {
                  if (!_isShrinking) {
                    _shrink(true,0);
                    Timer(Duration(milliseconds: 150), () {
                      _grow(true,0);
                    });
                  }
                  GameEnd = true;
                  Fluttertoast.showToast(
                      msg: "Game Over!!!",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0
                  );
                  if(prefs.getInt("AddedHighScore").toString().isNotEmpty){
                    var number = prefs.getInt("AddedHighScore")?.toInt() ?? 0;
                    prefs.setInt("AddedHighScore",number + 1);
                    prefs.setInt("HighScore ${prefs.getInt("AddedHighScore")}", score);
                  }else{
                    prefs.setInt("AddedHighScore",1);
                    prefs.setInt("HighScore ${1}", score);
                  }
                  SystemNavigator.pop();
                },
              ),
              Container(width: 18,),
              Image.asset('images/closeback.png',width: 40,),
              Stack(
                  children: <Widget>[
                    Image.asset('images/scoreback.png',width: 140,),
                    Positioned(
                        top: 40,
                        left: 55,
                        child: Center(child: Text(score.toString(),style: TextStyle(fontSize: 50,color: const Color(0xFF6C6C6C)),))
                    ),
                  ]
              ),
              Image.asset('images/closeback.png',width: 40,)
            ],),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemBuilder: (context, index) {
              final row = index ~/ 8;
              final col = index % 8;
              return Container(
                decoration: getBoxDecoration(row, col),
                child: GestureDetector(
                  onTap: () async {
                    try{
                      if(_grid[row][col].data.toString().split(" ")[1] == "." || _grid[row][col].data.toString().split(" ")[1] == "," || _grid[row][col].data.toString().split(" ")[1] == "`"){
                        if(prefs.getBool(_grid[row][col].data.toString().split(" ")[1]) == true){
                          setState(() {
                            checkString.remove(_grid[row][col].data.toString().split(" ")[0]);
                            //lettersLocation.remove(row.toString() + " " + col.toString());
                            print("ilk cikardim");
                          });
                          if(prefs.getBool(row.toString()+col.toString()) == false){
                            setState(() {
                              checkString.remove(_grid[row][col].data.toString().split(" ")[0]);
                              lettersLocation.remove(row.toString() + " " + col.toString());
                              print("ikinci cikardim");
                            });
                            await prefs.setBool(_grid[row][col].data.toString().split(" ")[1], false);
                          }
                          await prefs.setBool(row.toString()+col.toString(), false);
                        }else{
                          if(prefs.getBool(row.toString()+col.toString()) == true){
                            await prefs.setBool(_grid[row][col].data.toString().split(" ")[1], true);
                            setState(() {
                              print("ikinci ekledim");
                              checkString.add(_grid[row][col].data.toString().split(" ")[0]);
                              //lettersLocation.add(row.toString() + " " + col.toString());
                            });
                          }else{
                            setState(() {
                              print("ilk ekledim");
                              checkString.add(_grid[row][col].data.toString().split(" ")[0]);
                              lettersLocation.add(row.toString() + " " + col.toString());
                            });
                            await prefs.setBool(row.toString()+col.toString(), true);
                          }
                        }
                      }
                    }catch(e) {

                      if(prefs.getBool(row.toString()+col.toString()) == true){
                        setState(() {
                          checkString.remove(_grid[row][col].data.toString());
                          lettersLocation.remove(row.toString() + " " + col.toString());
                        });
                        print("cikardim");
                        await prefs.setBool(row.toString()+col.toString(), false);
                      }else{
                        setState(() {
                          print("ekledim");
                          checkString.add(_grid[row][col].data.toString());
                          lettersLocation.add(row.toString() + " " + col.toString());
                        });
                        await prefs.setBool(row.toString()+col.toString(), true);
                      }

                    }
                  },
                  child: _grid[row][col],
                ),
              );
            },
            itemCount: _grid.length * _grid[0].length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  width: _redSize,
                  height: _redSize,
                  child: Image.asset('images/redback.png'),
                ),
                onTap: () {
                if (!_isShrinking) {
                  _shrink(true,1);
                  Timer(Duration(milliseconds: 150), () {
                    _grow(true,1);
                  });
                }
                setState(() {
                  _deletingTheLettersFromPrefs();
                  checkString.clear();
                  lettersLocation.clear();
                });
                },
              ),
              Text(checkString.join(),style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
              GestureDetector(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  width: _greenSize,
                  height: _greenSize,
                  child: Image.asset('images/correctback.png'),
                ),
                onTap: () {
                if (!_isShrinking) {
                  _shrink(false,2);
                  Timer(Duration(milliseconds: 150), () {
                    _grow(false,2);
                  });
                }
                if(_correctCheck(checkString.join())){
                  setState(() {
                    _deletingTheLettersFromPrefs();
                    _calculatingScore();
                    _deletingTheLetters();
                  });
                }else{
                  setState(() {
                    _deletingTheLettersFromPrefs();
                    checkString.clear();
                    lettersLocation.clear();
                  });
                  callTheAddRow++;
                  if(callTheAddRow == 3){
                    _justOneRow();
                    callTheAddRow = 0;
                  }
                }
              },
              ),
            ],
          )
        ],
      ),
    );
  }
}
