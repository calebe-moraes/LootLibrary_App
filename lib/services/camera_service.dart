import 'package:mobile_scanner/mobile_scanner.dart';

class CameraService {
  final MobileScannerController controller;

  CameraService() : controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates, // evita scans repetidos
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  // Liga/desliga o flash
  Future<void> toggleFlash() => controller.toggleTorch();

  // Troca câmera frontal ↔ traseira
  Future<void> switchCamera() => controller.switchCamera();

  // Sempre chame isso ao sair da tela do scanner
  void dispose() => controller.dispose();
}