import 'dart:convert';
import 'package:flock/editSatffMember.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'addStaffMember.dart';
import 'package:intl/intl.dart'; // Add this import
// <-- New screen for editing

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({Key? key}) : super(key: key);

  @override
  _StaffManagementScreenState createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<Map<String, String>> staffMembers = [];
  String? _authToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchStaff();
  }

  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      return 'Not available';
    }
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return dateTimeStr; // Return original string if parsing fails
    }
  }

  Future<void> _loadTokenAndFetchStaff() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('access_token');
    if (_authToken == null) {
      debugPrint("No token found in SharedPreferences.");
      return;
    }
    await fetchStaffMembers();
  }

  Future<void> fetchStaffMembers() async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final response = await dio.get(
        'http://165.232.152.77/api/vendor/teams',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_authToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['data'] != null) {
          final List<dynamic> rawList = data['data'];
          final List<Map<String, String>> loadedStaff =
              rawList.map<Map<String, String>>((item) {
                return {
                  "id": item["id"]?.toString() ?? '',
                  "firstName": item["first_name"] ?? '',
                  "lastName": item["last_name"] ?? '',
                  "email": item["email"] ?? '',
                  "phone": item["contact"] ?? '',
                  "createdAt": item["created_at"] ?? '',
                };
              }).toList();

          setState(() {
            staffMembers = loadedStaff;
          });
        } else {
          debugPrint("No 'data' field found in the response.");
        }
      } else {
        debugPrint("Request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Exception while fetching staff members: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Navigate to AddMemberScreen and refresh on success
  Future<void> addMember() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMemberScreen()),
    );
    if (result == true) {
      await fetchStaffMembers();
    }
  }

  /// Navigate to EditStaffMemberScreen, passing in the staff ID, then refresh on success
  Future<void> editMember(String memberId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStaffMemberScreen(staffId: memberId),
      ),
    );
    if (result == true) {
      await fetchStaffMembers();
    }
  }

  /// Delete a member
  Future<void> deleteMember(int index) async {
    final memberId = staffMembers[index]["id"];
    if (memberId == null || memberId.isEmpty) {
      debugPrint("Cannot delete member: ID is missing.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot delete member: ID is missing.")),
      );
      return;
    }

    try {
      final dio = Dio();
      final response = await dio.delete(
        'http://165.232.152.77/api/vendor/teams/$memberId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_authToken',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          staffMembers.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Member deleted successfully!")),
        );
      } else {
        final errorMessage = response.data['message'] ?? 'Unknown error';
        debugPrint(
          "Delete request failed with status: ${response.statusCode}, message: $errorMessage",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete member: $errorMessage")),
        );
      }
    } catch (e) {
      debugPrint("Exception while deleting staff member: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting member: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top bar
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => Navigator.of(context).pop(),
                                   child: Image.asset(
    'assets/back_updated.png',
    height: 40,
    width: 34,
    fit: BoxFit.contain,
    // color: const Color.fromRGBO(255, 130, 16, 1.0), // Orange tint
  ),
                                ),
                                const Expanded(
                                  child: Center(
                                    child: Text(
                                      "Staff Members",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          InkWell(
                            onTap: addMember,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 10.0,
                              ), // <-- Adjust the value as needed
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: const [
                                  Icon(Icons.add_circle, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text(
                                    "Add Member",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Loading indicator
                          if (_isLoading)
                                    Stack(
  children: [
    // Semi-transparent dark overlay
    Container(
      color: Colors.black.withOpacity(0.14), // Dark overlay
    ),

    // Your original container with white tint and loader
    Container(
      color: Colors.white10,
      child: Center(
        child: Image.asset(
          'assets/Bird_Full_Eye_Blinking.gif',
          width: 100, // Adjust size as needed
          height: 100,
        ),
      ),
    ),
  ],
),

                          // Staff list or empty state
                          staffMembers.isEmpty && !_isLoading
                              ? const Padding(
                                padding: EdgeInsets.only(top: 16.0),
                                child: Text(
                                  "No Member Found...",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: staffMembers.length,
                                itemBuilder: (context, index) {
                                  final member = staffMembers[index];
                                  return Card(
                                    color: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        '${member["firstName"]} ${member["lastName"]}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        formatDateTime(member["createdAt"]),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Edit
                                          IconButton(
                                            icon: Image.asset(
                                              'assets/edit.png', // Path to your custom image
                                              width:
                                                  20, // Match the size of the previous icon
                                              height: 20,
                                              color:
                                                  Colors
                                                      .black, // Optional: tint the image like the original
                                            ),
                                            onPressed: () {
                                              final id = member["id"] ?? "";
                                              if (id.isNotEmpty) {
                                                editMember(id);
                                              }
                                            },
                                          ),
                                          // Delete
                                          IconButton(
  icon: Image.asset(
    'assets/closebtn.png', // Path to your custom image
    width: 20, // Match the size of the previous icon
    height: 20,
    // color: const Color.fromRGBO(255, 130, 16, 1), // Optional: tint the image like the original
  ),
  onPressed: () {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this member?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                deleteMember(index);
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  },
),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
