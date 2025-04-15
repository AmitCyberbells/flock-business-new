import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  _QRScanScreenState createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool _isPermissionGranted = false;
  bool _isScanned = false;
  MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        var newStatus = await Permission.camera.status;
        if (newStatus.isGranted) {
          setState(() => _isPermissionGranted = true);
        }
      });
    } else {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Camera Permission Denied!');
    }
  }

  void _handleScannedQRCode(String qrCode, BuildContext screenContext) {
    print('Scanned QR Code: $qrCode');
    if (mounted && !_isScanned) {
      setState(() {
        _isScanned = true;
      });
      _scannerController.stop(); // Stop scanner to prevent multiple triggers
      try {
        showDialog(
          context: screenContext,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('QR Code Scanned'),
            content: Text('QR Code scanned successfully: $qrCode'),
            actions: [
              TextButton(
                onPressed: () {
                  print('Dialog OK button pressed');
                  Navigator.of(dialogContext).pop(); // Close dialog
                  Navigator.of(screenContext).pop(); // Pop QRScanScreen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e, stackTrace) {
        print('Error showing dialog: $e\n$stackTrace');
        Navigator.of(screenContext).pop(); // Fallback navigation
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A4CE1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            print('AppBar back button pressed');
            Navigator.pop(context);
          },
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
                            controller: _scannerController,
                            onDetect: (capture) {
                              if (!_isScanned) {
                                final barcodes = capture.barcodes;
                                if (barcodes.isNotEmpty) {
                                  final qrCode = barcodes.first.rawValue ?? '';
                                  _handleScannedQRCode(qrCode, context);
                                }
                              }
                            },
                          )
                        : Stack(
                            children: [
                              Container(
                                color: Colors.black.withOpacity(0.14),
                              ),
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 190),
          ],
        ),
      ),
    );
  }
}