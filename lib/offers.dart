import 'dart:convert';
import 'package:flock/offer_details.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({Key? key}) : super(key: key);

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  bool isLoading = true;
  String errorMessage = '';
  List<dynamic> offersList = [];

  @override
  void initState() {
    super.initState();
    fetchOffers();
  }

  // Fetch the token saved after login
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // GET /offers: Fetch offer details from the API
  Future<void> fetchOffers() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    String? token = await getToken();
    if (token == null || token.isEmpty) {
      // If no token, navigate to login
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final url = Uri.parse('http://165.232.152.77/mobi/api/vendor/offers');

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
            offersList = List.from(data['data']);
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'No offers found.';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Error ${response.statusCode}: Unable to fetch offers.';
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

  // DELETE /offers/{id}: Remove an offer
  Future<void> removeOffer(int offerId) async {
    String? token = await getToken();
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final url = Uri.parse('http://165.232.152.77/mobi/api/vendor/offers/$offerId');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Remove from local list to update UI immediately
        setState(() {
          offersList.removeWhere((offer) => offer['id'] == offerId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove offer. Code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
              : offersList.isEmpty
                  ? const Center(child: Text('No offers found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: offersList.length,
                      itemBuilder: (context, index) {
                        final offer = offersList[index];
                        final int offerId = offer['id'];
                        final String discount = offer['name']?.toString() ?? '0';
                        final String desc = offer['description'] ?? '';
                        final String venueName = offer['venue']?['name']?.toString() ?? 'No Venue';
                        final String imageUrl = (offer['images'] != null && (offer['images'] as List).isNotEmpty)
    ? offer['images'][0] // Use the first image if it's a list
    : offer['image'] ?? 'https://via.placeholder.com/150'; // Fallback to 'image' or placeholder
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Offer Image
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 150,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image, size: 50),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$discount% off',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      desc,
                                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 18, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          venueName,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // See Details Button
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => OfferDetails(allDetail: offer),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'See Details',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        // Remove Button
                                        OutlinedButton(
                                          onPressed: () => removeOffer(offerId),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.red),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Remove',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}



