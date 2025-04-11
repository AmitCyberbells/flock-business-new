import 'package:flock/videoPlayer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({Key? key}) : super(key: key);

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  List<dynamic> tutorials = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTutorials();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(
      'access_token',
    ); // Changed from 'token' to 'access_token'
  }

  Future<void> _fetchTutorials() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          errorMessage = 'Please login to view tutorials';
        });
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://165.232.152.77/api/vendor/tutorials'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            tutorials = List<dynamic>.from(data['data']);
          });
          return;
        }
        throw Exception(data['message'] ?? 'Invalid data format');
      } else if (response.statusCode == 401) {
        // Clear token and redirect to login
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        setState(() {
          errorMessage = 'Session expired. Please login again.';
        });
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
        return;
      } else {
        throw Exception('Failed to load tutorials (${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildTutorialCard(Map<String, dynamic> tutorial) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutorial['name'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tutorial['description'] ?? 'No description',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: IconButton(
                icon: Image.asset(
  'assets/tutorials.png',
  width: 40,
  height: 40,
  fit: BoxFit.contain,
),

                  onPressed: () {
                    _playTutorial(tutorial['url'] ?? '');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

void _playTutorial(String rawUrl) {
  if (rawUrl.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No video available')),
    );
    return;
  }

  // If backend returns: http://IP/storage/https://actual-url.com/video.mp4
  String videoUrl;
  if (rawUrl.contains('https://')) {
    final split = rawUrl.split('https://');
    videoUrl = 'https://${split.last}';
  } else {
    videoUrl = rawUrl;
  }

  debugPrint('Final video URL: $videoUrl');

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color.fromRGBO(255, 130, 16, 1.0),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Tutorials",
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
            Expanded(
              child:
                  isLoading
                      ? Container(
                        color: Colors.white.withOpacity(0.19),
                        child: Center(
                          child: Image.asset(
                            'assets/Bird_Full_Eye_Blinking.gif',
                            width: 100, // Adjust size as needed
                            height: 100,
                          ),
                        ),
                      )
                      : errorMessage.isNotEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                            if (!errorMessage.contains('login'))
                              const SizedBox(height: 16),
                            if (!errorMessage.contains('login'))
                              ElevatedButton(
                                onPressed: _fetchTutorials,
                                child: const Text('Retry'),
                              ),
                          ],
                        ),
                      )
                      : tutorials.isEmpty
                      ? const Center(child: Text('No tutorials available'))
                      : ListView.builder(
                        itemCount: tutorials.length,
                        itemBuilder: (context, index) {
                          final tutorial =
                              tutorials[index] as Map<String, dynamic>;
                          return _buildTutorialCard(tutorial);
                        },
                      ),
            ),
            const SizedBox(height: 16),
          Padding(
  padding: const EdgeInsets.all(16),
  child: SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: () async {
        final url = Uri.parse('https://getflock.io/business/');
        debugPrint('Attempting to launch URL: $url');
        try {
          final launched = await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
          debugPrint('Launch result: $launched');
          if (!launched) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open the link')),
              );
            }
          }
        } catch (e) {
          debugPrint('Error launching URL: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error launching URL: $e')),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        "Learn More",
        style: TextStyle(color: Colors.white, fontSize: 16),
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
