import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onGranted;
  final VoidCallback? onDenied;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onGranted,
    this.onDenied,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 16),
          const Text(
            'Al presionar "Permitir", se te pedirá que autorices el acceso a la cámara.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onDenied != null) {
              onDenied!();
            }
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onGranted();
          },
          child: const Text('Permitir'),
        ),
      ],
    );
  }
}

class PermissionPermanentlyDeniedDialog extends StatelessWidget {
  final String title;
  final String message;

  const PermissionPermanentlyDeniedDialog({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 16),
          const Text(
            'Para habilitar este permiso, debes ir a la configuración de la aplicación.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await openAppSettings();
          },
          icon: const Icon(Icons.settings),
          label: const Text('Abrir Configuración'),
        ),
      ],
    );
  }
}
