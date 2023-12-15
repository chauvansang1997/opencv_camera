// import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<void> handleAccessPermission({
    required Permission permission,
    required BuildContext context,
    Function()? onPermissionAccepted,
    Function()? onPermissionDenied,
    Function()? onPermissionPermanentlynDenied,
  }) async {
    ///User have permanently denied in previous access, App can not show permission dialog any more
    PermissionStatus status = await permission.status;
    // var status = await Permission.camera.status;

    if (status.isGranted ||
        (permission.value == Permission.photos.value && status.isLimited)) {
      ///Handle your logic when permission is accepted
      onPermissionAccepted?.call();
      return;
    }

    ///Request a permission
    PermissionStatus newStatus = await permission.request();

    if (newStatus.isGranted ||
        (permission.value == Permission.photos.value && newStatus.isLimited)) {
      ///Handle your logic when permission is accepted
      onPermissionAccepted?.call();
      return;
    }

    if (newStatus == PermissionStatus.denied) {
      onPermissionDenied?.call();
      return;
    }

    if (newStatus == PermissionStatus.permanentlyDenied) {
      if (onPermissionPermanentlynDenied == null) {
        // ignore: use_build_context_synchronously
        await PermissionUtils.showPermissionSettingsDialog(context: context);
      } else {
        onPermissionPermanentlynDenied.call();
      }
      return;
    }

    if (status == PermissionStatus.denied) {
      return;
    }

    if (onPermissionPermanentlynDenied == null) {
      // ignore: use_build_context_synchronously
      await PermissionUtils.showPermissionSettingsDialog(context: context);
    } else {
      onPermissionPermanentlynDenied.call();
    }
  }

  static Future<void> showPermissionSettingsDialog({
    required BuildContext context,
    Function()? onOpenSettings,
    String? title,
    String? description,
    String? buttonTitle,
  }) async {
    final currentContext = context;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('You need provide permission for app'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(currentContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Open settings'),
              onPressed: () {
                if (onOpenSettings != null) {
                  Navigator.of(context).pop(true);
                  onOpenSettings();
                } else {
                  // AppSettings.openAppSettings();
                }
              },
            ),
          ],
        );
      },
    );
    // await AppDialogHelper.showError(
    //   title: title ?? '',
    //   content: description ?? '',
    //   actions: [
    //     AppButton(
    //       backgroundColor: Colors.transparent,
    //       // padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
    //       borderColor: Colors.transparent,
    //       onPressed: () {
    //         Navigator.of(currentContext).pop(true);
    //       },
    //       child: Center(
    //         child: Text(
    //           'Cancel',
    //           style: Theme.of(currentContext)
    //               .textTheme
    //               .bodyLarge!
    //               .copyWith(fontSize: 16),
    //         ),
    //       ),
    //     ),
    //     AppButton(
    //       // backgroundColor: Theme.of(currentContext).primaryColor,
    //       // padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
    //       borderColor: Colors.transparent,
    //       onPressed: () {
    //         if (onOpenSettings != null) {
    //           Navigator.of(context).pop();
    //           onOpenSettings();
    //         } else {
    //           AppSettings.openAppSettings();
    //         }
    //       },
    //       child: Center(
    //         child: Text(
    //           'Open settings',
    //           style: Theme.of(currentContext)
    //               .textTheme
    //               .bodyLarge!
    //               .copyWith(fontSize: 16),
    //         ),
    //       ),
    //     ),
    //   ],
    // );
  }
}
