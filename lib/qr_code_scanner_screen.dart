import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

void _handleScannedQRCode(String qrCode) {
  print('Scanned QR Code: $qrCode');
}

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  _QRScanScreenState createState() => _QRScanScreenState();
}
class _QRScanScreenState extends State<QRScanScreen> {
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    var status = await Permission.camera.status;
    print("QRScanScreen permission status: $status");
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    if (status.isGranted) {
      setState(() => _isPermissionGranted = true);
    } else if (status.isPermanentlyDenied) {
      Fluttertoast.showToast(
        msg: 'Camera permission is required. Please enable it in settings.',
      );
      await openAppSettings();
      // Re-check permission when returning
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        var newStatus = await Permission.camera.status;
        if (newStatus.isGranted) {
          setState(() => _isPermissionGranted = true);
        }
      });
    } else {
      Navigator.pop(context); // Go back if permission is denied
      Fluttertoast.showToast(msg: 'Camera Permission Denied!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A4CE1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFF2A4CE1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Text(
                'Please place the QR code within the frame. Avoid shaking for best results.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 250,
              height: 300,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _isPermissionGranted
                        ? MobileScanner(
                            onDetect: (capture) {
                              final barcodes = capture.barcodes;
                              if (barcodes.isNotEmpty) {
                                Navigator.pop(context);
                                final qrCode = barcodes.first.rawValue ?? '';
                                _handleScannedQRCode(qrCode);
                              }
                            },
                          )
                        : Container(
  color: Colors.white.withOpacity(0.19),
  child: Center(
    child: Image.asset(
      'assets/Bird_Full_Eye_Blinking.gif',
      width: 100, // Adjust size as needed
      height: 100,
    ),
  ),
)

                  ),
                  Container(
                    width: 250,
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Positioned(
                    top: -35,
                    left: 250 / 2 - 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(1.0),
                      child: Image.asset('assets/bird.png', fit: BoxFit.contain),
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