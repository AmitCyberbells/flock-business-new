import 'package:flutter/material.dart';

class AppConstants {
  // Reusable InputDecoration for TextFields
  static final InputDecoration textFieldDecoration = InputDecoration(
    hintStyle: TextStyle(color: Colors.grey),
    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),

    // Default border
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8.0)), // Rounded corners
      borderSide: BorderSide(
        color: Colors.grey,
        width: 1,
      ),
    ),

    // Border when focused
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
      borderSide: BorderSide(
        color: Color.fromRGBO(255, 106, 16, 1),
        width: 1,
      ),
    ),

    // Border when there's an error
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
      borderSide: BorderSide(color: Colors.red, width: 2),
    ),

    // Border when focused and error occurs
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
      borderSide: BorderSide(color: Colors.red, width: 2),
    ),
  );

  // BoxDecoration with BoxShadow to be used in a Container wrapping the TextField
  static final BoxDecoration textFieldBoxDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(8.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1), // Shadow color
        spreadRadius: 1, 
        blurRadius: 5, 
        offset: Offset(0, 3), // Shadow position
      ),
    ],
  );


  // button 1

   static final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: const Color.fromRGBO(255, 130, 16, 1), // Button color
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15), // Rounded corners
    ),
  );

    // Reusable Full-Width Button
  static Widget fullWidthButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity, // Makes the button take full width
      child: ElevatedButton(
        style: elevatedButtonStyle,
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

}
