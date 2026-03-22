import 'package:flutter/material.dart';


class DefaultButton extends StatefulWidget {
  final Color ContainerColor ;
  final String text ;
  final Function pressed;
  final bool loading ;
  final bool activated;
  double width;
  DefaultButton({super.key,
    this.ContainerColor = Colors.blueAccent,
    required this.text,
    required this.pressed,
    this.loading = false,
    required this.activated,
    this.width = double.infinity});


  @override
  State<DefaultButton> createState() => _DefaultButtonState();
}

class _DefaultButtonState extends State<DefaultButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: widget.width,
      decoration: BoxDecoration(
        color: widget.activated == true ? widget.ContainerColor : Color(0xffECECEC),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color:widget.activated == true ? widget.ContainerColor.withOpacity(0.1) : Color(0xffECECEC).withOpacity(0.2) ,
            spreadRadius: -10,
            blurRadius: 40,
            offset: Offset(0, 25), // changes position of shadow
          ),
        ],
      ),

      child: TextButton(onPressed: (){
        if(widget.activated == true){
          widget.pressed();
        }

      },
        child: widget.loading ? CircularProgressIndicator(
          color: Colors.white,
        ) :Text(widget.text,
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600
          ), ),
      ),
    );
  }
}