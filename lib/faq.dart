import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FaqScreen extends StatefulWidget {
  @override
  _FaqScreenState createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  bool isLoading = true;
  int activeFaq = -1;
  List<dynamic> faqList = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchFaqs();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchFaqs() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    String? token = await getToken();
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final url = Uri.parse('http://165.232.152.77/mobi/api/vendor/faqs');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            faqList = List.from(data['data']);
          });
        } else {
          setState(() {
            errorMessage = 'No FAQs found.';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Error ${response.statusCode}: Unable to fetch FAQs';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void toggleFaq(int id) {
    setState(() {
      activeFaq = activeFaq == id ? -1 : id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('FAQs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Questions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            SizedBox(height: 15),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red, fontSize: 16)))
                      : faqList.isNotEmpty
                          ? ListView.builder(
                              itemCount: faqList.length,
                              itemBuilder: (context, index) {
                                final item = faqList[index];
                                return Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () => toggleFaq(item['id']),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item['question'],
                                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            Icon(
                                              activeFaq == item['id']
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (activeFaq == item['id'])
                                      Container(
                                        padding: EdgeInsets.all(15),
                                        margin: EdgeInsets.only(top: 5, bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          item['answer'],
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            )
                          : Center(child: Text('No record found!', style: TextStyle(fontSize: 16))),
            ),
          ],
        ),
      ),
    );
  }
}