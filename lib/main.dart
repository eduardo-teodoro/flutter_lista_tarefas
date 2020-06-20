import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();

  List _toDoList = [];

  //ultimo map removido
  Map<String, dynamic> _lastRemoved;

  //ultima posição removida
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    //ler os dados do arquivo ao abrir o app
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  //Função para adicionar itens na lista

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      //título da tarefa
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      //ao adicionar um elemento na lista chama a função para salvar no arquivo
      _saveData();
    });
  }
  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds:1));

    setState(() {
      //a>b =1 a=b = 0 a<b -1
      _toDoList.sort((a,b){
        if(a["ok"] && !b["ok"])return 1;
        else if(!a["ok"] && b["ok"])return -1;
        else return 0;
      });
      _saveData();
    });

return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          //containeir para dar os espaços nas laterais
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                //monta a lista no tamanho informado
                itemCount: _toDoList.length,
                //index é o elemento da lista que está sendo desenhado
                itemBuilder: buildItem),
          ))
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    //Dismissible serve para arrastar o item na tela
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(0.0, 1.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      //direção do deslize
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      //função chamada assim que um intem da lista for arrastado para direita
      onDismissed: (direction) {
        setState(() {
          //inserindo na variável _lastRemoved o item arrastado
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);

          _saveData();
          //snackbar para mostrar ao usuário para Desfazer
          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            //ação na snackbar
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          //mostrando snackbar
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

//importar a biblioteca path provider
  //inserir no pubspec.yaml depois cupertino_icons
  //path_provider: "^0.4.1"

//função que retorna o arquivo para salvar
  Future<File> _getFile() async {
    //diretorio para gravar aquivo conforme plataorma IOS ou Android
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

//função para salvar os dados
  Future<File> _saveData() async {
    //transformando lista em um Json
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  //Função para obter os dados

  Future<String> _readData() async {
    try {
      //tentar pegar o arquivo
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
