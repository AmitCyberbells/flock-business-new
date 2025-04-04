import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void _handleScannedQRCode(String qrCode) {
  // Implement your logic here, e.g., navigate or show a dialog
  print('Scanned QR Code: $qrCode');
}

class QRScanScreen extends StatelessWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A4CE1 ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFF2A4CE1 ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.0,vertical: 20),
              child: Text(
                'Please place the QR code within the frame. Avoid shaking for best results.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            // Bird icon
            Image.asset(
              'assets/bird.png', // Replace with your bird asset path
              width: 50,
              height: 50,
              // color: Colors.orange, // Match the orange bird color from the screenshot
            ),
            
            // Scanning frame with MobileScanner
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    // allowDuplicates: false,
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        Navigator.pop(context);
                        final qrCode = barcodes.first.rawValue ?? '';
                        _handleScannedQRCode(qrCode);
                      }
                    },
                  ),
                  // Overlay for the scanning frame
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scanning Code ...',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 190),
          ],
        ),
      ),
    );
  }
}

// Usage in your navigation
void navigateToQRScan(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const QRScanScreen(),
    ),
  );
}