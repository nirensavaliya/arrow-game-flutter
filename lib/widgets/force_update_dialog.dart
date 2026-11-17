import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/force_update_service.dart';

class ForceUpdateDialog {
  static void show() {
    Get.dialog(
      PopScope(
        canPop: false, // blocks the back button
        child: AlertDialog(
          title: const Text('Update Required'),
          content: const Text(
            'A new version of Arrow Escape is available. '
                'Please update to continue playing.',
          ),
          actions: [
            TextButton(
              onPressed: ForceUpdateService.instance.openStore,
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}