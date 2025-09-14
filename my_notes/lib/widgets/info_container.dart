import 'package:flutter/material.dart';

class InfoContainer extends StatelessWidget {
  const InfoContainer({
    super.key,
    required this.size,
    this.color = Colors.grey,
    this.message = 'No notes available. Please add some notes.',
    this.textColor = Colors.grey,
    this.onClose,
  });

  final Size size;
  final Color color;
  final String message;
  final Color textColor;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      margin: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: onClose != null
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(fontSize: 16, color: textColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close, color: textColor, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            )
          : Text(
              message,
              style: TextStyle(fontSize: 16, color: textColor),
              textAlign: TextAlign.center,
            ),
    );
  }
}