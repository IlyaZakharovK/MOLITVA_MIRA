import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  final String text;
  final bool needs;
  const Label(this.text, {this.needs = true});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 6),
        child: Row(
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (needs)...{
              Text(
                " *",
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red
                ),
              )
            }
          ],
        ),
      ),
    );
  }
}