import 'package:flutter/material.dart';

//import 'package:vigilant_care/register_child.dart';
//Color primaryColor =  const Color.fromARGB(1, 12, 64, 92);
void goTo(BuildContext context, Widget nextScreen) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => nextScreen,
    ),
  );
}

dialogueBox(BuildContext context, String text){
  showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      title:Text(text),
    ),
  );
}

Widget progressIndicator(BuildContext context){
  return Center(
      child: CircularProgressIndicator(
    backgroundColor:Color.fromARGB(1, 12, 64, 92) ,
    color: Color.fromARGB(255, 3, 116, 138) ,
    strokeWidth: 7,
  ));
}