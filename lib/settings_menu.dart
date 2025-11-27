import 'package:flutter/material.dart';
import 'db_model.dart';

class SettingsMenu extends StatefulWidget {
  final String calorieValue;
  final String proteinValue;
  final String fatValue;
  final String carbsValue;

  const SettingsMenu({super.key,required this.calorieValue,required this.proteinValue,required this.fatValue,required this.carbsValue});

  @override
  State<SettingsMenu> createState() => SettingsMenuState();
}

class SettingsMenuState extends State<SettingsMenu> {
  final _formKey = GlobalKey<FormState>();

  final _calorieController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _calorieController.text = widget.calorieValue;
    _proteinController.text = widget.proteinValue;
    _fatController.text = widget.fatValue;
    _carbsController.text = widget.carbsValue;

    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children:[
                Text('Calorie Goal: ', style:TextStyle(fontSize:20)),
                SizedBox(
                  width:200,
                  child: TextFormField(
                    controller: _calorieController,
                    decoration: InputDecoration(border:OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! < 0.0) {
                        return('Please enter a valid calorie goal');
                      }
                      return null;
                    }
                  )
                ),
                SizedBox(width:16)
              ]
            ),
            SizedBox(
                height:15
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children:[
                Text('Protein Goal (g): ', style:TextStyle(fontSize:20)),
                SizedBox(
                  width:200,
                  child: TextFormField(
                    controller: _proteinController,
                    decoration: InputDecoration(border:OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! < 0.0) {
                        return('Please enter a valid protein goal');
                      }
                      return null;
                    }
                  ),
                ),
                SizedBox(width:16)
              ]
            ),
            SizedBox(
                height:15
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children:[
                Text('Carb Goal (g): ', style:TextStyle(fontSize:20)),
                SizedBox(
                  width:200,
                  child: TextFormField(
                    controller: _carbsController,
                    decoration: InputDecoration(border:OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! < 0.0) {
                        return('Please enter a valid carb goal');
                      }
                      return null;
                    }
                  ),
                ),
                SizedBox(width:16)
              ]
            ),
            SizedBox(
                height:15
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children:[
                Text('Fat Goal (g): ', style:TextStyle(fontSize:20)),
                SizedBox(
                  width:200,
                  child: TextFormField(
                    controller: _fatController,
                    decoration: InputDecoration(border:OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! < 0.0) {
                        return('Please enter a valid fat goal');
                      }
                      return null;
                    }
                  ),
                ),
                SizedBox(width:16)
              ]
            ),
            SizedBox(
              height:10
            ),
            FilledButton(
              child:Text('Update'),
              onPressed: () async {
                DBModel db = DBModel.db;
                db.updateUser({
                  'uid':1, // Hard coded for a single user
                  'dailyCalorieLimit':_calorieController.text,
                  'dailyProteinLimit':_proteinController.text,
                  'dailyFatLimit':_fatController.text,
                  'dailyCarbsLimit':_carbsController.text
                });
              },

            )
          ]
        )
      ),
    );
  }

}