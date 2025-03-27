import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'addStaffMember.dart'; // Ensure this path is correct

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({Key? key}) : super(key: key);

  @override
  _StaffManagementScreenState createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  /// List of staff members.
  List<Map<String, String>> staffMembers = [];
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchStaff();
  }

  /// Load the access token from SharedPreferences and fetch staff members.
  Future<void> _loadTokenAndFetchStaff() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('access_token');
    if (_authToken == null) {
      debugPrint("No token found in SharedPreferences.");
      return;
    }
    await fetchStaffMembers();
  }

  /// Fetch staff members from the API.
  Future<void> fetchStaffMembers() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'http://165.232.152.77/mobi/api/vendor/teams',
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
          final List<Map<String, String>> loadedStaff = rawList
              .map<Map<String, String>>((item) {
                return {
                  "id": item["id"]?.toString() ?? '',
                  "firstName": item["first_name"] ?? '',
                  "lastName": item["last_name"] ?? '',
                  "email": item["email"] ?? '',
                  "phone": item["contact"] ?? '',
                  "createdAt": item["created_at"] ?? '',
                };
              })
              .toList();

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
    }
  }

  /// Fetch a single team member's details by ID.
  Future<Map<String, String>?> fetchTeamMember(String memberId) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'http://165.232.152.77/mobi/api/vendor/teams/$memberId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_authToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          return {
            "id": data["id"]?.toString() ?? '',
            "firstName": data["first_name"] ?? '',
            "lastName": data["last_name"] ?? '',
            "email": data["email"] ?? '',
            "phone": data["contact"] ?? '',
            "venue": data["venue_ids"]?.join(',') ?? '',
            "permission": data["permission_ids"]?.join(',') ?? '',
          };
        } else {
          debugPrint("No 'data' field found in the response for team member.");
          return null;
        }
      } else {
        debugPrint("Request failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Exception while fetching team member: $e");
      return null;
    }
  }

  /// Navigate to AddMemberScreen and refresh the list upon success.
  Future<void> addOrUpdateMember({Map<String, String>? member, int? index}) async {
    Map<String, String>? memberData = member;

    // If editing, fetch the latest member data from the API
    if (member != null && member["id"] != null) {
      memberData = await fetchTeamMember(member["id"]!);
      if (memberData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch member details.")),
        );
        return;
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemberScreen(existingMember: memberData),
      ),
    );

    // If the AddMemberScreen returned a successful result, refetch the list.
    if (result != null && result == true) {
      await fetchStaffMembers();
    }
  }

  /// Delete a member from the server and locally.
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
        'http://165.232.152.77/mobi/api/vendor/teams/$memberId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_authToken',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500, // Accept status codes less than 500
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
        debugPrint("Delete request failed with status: ${response.statusCode}, message: $errorMessage");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete member: $errorMessage")),
        );
      }
    } catch (e) {
      debugPrint("Exception while deleting staff member: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting member: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top bar with back arrow, title, and "Add Member" button.
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Icon(Icons.arrow_back, color: Colors.black),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                "Staff Members",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                addOrUpdateMember();
                              },
                              child: Row(
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
                          ],
                        ),
                      ),
                      // Display staff members or a "No Member Found" message.
                      staffMembers.isEmpty
                          ? Center(
                              child: Text(
                                "No Member Found...",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
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
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
                                      member["createdAt"] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Edit icon.
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.black, size: 20),
                                          onPressed: () {
                                            addOrUpdateMember(member: member, index: index);
                                          },
                                        ),
                                        // Delete icon.
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.orange, size: 20),
                                          onPressed: () {
                                            deleteMember(index);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      // Bottom bubble for empty list.
                      staffMembers.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text(
                                      "No record found!",
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}