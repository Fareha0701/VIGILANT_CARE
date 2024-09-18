import 'package:flutter/material.dart';
import 'package:vigilant_care/utils/quotes.dart';
import 'package:flutter/cupertino.dart';

class CustomAppBar extends StatelessWidget{
  //const CustomAppBar({super.key});
 final Function? onTap;
 final int? quoteIndex;
  CustomAppBar({this.onTap, this.quoteIndex});

  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: () {
        if(onTap!= null){
          onTap!();
        }
      },
      child: Container(
        child:Text(
          quotess[quoteIndex!],
          //textAlign: TextAlign.center,
          style:TextStyle(fontSize:22,fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}