import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share/share.dart';
import 'generated/i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      localeResolutionCallback: S.delegate.resolution(fallback: new Locale("en","")),
      title: "Kasikari Memo",
      routes: <String, WidgetBuilder>{
        '/': (_) =>  Splash(),
        '/list': (_) => List(),
      },
    );
  }
}

class List extends StatefulWidget {
  @override
  _MyList createState() => _MyList();
}

class _MyList extends State<List> {

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              print("login");
              showBasicDialog(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance.collection('users').document(firebaseUser.uid).collection("transaction").snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
              if (!snapshot.hasData) return const Text('Loading...');
              return ListView.builder(
                itemCount: snapshot.data.documents.length,
                padding: const EdgeInsets.only(top: 10.0),
                itemBuilder: (context, index) => _buildListItem(context, snapshot.data.documents[index]),
              );
            }
        ),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            print("新規作成ボタンを押しました");
            Navigator.push(
              context,
              MaterialPageRoute(
                  settings: const RouteSettings(name: "/new"),
                  //新規作成ボタンの修正
                  builder: (BuildContext context) => InputForm(null)
              ),
            );
          }
      ),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document){
    return Card(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.android),
              title: Text("【 " + (document['borrowOrLend'] == "lend"?S.of(context).lend: S.of(context).borrow) + " 】"+ document['stuff']),
              subtitle: Text(S.of(context).deadline(document['date'].toString().substring(0,10)) +"\n"+ S.of(context).who(document['user'])),
            ),
            ButtonTheme.bar(
                child: ButtonBar(
                  children: <Widget>[
                    FlatButton(
                      child: Text(S.of(context).edit),
                        onPressed: ()
                        {
                          print("編集ボタンを押しました");
                          //編集ボタンの処理追加
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                settings: const RouteSettings(name: "/edit"),
                                builder: (BuildContext context) => InputForm(document)
                            ),
                          );
                        }
                    ),
                  ],
                )
            ),
          ]
      ),
    );
  }
}

class InputForm extends StatefulWidget {
  //引数の追加
  InputForm(this.document);
  final DocumentSnapshot document;

  @override
  _MyInputFormState createState() => _MyInputFormState();
}

class _FormData {
  String borrowOrLend = "borrow";
  String user;
  String stuff;
  DateTime date = DateTime.now();
}

class _MyInputFormState extends State<InputForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _FormData _data = _FormData();

  void _setLendOrRent(String value){
    setState(() {
      _data.borrowOrLend = value;
    });
  }

  Future <DateTime> _selectTime(BuildContext context) {
    return showDatePicker(
        context: context,
        initialDate: _data.date,
        firstDate: DateTime(_data.date.year - 2),
        lastDate: DateTime(_data.date.year + 2)
    );
  }

  @override
  Widget build(BuildContext context) {
    //編集データの作成
    DocumentReference _mainReference;
    _mainReference = Firestore.instance.collection('users').document(firebaseUser.uid).collection("transaction").document();
    bool deleteFlg = false;
    if (widget.document != null) {//引数で渡したデータがあるかどうか
      if(_data.user == null && _data.stuff == null) {
        _data.borrowOrLend = widget.document['borrowOrLend'];
        _data.user = widget.document['user'];
        _data.stuff = widget.document['stuff'];
        _data.date = widget.document['date'];
      }
      _mainReference = Firestore.instance.collection('users').document(firebaseUser.uid).collection("transaction").document(widget.document.documentID);
      deleteFlg = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).input_title),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                print("保存ボタンを押しました");
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();
                  _mainReference.setData(
                      {
                        'borrowOrLend': _data.borrowOrLend,
                        'user': _data.user,
                        'stuff': _data.stuff,
                        'date': _data.date
                      }
                  );
                  Navigator.pop(context);
                }
              }
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: !deleteFlg? null:() {
              print("削除ボタンを押しました");
              _mainReference.delete();
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              print("シェアボタンを押しました");
              if (_formKey.currentState.validate()) {
                _formKey.currentState.save();
                Share.share(
                    "【 " + (_data.borrowOrLend == "lend"?S.of(context).lend: S.of(context).borrow) +" 】"+ _data.stuff+
                    "\n"+S.of(context).deadline(_data.date.toString().substring(0,10)) +
                    "\n"+S.of(context).who(_data.user)+
                    "\n#"+S.of(context).title
                );
              }
            },
          )
        ],
      ),
      body: SafeArea(
        child:
        Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[

              RadioListTile(
                value: "borrow",
                groupValue: _data.borrowOrLend,
                title: Text(S.of(context).Registration_borrow),
                onChanged: (String value){
                  print("借りたをタッチしました");
                  _setLendOrRent(value);
                },
              ),
              RadioListTile(
                  value: "lend",
                  groupValue: _data.borrowOrLend,
                  title: Text(S.of(context).Registration_lend),
                  onChanged: (String value) {
                    print("貸したをタッチしました");
                    _setLendOrRent(value);
                  }
              ),

              TextFormField(
                decoration:  InputDecoration(
                  icon: const Icon(Icons.person),
                  hintText: (_data.borrowOrLend == "lend"?S.of(context).Registration_name_lend: S.of(context).Registration_name_borrow),
                  labelText: 'Name',
                ),
                onSaved: (String value) {
                  _data.user = value;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return S.of(context).validate_name;
                  }
                },
                initialValue: _data.user,
              ),

              TextFormField(
                decoration:  InputDecoration(
                  icon: const Icon(Icons.business_center),
                  hintText: (_data.borrowOrLend == "lend"?S.of(context).Registration_loan_lend: S.of(context).Registration_loan_borrow),
                  labelText: 'Loan',
                ),
                onSaved: (String value) {
                  _data.stuff = value;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return S.of(context).validate_loan;
                  }
                },
                initialValue: _data.stuff,
              ),

              Padding(
                padding: const EdgeInsets.only(top:8.0),
                child: Text(S.of(context).deadline(_data.date.toString().substring(0,10))),
              ),

              RaisedButton(
                child: Text(S.of(context).change_deadline),
                onPressed: (){
                  print("締め切り日変更をタッチしました");
                  _selectTime(context).then((time){
                    if(time != null && time != _data.date){
                      setState(() {
                        _data.date = time;
                      });
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

FirebaseUser firebaseUser;
final FirebaseAuth _auth = FirebaseAuth.instance;

class Splash extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    _getUser(context);
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child:
          FractionallySizedBox(
            child: Image.asset('res/image/note.png'),
            heightFactor: 0.4,
            widthFactor: 0.4,
          ),
      ),
    );
  }
}

void _getUser(BuildContext context) async {
  try {
    firebaseUser = await _auth.currentUser();
    if (firebaseUser == null) {
      await _auth.signInAnonymously();
      firebaseUser = await _auth.currentUser();
    }
    Navigator.pushReplacementNamed(context, "/list");
  }catch(e){
    Fluttertoast.showToast(msg: S.of(context).fail_connect_firebase);
  }
}

void showBasicDialog(BuildContext context) {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String email, password;
  if(firebaseUser.isAnonymous) {
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          AlertDialog(
            title: Text(S.of(context).login_register),
            content: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.mail),
                      labelText: 'Email',
                    ),
                    onSaved: (String value) {
                      email = value;
                    },
                    validator: (value) {
                      if (value.isEmpty) {
                        return S.of(context).validate_mail;
                      }
                    },
                  ),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.vpn_key),
                      labelText: 'Password',
                    ),
                    onSaved: (String value) {
                      password = value;
                    },
                    validator: (value) {
                      if (value.isEmpty) {
                        return S.of(context).validate_password_null_empty;
                      }
                      if(value.length<6){
                        return S.of(context).validate_password_short_length;
                      }
                    },
                  ),
                ],
              ),
            ),
            // ボタンの配置
            actions: <Widget>[
              FlatButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () {
                    Navigator.pop(context);
                  }
              ),
              FlatButton(
                  child: Text(S.of(context).register),
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      _createUser(context,email, password);
                    }
                  }
              ),
              FlatButton(
                  child: Text(S.of(context).login),
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      _signIn(context,email, password);
                    }
                  }
              ),
            ],
          ),
    );
  }else{
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          AlertDialog(
            title: Text(S.of(context).dialog),
            content: Text(S.of(context).login_user(firebaseUser.email)),
            actions: <Widget>[
              FlatButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () {
                    Navigator.pop(context);
                  }
              ),
              FlatButton(
                  child: Text(S.of(context).logout),
                  onPressed: () {
                    _auth.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
                  }
              ),
            ],
          ),
    );
  }
}

void _signIn(BuildContext context,String email, String password) async {
  try {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
  }catch(e){
    Fluttertoast.showToast(msg: S.of(context).fail_login_firebase);
  }
}

void _createUser(BuildContext context,String email, String password) async {
  try {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
    Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
  }catch(e){
    Fluttertoast.showToast(msg: S.of(context).fail_register_firebase);
  }
}