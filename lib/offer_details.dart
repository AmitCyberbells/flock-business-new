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
 late String? expireAt; // Use expire_at from API response
 late String discount;


 // Redeemed people list
 List<dynamic> redeemedPeopleList = [];


 // QR Scanner controller
 late MobileScannerController _scannerController;


 @override
 @override
void initState() {
 super.initState();
 final detail = widget.allDetail;
 offerId = detail['id'] ?? 0;
 venueId = detail['venue_id'];
 venueName = detail['venue']?['name'] ?? 'No Venue';
 offerName = detail['name'] ?? 'No Title';
  // Handle image URL from the images array
 final images = detail['images'] as List<dynamic>?;
 imageUrl = (images != null && images.isNotEmpty)
     ? images[0]['image'] ?? ''
     : '';
  description = detail['description'] ?? '';
 redeemed_count = detail['people'] ?? 0;
 expireAt = detail['expire_at'];
 discount = detail['discount']?.toString() ?? '0';


 _scannerController = MobileScannerController(
   detectionSpeed: DetectionSpeed.normal,
   facing: CameraFacing.back,
   torchEnabled: false,
 );


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
       const SnackBar(content: Text('Authentication failed. Please login again.')),
     );
     return;
   }
   try {
     final url = Uri.parse('http://165.232.152.77/mobi/api/vendor/count_redeem_offer');
     final request = http.MultipartRequest('POST', url);
     request.headers['Authorization'] = 'Bearer $token';
     request.fields['offer_id'] = offerId.toString();


     final streamed = await request.send();
     final response = await http.Response.fromStream(streamed);
     if (response.statusCode == 200) {
       final data = jsonDecode(response.body);
       if (data['status'] == 'success' && data['result'] != null) {
         setState(() {
           redeemedPeopleList = List.from(data['result']);
           redeemed_count = redeemedPeopleList.length; // Update redeemed_count
         });
       } else {
         setState(() {
           errorMessage = data['message'] ?? 'Failed to fetch redeemed people.';
         });
       }
     } else {
       setState(() {
         errorMessage = 'Failed to fetch redeemed people. Code: ${response.statusCode}';
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
       const SnackBar(content: Text('Authentication failed. Please login again.')),
     );
     return;
   }
   try {
     final url = Uri.parse('http://165.232.152.77/mobi/api/vendor/offers/$offerId');
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
       Navigator.pop(context, true); // Indicate that the offer was removed
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
Future<void> endOffer() async {
 _setLoading(true);
 final token = await _getToken();
 if (token == null || token.isEmpty) {
   _setLoading(false);
   ScaffoldMessenger.of(context).showSnackBar(
     const SnackBar(content: Text('Authentication failed. Please login again.')),
   );
   return;
 }
 try {
   final url = Uri.parse('http://165.232.152.77/mobi/api/vendor/offers/$offerId/expire-toggle');
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
         expireAt = data['data']['expire_at']; // Update expire_at from API response
       });
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(data['message'] ?? 'Offer expired!')),
       );
       // Do not pop the screen. The updated expireAt will cause isExpired to be true.
     } else {
       setState(() {
         errorMessage = data['message'] ?? 'Failed to expire offer.';
       });
     }
   } else {
     setState(() {
       errorMessage = 'Failed to expire offer. Code: ${response.statusCode}';
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




 Future<void> scanQR() async {
   // Check if the offer is expired before allowing QR scanning
   if (expireAt != null) {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Cannot scan QR code: Offer is expired.')),
     );
     return;
   }


   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => Scaffold(
         appBar: AppBar(title: const Text('Scan QR Code')),
         body: MobileScanner(
           controller: _scannerController,
           onDetect: (capture) {
             final barcodes = capture.barcodes;
             if (barcodes.isNotEmpty) {
               Navigator.pop(context);
               _verifyQRCode(barcodes.first.rawValue ?? '');
             }
           },
         ),
       ),
     ),
   );
 }


 Future<void> _verifyQRCode(String qrCode) async {
   _setLoading(true);
   final token = await _getToken();
   if (token == null || token.isEmpty) {
     _setLoading(false);
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Authentication failed. Please login again.')),
     );
     return;
   }


   // Check if the offer is expired
   if (expireAt != null) {
     _setLoading(false);
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Cannot verify QR code: Offer is expired.')),
     );
     return;
   }


   try {
     // Validate QR code format
     if (qrCode.isEmpty) {
       _setLoading(false);
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Invalid QR code: Empty data.')),
       );
       return;
     }


     // Parse QR code as JSON
     Map<String, dynamic> decodedData;
     try {
       decodedData = jsonDecode(qrCode);
     } catch (e) {
       _setLoading(false);
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Invalid QR code: Not a valid JSON format.')),
       );
       return;
     }


     // Extract redeem_id from QR code
     final redeemId = decodedData['redeem_id'];
     if (redeemId == null) {
       _setLoading(false);
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Invalid QR code: Missing redeem_id.')),
       );
       return;
     }


     // Verify the QR code with the API
     final url = Uri.parse('http://165.232.152.77/mobi/api/vendor/redeemed-offers/$redeemId/verify');
     final response = await http.post(
       url,
       headers: {
         'Authorization': 'Bearer $token',
         'Content-Type': 'application/json',
       },
     );


     if (response.statusCode == 200) {
       final data = jsonDecode(response.body);
       if (data['status'] == 'success') {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(data['message'] ?? 'QR Code verified successfully!')),
         );
         await fetchRedeemedPeople(); // Refresh the redeemed people list
       } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(data['message'] ?? 'Verification failed.')),
         );
       }
     } else {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error: ${response.statusCode}')),
       );
     }
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Network error: $e')),
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
           child: redeemedPeopleList.isEmpty
               ? const Center(child: Text('No data found.'))
               : ListView.builder(
                   itemCount: redeemedPeopleList.length,
                   itemBuilder: (context, index) {
                     final person = redeemedPeopleList[index];
                     final username = person['username'] ?? 'Unknown';
                     final image = person['images'];
                     return ListTile(
                       leading: CircleAvatar(
                         backgroundImage: image != null
                             ? NetworkImage(image)
                             : const AssetImage('assets/placeholder.png') as ImageProvider,
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
     builder: (ctx) => AlertDialog(
       title: const Text('Remove Offer'),
       content: const Text('Are you sure you want to remove this offer?'),
       actions: [
         TextButton(onPressed: removeOffer, child: const Text('Yes')),
         TextButton(
           onPressed: () => Navigator.pop(context),
           child: const Text('No'),
         ),
       ],
     ),
   );
 }


 void showEndDialogFunc() {
   showDialog(
     context: context,
     builder: (ctx) => AlertDialog(
       title: const Text('End Offer'),
       content: const Text('Are you sure you want to end this offer?'),
       actions: [
         TextButton(onPressed: endOffer, child: const Text('Yes')),
         TextButton(
           onPressed: () => Navigator.pop(context),
           child: const Text('No'),
         ),
       ],
     ),
   );
 }


 @override
 Widget build(BuildContext context) {
   bool isExpired = expireAt != null; // Offer is expired if expire_at is not null


   return Stack(
     children: [
       Scaffold(
         appBar: AppBar(
           title: const Text('Offer Detail'),
           leading: IconButton(
             icon: const Icon(Icons.arrow_back),
             onPressed: () => Navigator.pop(context),
           ),
           actions: [
             IconButton(
               icon: const Icon(Icons.qr_code),
               onPressed: isExpired ? null : scanQR, // Disable QR scanning if expired
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
               const SizedBox(height: 16),
               // Text(
               //   '$discount% off',
               //   style: const TextStyle(
               //     fontSize: 20,
               //     fontWeight: FontWeight.bold,
               //     color: Colors.orange,
               //   ),
               // ),
               const SizedBox(height: 8),
               Text(
                 offerName,
                 style: const TextStyle(
                   fontSize: 24,
                   fontWeight: FontWeight.bold,
                 ),
               ),
               const SizedBox(height: 16),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text(
                         'Redeemed in:',
                         style: TextStyle(color: Colors.grey),
                       ),
                       Text(
                         venueName,
                         style: const TextStyle(fontWeight: FontWeight.bold),
                       ),
                     ],
                   ),
                   InkWell(
                     onTap: showRedeemedPeopleDialog,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text(
                           'Redeemed by:',
                           style: TextStyle(color: Colors.grey),
                         ),
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
               const Text(
                 'Description',
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 8),
               Text(description, textAlign: TextAlign.justify),
               const SizedBox(height: 32),
               Row(
                 children: [
                   Expanded(
                     child: OutlinedButton(
                       onPressed: showRemoveDialogFunc,
                       child: const Text(
                         'Remove',
                         style: TextStyle(color: Colors.blue),
                       ),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: isExpired
                         ? ElevatedButton(
                             onPressed: null, // Disable the button
                             style: ElevatedButton.styleFrom(
                               backgroundColor: Colors.grey, // Indicate disabled state
                             ),
                             child: const Text('Expired'),
                           )
                         : ElevatedButton(
                             onPressed: showEndDialogFunc,
                             style: ElevatedButton.styleFrom(
                               backgroundColor: const Color.fromRGBO(255, 130, 16, 1),
                             ),
                             child: const Text('End Offer'),
                           ),
                   ),
                 ],
               ),
               if (errorMessage.isNotEmpty) ...[
                 const SizedBox(height: 16),
                 Center(
                   child: Text(
                     errorMessage,
                     style: const TextStyle(color: Color.fromRGBO(255, 130, 16, 1)),
                   ),
                 ),
               ],
             ],
           ),
         ),
       ),
       if (isLoading)
         Container(
           color: Colors.black26,
           child: const Center(child: CircularProgressIndicator()),
         ),
     ],
   );
 }
}


