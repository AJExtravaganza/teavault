import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teavault/models/tea.dart';
import 'package:teavault/models/tea_collection.dart';
import 'package:teavault/models/tea_producer.dart';
import 'package:teavault/models/tea_producer_collection.dart';
import 'package:teavault/models/tea_production.dart';
import 'package:teavault/models/tea_production_collection.dart';

class AddNewTeaToStash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Tea to Stash'),
      ),
      body: StashAddNewTeaForm(),
    );
  }
}

class CommonOrCustomNewTeaSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Existing or Custom Production?'),
        ),
        body: Column(children: <Widget>[
          RaisedButton(
            child: Text('Choose Existing Production'),
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => StashAddNewTeaForm(userDefined: false)));
            },
          ),
          RaisedButton(
              child: Text('Define Custom Production'),
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => StashAddNewTeaForm(userDefined: true)));
              })
        ]));
  }
}

class StashAddNewTeaForm extends StatefulWidget {
  final bool userDefined;
  
  StashAddNewTeaForm({this.userDefined: false});
  
  @override
  StashAddNewTeaFormState createState() => new StashAddNewTeaFormState(userDefined: this.userDefined);
}

class StashAddNewTeaFormState extends State<StashAddNewTeaForm> {
  final bool userDefined; 
  final _formKey = GlobalKey<FormState>();

  TeaProducer _producer;
  TeaProduction _production;
  int _quantity;
  
  StashAddNewTeaFormState({this.userDefined: false});

  TeaProducer get producer => this._producer;
  
  set producer(TeaProducer producer) {
    setState(() {
      setState(() {
        _producer = producer;
        if (_production != null && _production.producer != _producer) {
          _production = null;
        }
      });
    });
  }
  
  TeaProduction get production => this._production;
  
  set production (TeaProduction production) {
    this._producer = production.producer;
    this._production = production;
  }

  //  Necessary for TextFormField select-all-on-focus
  static final _quantityInitialValue = '1';
  final _quantityFieldController = TextEditingController(text: _quantityInitialValue);
  FocusNode _quantityFieldFocusNode;

  @override
  initState() {
    super.initState();
    _quantityFieldFocusNode = FocusNode();

    //  Implements TextFormField select-all-on-focus
    _quantityFieldFocusNode.addListener(() {
      if (_quantityFieldFocusNode.hasFocus) {
        _quantityFieldController.selection = TextSelection(baseOffset: 0, extentOffset: _quantityInitialValue.length);
      }
    });
  }

  @override
  dispose() {
    _quantityFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: new ListView(children: <Widget>[
        this.userDefined ? Text('Placeholder') : ProducerDropdown(this),
        this.userDefined ? Text('Placeholder'): ProductionDropdown(this),
        TextFormField(
            decoration: InputDecoration(labelText: 'Enter Quantity', hintText: 'Quantity'),
            validator: (value) {
              if (int.tryParse(value) == null) {
                return 'Please enter a valid quantity';
              }
              return null;
            },
            focusNode: _quantityFieldFocusNode,
            controller: _quantityFieldController,
            onSaved: (value) {
              setState(() {
                _quantity = int.parse(value);
              });
            },
            keyboardType: TextInputType.number),
        RaisedButton(
            color: Colors.blue,
            textColor: Colors.white,
            child: new Text('Add to Stash'),
            onPressed: () async {
              await addNewTeaFormSubmit();
            })
      ]),
    );
  }

  void addNewTeaFormSubmit() async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      FocusScope.of(context).unfocus(); //Dismiss the keyboard
      Scaffold.of(context).showSnackBar(SnackBar(content: Text('Adding new tea to stash...')));
      await teasCollection.add(Tea(_quantity, _production.id));
      Navigator.pop(context);
    }
  }
}

class ProducerDropdown extends StatelessWidget {
  final StashAddNewTeaFormState state;

  ProducerDropdown(this.state);

  @override
  Widget build(BuildContext context,) {
    final listItems = teaProducersCollection.items
        .map((producer) => DropdownMenuItem(
              child: Text(producer.asString()),
              value: producer,
            ))
        .toList();
    return DropdownButtonFormField(
      hint: Text('Select Producer'),
      items: listItems,
      value: state.producer,
      onChanged: (value) {state.producer = value;},
      isExpanded: true,
    );
  }
}

class ProductionDropdown extends StatelessWidget {
  final StashAddNewTeaFormState state;
  
  ProductionDropdown(this.state);

  @override
  Widget build(BuildContext context) {
    final listItems = teaProductionsCollection.items
        .map((production) => DropdownMenuItem(
      child: Text(production.asString()),
      value: production,
    ))
        .where((dropdownListItem) => (state.producer == null || dropdownListItem.value.producer == state.producer))
        .toList();
    return Consumer<TeaProductionCollectionModel>(
      builder: (context, productions, child) => DropdownButtonFormField(
          hint: Text('Select Production'),
          value: state.production,
          items: listItems,
          onChanged: (value) {
            state.production = value;
            state.producer = value.producer;
          },
          isExpanded: true),
    );
  }
}