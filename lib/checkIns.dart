import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class CheckInsScreen extends StatefulWidget {
  const CheckInsScreen({Key? key}) : super(key: key);

  @override
  State<CheckInsScreen> createState() => _CheckInsScreenState();
}

class _CheckInsScreenState extends State<CheckInsScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _showDatePickerDialog() async {
    DateTime tempPickedDate = _selectedDate;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Select date"),
          content: SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: tempPickedDate,
              minimumYear: 2000,
              maximumYear: 2100,
              onDateTimeChanged: (DateTime newDate) {
                tempPickedDate = newDate;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDate = tempPickedDate;
                });
                Navigator.pop(context);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  String get dateLabel {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    return isToday
        ? "Today"
        : DateFormat("d MMM yyyy").format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Check Ins"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _showDatePickerDialog,
            child: Row(
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(color: Colors.white),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: Text(
            "Check Ins Content Here",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}



