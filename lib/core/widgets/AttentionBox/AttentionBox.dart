import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DeliveryScreen(),
  ));
}

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Delivery Outcome")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const PretermDialog();
              },
            );
          },
          child: const Text("Show Dialog"),
        ),
      ),
    );
  }
}

class PretermDialog extends StatelessWidget {
  const PretermDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // To make the card compact
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. THE HEADER (Pink Background)
            Container(
              padding: const EdgeInsets.only(top: 20, bottom: 20, left: 24, right: 24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFCDD2), // Light Pink/Red color
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4.0),
                  topRight: Radius.circular(4.0),
                ),
              ),
              child: const Text(
                "Attention !",
                style: TextStyle(
                  color: Color(0xFFD32F2F), // Darker Red for text
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // 2. THE BODY (White Background)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              color: Colors.white,
              child: const Text(
                "It is Preterm delivery.",
                style: TextStyle(
                  color: Color(0xFFD32F2F), // Matches header text color
                  fontSize: 16.0,
                ),
              ),
            ),

            // 3. THE FOOTER (OKAY Button)
            Container(
              padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  "OKAY",
                  style: TextStyle(
                    color: Color(0xFFD32F2F), // Red text for button
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}