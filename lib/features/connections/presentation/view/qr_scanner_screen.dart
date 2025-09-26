// lib/features/connections/presentation/view/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final String? code = capture.barcodes.first.rawValue;

    if (code != null && code.isNotEmpty) {
      _isProcessing = true;
      // Retorna o código lido para a tela anterior
      Navigator.of(context).pop(code);
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler QR Code'),
        // ignore: deprecated_member_use
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // Sobreposição para guiar o utilizador
          _buildScannerOverlay(),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: _buildCameraControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.black.withOpacity(0.5),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width * 0.15,
          ),
          vertical: BorderSide(
            color: Colors.transparent,
            width: MediaQuery.of(context).size.height * 0.25,
          ),
        ),
      ),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.width * 0.7,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accent, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => _scannerController.toggleTorch(),
          icon: const Icon(Icons.flash_on, color: Colors.white, size: 32),
          tooltip: 'Lanterna',
        ),
        const SizedBox(width: 40),
        IconButton(
          onPressed: () => _scannerController.switchCamera(),
          icon:
              const Icon(Icons.flip_camera_ios, color: Colors.white, size: 32),
          tooltip: 'Virar Câmara',
        ),
      ],
    );
  }
}
