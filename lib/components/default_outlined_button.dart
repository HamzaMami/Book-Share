import 'package:flutter/material.dart';


class DefaultOutlinedButton extends StatefulWidget {
  final Color ContainerColor ;
  final String text ;
  final Function pressed;
  final bool loading ;
  final double width;
  final double raduis;
  DefaultOutlinedButton({super.key,
    this.ContainerColor = Colors.blueAccent,
    required this.text,
    required this.pressed,
    this.loading = false ,
    this.width = double.infinity,
    this.raduis = 6,


  });


  @override
  State<DefaultOutlinedButton> createState() => _DefaultOutlinedButtonState();
}

class _DefaultOutlinedButtonState extends State<DefaultOutlinedButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.raduis),
        border: Border.all(
          color: widget.ContainerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.ContainerColor.withOpacity(0.1),
            spreadRadius: -10,
            blurRadius: 40,
            offset: Offset(0, 25), // changes position of shadow
          ),
        ],
      ),

      child: TextButton(onPressed: (){
        widget.pressed();
      },
        child: widget.loading ? CircularProgressIndicator(
          color: widget.ContainerColor,
        ) :Text(widget.text,
          style: TextStyle(
              color: Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.w600
          ),),
      ),
    );
  }
}