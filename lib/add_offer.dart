import 'package:flutter/material.dart';

class AddOfferScreen extends StatefulWidget {
  const AddOfferScreen({Key? key}) : super(key: key);

  @override
  State<AddOfferScreen> createState() => _AddOfferScreenState();
}

class _AddOfferScreenState extends State<AddOfferScreen> {
  // Text controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Example list of venues
  final List<String> _venues = ["Select Venue", "Venue 1", "Venue 2", "Venue 3"];
  String _selectedVenue = "Select Venue";

  // Redeem type checkboxes
  bool _venuePoints = false;
  bool _appPoints = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with back arrow and title
      appBar: AppBar(
        title: const Text("Add New Offer"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      // Body: scrollable content
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Enter Details"
            const Text(
              "Enter Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Title of Offer
            const Text(
              "Title of Offer",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "Enter Title of Offer",
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Venue dropdown
            const Text(
              "Venue",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedVenue,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _venues.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedVenue = newValue ?? _selectedVenue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Redeem Type
            const Text(
              "Redeem Type",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Venue Points
                Expanded(
                  child: CheckboxListTile(
                    title: const Text("Venue Points"),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _venuePoints,
                    onChanged: (bool? value) {
                      setState(() {
                        _venuePoints = value ?? false;
                      });
                    },
                  ),
                ),
                // App Points
                Expanded(
                  child: CheckboxListTile(
                    title: const Text("App Points"),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _appPoints,
                    onChanged: (bool? value) {
                      setState(() {
                        _appPoints = value ?? false;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              "Description",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "",
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Upload Pictures
            const Text(
              "Upload Pictures",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            // Camera icon box
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 30),
                onPressed: () {
                  // Handle picking images from camera or gallery
                },
              ),
            ),
            const SizedBox(height: 80), // Extra space for the bottom button
          ],
        ),
      ),

      // Bottom "Continue" button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Handle form submission
            },
            child: const Text(
              "Continue",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}



