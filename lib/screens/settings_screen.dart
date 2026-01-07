import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../widgets/custom_toast.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'moto_pos_v3.db');
      final sourceFile = File(path);

      if (!await sourceFile.exists()) {
        if (context.mounted) {
          CustomToast.show(context, 'Database not found!', isError: true);
        }
        return;
      }

      // Target path: Downloads folder
      // Note: This path is for standard Android. Might vary on devices.
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final targetPath = join(downloadDir.path, 'moto_pos_backup_${DateTime.now().millisecondsSinceEpoch}.db');
      await sourceFile.copy(targetPath);

      if (context.mounted) {
        CustomToast.show(context, 'Database exported to Downloads!');
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(context, 'Export failed: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.backup, color: Colors.blue),
            title: const Text('Export Database'),
            subtitle: const Text('Save a backup of your data to Downloads'),
            onTap: () => _exportDatabase(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Belani POS v4.0'),
          ),
        ],
      ),
    );
  }
}
