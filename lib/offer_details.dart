import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class OfferDetails extends StatefulWidget {
  final Map<String, dynamic> allDetail;

  const OfferDetails({Key? key, required this.allDetail}) : super(key: key);

  @override
  State<OfferDetails> createState() => _OfferDetailsState();
}

class _OfferDetailsState extends State<OfferDetails> {
  bool isLoading = false;
  String errorMessage = '';

  // Offer detail variables
  late int offerId;
  late int? venueId;
  late String venueName;
  late String offerName;
  late String imageUrl;
  late String description;
  late int redeemed_count;
  late String? expireAt;
  late String discount;

  // Redeemed people list
  List<dynamic> redeemedPeopleList = [];

  // QR Scanner controller
  late MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    final detail = widget.allDetail;
    offerId = detail['id'] ?? 0;
    venueId = detail['venue_id'];
    venueName = detail['venue']?['name'] ?? 'No Venue';
    offerName = detail['name'] ?? 'No Title';
    final images = detail['images'] as List<dynamic>?;
    imageUrl =
        (images != null && images.isNotEmpty) ? images[0]['image'] ?? '' : '';
    description = detail['description'] ?? '';
    redeemed_count = detail['people'] ?? 0;
    expireAt = detail['expire_at'];
    discount = detail['discount']?.toString() ?? '0';

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    print('before fetch');

    fetchRedeemedPeople();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  void _setLoading(bool loading) {
    setState(() {
      isLoading = loading;
      errorMessage = '';
    });
  }

  Future<void> fetchRedeemedPeople() async {
    _setLoading(true);
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Please login again.'),
        ),
      );
      return;
    }

    try {
      final url = Uri.parse(
        'http://165.232.152.77/api/vendor/offers/$offerId/redeemed-count',
      );
      final request = http.MultipartRequest('GET', url);
      request.headers['Authorization'] = 'Bearer $token';
      // request.fields['offer_id'] = offerId.toString();

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final statusCode = response.statusCode;
      print('data before print ' + statusCode.toString());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('data for offer: $data');

        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            // redeemedPeopleList = List.from(data['count']);
            redeemed_count = data['data']['count'];
          });
        } else {
          setState(() {
            errorMessage =
                data['message'] ?? 'Failed to fetch redeemed people.';
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to fetch redeemed people. Code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
      });
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeOffer() async {
    Navigator.pop(context);
    _setLoading(true);
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Please login again.'),
        ),
      );
      return;
    }
    try {
      final url = Uri.parse('http://165.232.152.77/api/vendor/offers/$offerId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer removed successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          errorMessage = 'Failed to remove offer. Code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
      });
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleOfferStatus() async {
    _setLoading(true);
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Please login again.'),
        ),
      );
      return;
    }
    try {
      final url = Uri.parse(
        'http://165.232.152.77/api/vendor/offers/$offerId/expire-toggle',
      );
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            expireAt = data['data']['expire_at'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                expireAt != null
                    ? (data['message'] ?? 'Offer ended successfully!')
                    : (data['message'] ?? 'Offer reactivated successfully!'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to toggle offer status.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to toggle offer status. Code: ${response.statusCode}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> scanQR() async {
    if (expireAt != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot scan QR code: Offer is expired.')),
      );
      return;
    }

    try {
      await _scannerController.start();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(title: const Text('Scan QR Code')),
                body: Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: (capture) async {
                        final barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final qrCode = barcodes.first.rawValue ?? '';
                          print('Scanned QR Code: $qrCode');
                          await _scannerController.stop();
                          if (!mounted) return;
                          Navigator.pop(context);
                          await _verifyQRCode(qrCode);
                        }
                      },
                    ),
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ).then((_) async {
        await _scannerController.stop();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting scanner: $e')));
    }
  }

  Future<void> _verifyQRCode(String qrCode) async {
    print('Verifying QR Code: $qrCode');
    _setLoading(true);

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Please login again.'),
        ),
      );
      return;
    }

    if (expireAt != null) {
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot verify QR code: Offer is expired.'),
        ),
      );
      return;
    }

    if (qrCode.isEmpty) {
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code: Empty data.')),
      );
      return;
    }

    Map<String, dynamic> decodedData;
    try {
      decodedData = jsonDecode(qrCode);
      print('Decoded QR Data: $decodedData');
    } catch (e) {
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code: Not a valid JSON format.'),
        ),
      );
      return;
    }

    final redeemId = decodedData['redeem_id'];
    if (redeemId == null) {
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code: Missing redeem_id.')),
      );
      return;
    }

    int? parsedRedeemId;
    try {
      parsedRedeemId = int.parse(redeemId.toString());
      print('Parsed Redeem ID: $parsedRedeemId');
    } catch (e) {
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code: redeem_id must be a valid number.'),
        ),
      );
      return;
    }

    try {
      final url = Uri.parse(
        'http://165.232.152.77/api/vendor/redeemed-offers/$parsedRedeemId/verify?offer_id=$offerId',
      );
      print('Sending verification request to: $url');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Offer verified successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          await fetchRedeemedPeople();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Verification failed.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification error: ${response.statusCode} - ${response.body}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Network error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _setLoading(false);
    }
  }

  void showRedeemedPeopleDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Redeemed People List'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child:
                redeemedPeopleList.isEmpty
                    ? const Center(child: Text('No data found.'))
                    : ListView.builder(
                      itemCount: redeemedPeopleList.length,
                      itemBuilder: (context, index) {
                        final person = redeemedPeopleList[index];
                        final username = person['username'] ?? 'Unknown';
                        final image = person['images'];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                image != null
                                    ? NetworkImage(image)
                                    : const AssetImage('assets/placeholder.png')
                                        as ImageProvider,
                          ),
                          title: Text(username),
                        );
                      },
                    ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void showRemoveDialogFunc() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Offer'),
            content: const Text('Are you sure you want to remove this offer?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  removeOffer();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void showToggleOfferDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(expireAt != null ? 'Reactivate Offer' : 'End Offer'),
            content: Text(
              expireAt != null
                  ? 'Are you sure you want to bring this offer back?'
                  : 'Are you sure you want to end this offer?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  toggleOfferStatus();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isExpired = expireAt != null;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Offer Detail'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: isExpired ? null : scanQR,
                tooltip: isExpired ? 'Offer Expired' : 'Scan QR Code',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        ColorFiltered(
                          colorFilter:
                              isExpired
                                  ? const ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.saturation,
                                  )
                                  : const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.dst,
                                  ),
                          child: Image.network(
                            imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 50),
                              );
                            },
                          ),
                        ),
                        if (isExpired)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Offer Expired',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  offerName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(description, textAlign: TextAlign.justify),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/orange_hotel.png',
                              color: Colors.grey,
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Offered by:',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          venueName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: showRedeemedPeopleDialog,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/people.png',
                                color: Colors.grey,
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Redeemed by:',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$redeemed_count People',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: showRemoveDialogFunc,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Delete Offer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: showToggleOfferDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isExpired
                                  ? Colors.green
                                  : const Color.fromRGBO(255, 130, 16, 1),
                        ),
                        child: Text(
                          isExpired ? 'Bring Offer Back' : 'End Offer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Color.fromRGBO(255, 130, 16, 1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isLoading)
          Stack(
            children: [
              Container(color: Colors.black.withOpacity(0.14)),
              Container(
                color: Colors.white10,
                child: Center(
                  child: Image.asset(
                    'assets/Bird_Full_Eye_Blinking.gif',
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
