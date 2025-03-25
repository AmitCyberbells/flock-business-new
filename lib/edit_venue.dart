import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Design {
  static const Color white = Colors.white;
  static const Color darkPink = Color(0xFFD81B60);
  static const Color lightGrey = Colors.grey;
  static const Color lightBlue = Color(0xFF2196F3);
  static const Color primaryColorOrange = Colors.orange;
  static const double font15 = 15;
  static const double font17 = 17;
  static const double font20 = 20;
}

class Server {
  static const String updateVenue = 'http://165.232.152.77/mobi/api/vendor/venues';
}

class EditVenueScreen extends StatefulWidget {
  final Map<String, dynamic> venueData;
  final String categoryId;

  const EditVenueScreen({
    Key? key,
    required this.venueData,
    required this.categoryId,
  }) : super(key: key);

  @override
  State<EditVenueScreen> createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends State<EditVenueScreen> {
  late TextEditingController _nameController;
  late TextEditingController _suburbController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _featherPointsController;
  late TextEditingController _venuePointsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.venueData['name']?.toString() ?? '');
    _suburbController = TextEditingController(text: widget.venueData['suburb']?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.venueData['description']?.toString() ?? '');
    _locationController = TextEditingController(text: widget.venueData['location']?.toString() ?? '');
    _latController = TextEditingController(text: widget.venueData['lat']?.toString() ?? '');
    _lonController = TextEditingController(text: widget.venueData['lon']?.toString() ?? '');
    _featherPointsController = TextEditingController(text: widget.venueData['feather_points']?.toString() ?? '');
    _venuePointsController = TextEditingController(text: widget.venueData['venue_points']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _suburbController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _featherPointsController.dispose();
    _venuePointsController.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Future<void> _updateVenue() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _latController.text.isEmpty ||
        _lonController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please fill in all required fields',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      if (token.isEmpty) throw Exception('No authentication token');

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        'id': widget.venueData['id']?.toString(),
        'name': _nameController.text,
        'suburb': _suburbController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'lat': _latController.text,
        'lon': _lonController.text,
        'feather_points': _featherPointsController.text,
        'venue_points': _venuePointsController.text,
        'category_id': widget.categoryId,
      });

      final response = await http.post(
        Uri.parse('${Server.updateVenue}/${widget.venueData['id']}'),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Create a properly typed map for the updated venue
        final updatedVenue = Map<String, dynamic>.from(widget.venueData)
          ..addAll({
            'name': _nameController.text,
            'suburb': _suburbController.text,
            'description': _descriptionController.text,
            'location': _locationController.text,
            'lat': _latController.text,
            'lon': _lonController.text,
            'feather_points': _featherPointsController.text,
            'venue_points': _venuePointsController.text,
            'category_id': widget.categoryId,
          });

        Navigator.pop(context, updatedVenue);
        Fluttertoast.showToast(msg: 'Venue updated successfully');
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update venue');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Venue'),
        backgroundColor: Design.primaryColorOrange,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Venue ID: ${widget.venueData['id']}',
                  style: const TextStyle(
                    fontSize: Design.font15,
                    color: Design.lightGrey,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Venue Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _suburbController,
                  decoration: const InputDecoration(
                    labelText: 'Suburb',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _lonController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _featherPointsController,
                        decoration: const InputDecoration(
                          labelText: 'Feather Points',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _venuePointsController,
                        decoration: const InputDecoration(
                          labelText: 'Venue Points',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateVenue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Design.primaryColorOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: Design.font17),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}