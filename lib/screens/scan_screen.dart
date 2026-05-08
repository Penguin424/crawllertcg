import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/ocr_provider.dart';
import '../providers/permission_provider.dart';
import '../services/flesh_and_blood_service.dart';
import '../services/permission_service.dart';
import '../widgets/permission_dialog.dart';
import 'add_card_screen.dart';
import 'card_search_results_screen.dart';
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
  bool _torchOn = false;
  String? _errorMessage;
  String _processingMessage = 'Analizando texto...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPermissionDialogAndInitialize();
    });
  }

  Future<void> _showPermissionDialogAndInitialize() async {
    final permissionService = ref.read(permissionServiceProvider);

    final isGranted = await permissionService.isCameraPermissionGranted();
    if (isGranted) {
      _initializeCamera();
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionDialog(
        title: 'Permiso de Cámara',
        message:
            'Esta aplicación necesita acceso a la cámara para escanear cartas de Flesh and Blood TCG.',
        onGranted: () async {
          await _requestPermissionAndInitialize();
        },
        onDenied: () {
          setState(() {
            _errorMessage =
                'Se requiere permiso de cámara para usar esta función';
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
          _errorMessage =
              'Se requiere permiso de cámara para escanear cartas. Por favor, intenta nuevamente.';
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
            message:
                'Has denegado permanentemente el acceso a la cámara. Para usar esta función, debes habilitar el permiso en la configuración.',
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
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No se encontraron cámaras disponibles';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
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

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final next = !_torchOn;
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torchOn = next);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo activar la linterna: $e')),
        );
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
      _processingMessage = 'Analizando texto...';
    });

    try {
      final image = await _cameraController!.takePicture();
      final ocrService = ref.read(ocrServiceProvider);

      final detectedTexts = await ocrService.extractTextFromArea(
        image,
        x: 0.1,
        y: 0.35,
        width: 0.8,
        height: 0.3,
      );

      if (!mounted) return;

      // No text detected → don't navigate, just nudge the user
      if (detectedTexts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No se detectó texto. Prueba con mejor luz o acerca el nombre.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Auto-skip when we got exactly one line: hit the API directly.
      if (detectedTexts.length == 1) {
        await _searchAndNavigate(detectedTexts.first, image.path);
        return;
      }

      // Multiple options → show selection screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TextSelectionScreen(
            detectedTexts: detectedTexts,
            imagePath: image.path,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _searchAndNavigate(String text, String imagePath) async {
    setState(() => _processingMessage = 'Buscando "$text"...');
    try {
      final results = await FleshAndBloodService().searchCards(text);
      if (!mounted) return;

      if (results.isEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddCardScreen(
              initialName: text,
              imagePath: imagePath,
            ),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CardSearchResultsScreen(
            results: results,
            imagePath: imagePath,
            searchQuery: text,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      // API error → fall back to manual entry with the OCR'd name
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddCardScreen(
            initialName: text,
            imagePath: imagePath,
          ),
        ),
      );
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
          if (_isInitialized)
            IconButton(
              tooltip: _torchOn ? 'Apagar linterna' : 'Encender linterna',
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
              onPressed: _toggleTorch,
            ),
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
          ? _ErrorView(
              message: _errorMessage!,
              onRetry: () {
                setState(() => _errorMessage = null);
                _showPermissionDialogAndInitialize();
              },
            )
          : !_isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    SizedBox.expand(
                      child: CameraPreview(_cameraController!),
                    ),
                    _buildFocusOverlay(),
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
                    if (_isProcessing)
                      Positioned(
                        bottom: 130,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _processingMessage,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isPermanent = message.contains('permanentemente');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 100, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (isPermanent)
              ElevatedButton.icon(
                onPressed: () => openAppSettings(),
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
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
          ],
        ),
      ),
    );
  }
}

class _FocusRectanglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double rectangleWidth = size.width * 0.8;
    final double rectangleHeight = size.height * 0.3;
    final double left = (size.width - rectangleWidth) / 2;
    final double top = (size.height - rectangleHeight) / 2;

    final focusRect = Rect.fromLTWH(left, top, rectangleWidth, rectangleHeight);

    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    final screenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final focusPath = Path()
      ..addRRect(
          RRect.fromRectAndRadius(focusRect, const Radius.circular(12)));

    final overlayPath = Path.combine(
      PathOperation.difference,
      screenPath,
      focusPath,
    );

    canvas.drawPath(overlayPath, overlayPaint);

    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(focusRect, const Radius.circular(12)),
      borderPaint,
    );

    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    const cornerLength = 40.0;

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
