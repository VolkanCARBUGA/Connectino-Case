import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double width;
  final double height;
  final bool isLoading;
  const ButtonWidget({
    super.key,
    required this.text,
    this.onPressed,
    required this.color,
    required this.textColor,
    required this.width,
    required this.height,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
        padding: EdgeInsets.all(size.width * 0.02),
        decoration: BoxDecoration(
          color: isLoading ? color.withValues(alpha: 0.6) : color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: isLoading 
            ? CircularProgressIndicator(color: textColor)
            : Text(
                text,
                style: TextStyle(fontSize: 16, color: textColor),
                textAlign: TextAlign.center,
              ),
        ),
      ),
    );
  }
}
