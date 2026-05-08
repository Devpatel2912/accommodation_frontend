import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/presentation/widgets/app_button.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final dynamic icon;
  final Color? iconColor;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.icon,
    this.iconColor,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    dynamic icon,
    Color? iconColor,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => AppDialog(
        title: title,
        content: content,
        actions: actions,
        icon: icon,
        iconColor: iconColor,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.teal).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: icon is IconData
                      ? Icon(
                          icon,
                          size: 32,
                          color: iconColor ?? AppColors.teal,
                        )
                      : HugeIcon(
                          icon: icon,
                          size: 32,
                          color: iconColor ?? AppColors.teal,
                        ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              content,
              if (actions != null) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Future<void> Function() onConfirm;
  final dynamic icon;
  final Color? confirmColor;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.icon,
    this.confirmColor,
  });

  @override
  State<AppConfirmDialog> createState() => _AppConfirmDialogState();
}

class _AppConfirmDialogState extends State<AppConfirmDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      icon: widget.icon,
      iconColor: widget.confirmColor,
      content: Text(
        widget.message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textLight,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            widget.cancelText,
            style: const TextStyle(
              color: AppColors.labelGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 110,
          child: AppButton(
            text: widget.confirmText,
            height: 40,
            borderRadius: 12,
            color: widget.confirmColor,
            isLoading: _isLoading,
            onPressed: () async {
              setState(() => _isLoading = true);
              await widget.onConfirm();
              if (mounted) {
                setState(() => _isLoading = false);
                Navigator.pop(context, true);
              }
            },
          ),
        ),
      ],
    );
  }
}
