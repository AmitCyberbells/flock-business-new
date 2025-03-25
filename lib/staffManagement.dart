import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'addStaffMember.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({Key? key}) : super(key: key);

  @override
  _StaffManagementScreenState createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<Map<String, String>> staffMembers = [];

  @override
  void initState() {
    super.initState();
    loadStaffMembers();
  }

  // Reload staff members every time the widget is reinserted in the tree.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadStaffMembers();
  }

  Future<void> loadStaffMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final staffJson = prefs.getString('staffMembers') ?? '[]';
    final List<dynamic> staffList = json.decode(staffJson);
    setState(() {
      staffMembers = List<Map<String, String>>.from(staffList);
    });
  }

  Future<void> saveStaffMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final String staffJson = json.encode(staffMembers);
    await prefs.setString('staffMembers', staffJson);
  }

  Future<void> addOrUpdateMember({Map<String, String>? member, int? index}) async {
    // Navigate to AddMemberScreen and wait for result.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemberScreen(
          existingMember: member,
        ),
      ),
    );
    if (result != null && result is Map<String, String>) {
      setState(() {
        if (index != null) {
          // Update the existing member.
          staffMembers[index] = result;
        } else {
          // Add new member.
          staffMembers.add(result);
        }
      });
      await saveStaffMembers();
    }
  }

  Future<void> deleteMember(int index) async {
    setState(() {
      staffMembers.removeAt(index);
    });
    await saveStaffMembers();
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
                    // If there are members, space the list and bottom evenly; otherwise, show a message.
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
                      // Middle area: display staff members list or a "No Member Found..." message.
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
                                  child: ListTile(
                                    title: Text(
                                      '${member["firstName"]} ${member["lastName"]}',
                                    ),
                                    subtitle: Text(
                                      '${member["email"]}\n${member["phone"]}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Edit (pencil) icon.
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            addOrUpdateMember(member: member, index: index);
                                          },
                                        ),
                                        // Delete icon.
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
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
                      // Bottom bubble: "No record found!" message if list is empty.
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
