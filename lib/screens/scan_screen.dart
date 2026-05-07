import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/ocr_provider.dart';
import '../providers/permission_provider.dart';
import '../services/permission_service.dart';
import '../widgets/permission_dialog.dart';
import 'add_card_screen.dart';
import 'text_selection_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Show permission dialog first, then initialize camera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPermissionDialogAndInitialize();
    });
  }

  Future<void> _showPermissionDialogAndInitialize() async {
    final permissionService = ref.read(permissionServiceProvider);

    // Check if permission is already granted
    final isGranted = await permissionService.isCameraPermissionGranted();
    if (isGranted) {
      _initializeCamera();
      return;
    }

    // Show dialog explaining why we need the permission
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionDialog(
        title: 'Permiso de Cámara',
        message: 'Esta aplicación necesita acceso a la cámara para escanear cartas de Flesh and Blood TCG.',
        onGranted: () async {
          await _requestPermissionAndInitialize();
        },
        onDenied: () {
          setState(() {
            _errorMessage = 'Se requiere permiso de cámara para usar esta función';
          });
        },
      ),
    );
  }

  Future<void> _requestPermissionAndInitialize() async {
    final permissionService = ref.read(permissionServiceProvider);
    final result = await permissionService.requestCameraPermission();

    if (!mounted) return;

    switch (result) {
      case PermissionResult.granted:
        _initializeCamera();
        break;
      case PermissionResult.denied:
        setState(() {
          _errorMessage = 'Se requiere permiso de cámara para escanear cartas. Por favor, intenta nuevamente.';
        });
        break;
      case PermissionResult.permanentlyDenied:
        setState(() {
          _errorMessage = 'El permiso de cámara ha sido denegado permanentemente.';
        });
        showDialog(
          context: context,
          builder: (context) => const PermissionPermanentlyDeniedDialog(
            title: 'Permiso Denegado',
            message: 'Has denegado permanentemente el acceso a la cámara. Para usar esta función, debes habilitar el permiso en la configuración.',
          ),
        );
        break;
      case PermissionResult.error:
        setState(() {
          _errorMessage = 'Error al solicitar permiso de cámara';
        });
        break;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No se encontraron cámaras disponibles';
        });
        return;
      }

      // Initialize camera controller
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null; // Clear any previous error
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al inicializar la cámara: $e';
        });
      }
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _cameraController!.takePicture();
      final ocrService = ref.read(ocrServiceProvider);

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analizando texto...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Extract text only from the focus rectangle area
      // Rectangle is centered with 80% width and 30% height
      final detectedTexts = await ocrService.extractTextFromArea(
        image,
        x: 0.1,     // 10% from left (to center the 80% width)
        y: 0.35,    // 35% from top (to center the 30% height)
        width: 0.8,  // 80% of total width
        height: 0.3, // 30% of total height
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Navigate to text selection screen with all detected texts
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TextSelectionScreen(
              detectedTexts: detectedTexts,
              imagePath: image.path,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildFocusOverlay() {
    return CustomPaint(
      painter: _FocusRectanglePainter(),
      child: Container(),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Carta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddCardScreen(),
                ),
              );
            },
            tooltip: 'Añadir manualmente',
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 100,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage!.contains('permanentemente'))
                      ElevatedButton.icon(
                        onPressed: () async {
                          await openAppSettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Abrir Configuración'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                          _showPermissionDialogAndInitialize();
                        },
                        child: const Text('Reintentar'),
                      ),
                  ],
                ),
              ),
            )
          : !_isInitialized
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Stack(
                  children: [
                    // Camera preview
                    SizedBox.expand(
                      child: CameraPreview(_cameraController!),
                    ),
                    // Focus rectangle overlay
                    _buildFocusOverlay(),
                    // Overlay with instructions
                    Positioned(
                      top: 40,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.center_focus_strong,
                              color: Colors.white,
                              size: 30,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Enfoca el nombre de la carta',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Coloca el nombre dentro del rectángulo verde',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Capture button
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FloatingActionButton.large(
                          onPressed: _isProcessing ? null : _takePicture,
                          backgroundColor: Colors.green,
                          child: _isProcessing
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Icon(Icons.camera_alt, size: 40),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _FocusRectanglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Define the focus rectangle dimensions
    final double rectangleWidth = size.width * 0.8;
    final double rectangleHeight = size.height * 0.3;
    final double left = (size.width - rectangleWidth) / 2;
    final double top = (size.height - rectangleHeight) / 2;

    final focusRect = Rect.fromLTWH(left, top, rectangleWidth, rectangleHeight);

    // Draw the dark overlay with a transparent rectangle in the center
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6);

    // Create a path for the entire screen
    final screenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create a path for the focus rectangle
    final focusPath = Path()
      ..addRRect(RRect.fromRectAndRadius(focusRect, const Radius.circular(12)));

    // Subtract the focus rectangle from the screen path
    final overlayPath = Path.combine(
      PathOperation.difference,
      screenPath,
      focusPath,
    );

    canvas.drawPath(overlayPath, overlayPaint);

    // Draw the green border around the focus rectangle
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(focusRect, const Radius.circular(12)),
      borderPaint,
    );

    // Draw corner decorations
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final cornerLength = 40.0;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + rectangleWidth - cornerLength, top),
      Offset(left + rectangleWidth, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + rectangleWidth, top),
      Offset(left + rectangleWidth, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + rectangleHeight - cornerLength),
      Offset(left, top + rectangleHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + rectangleHeight),
      Offset(left + cornerLength, top + rectangleHeight),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + rectangleWidth - cornerLength, top + rectangleHeight),
      Offset(left + rectangleWidth, top + rectangleHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + rectangleWidth, top + rectangleHeight - cornerLength),
      Offset(left + rectangleWidth, top + rectangleHeight),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
