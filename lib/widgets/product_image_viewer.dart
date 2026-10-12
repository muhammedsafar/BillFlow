import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Renders a product image from various sources (Network URL, Data URI / Base64, Local File).
/// Safely falls back to a placeholder widget or icon if the image is missing or invalid.
class ProductImageViewer extends StatelessWidget {
  final String? image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final bool interactive;

  const ProductImageViewer({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.interactive = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = _buildImageWidget(context);

    if (interactive) {
      content = InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.8,
        maxScale: 4.0,
        child: content,
      );
    }

    if (borderRadius != null) {
      content = ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    if (width != null || height != null) {
      content = SizedBox(
        width: width,
        height: height,
        child: content,
      );
    }

    return content;
  }

  Widget _buildImageWidget(BuildContext context) {
    final raw = image?.trim();
    if (raw == null || raw.isEmpty) {
      return placeholder ?? _defaultPlaceholder(context);
    }

    // 1. Network Image (HTTP / HTTPS)
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return Image.network(
        raw,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: (width != null && width! < 32) ? 14 : 20,
              height: (height != null && height! < 32) ? 14 : 20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            _buildErrorWidget(context),
      );
    }

    // 2. Data URI (data:image/...) or Base64
    if (raw.startsWith('data:image')) {
      try {
        final commaIndex = raw.indexOf(',');
        final base64String = commaIndex != -1 ? raw.substring(commaIndex + 1) : raw;
        final bytes = base64Decode(base64String.replaceAll(RegExp(r'\s+'), ''));
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorWidget(context),
        );
      } catch (_) {
        return _buildErrorWidget(context);
      }
    }

    // Check if it's a raw base64 string
    if (_isLikelyBase64(raw)) {
      try {
        final bytes = base64Decode(raw.replaceAll(RegExp(r'\s+'), ''));
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorWidget(context),
        );
      } catch (_) {
        // Fall through to local file check
      }
    }

    // 3. Local File Path
    try {
      final file = File(raw);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorWidget(context),
        );
      }
    } catch (_) {
      // Ignored
    }

    return _buildErrorWidget(context);
  }

  bool _isLikelyBase64(String str) {
    if (str.length < 30) return false;
    final clean = str.trim();
    if (clean.contains('/') && (clean.contains(r'\') || clean.contains(':'))) {
      return false; // likely file path
    }
    return !clean.startsWith('/') && !clean.contains(' ') && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(clean.substring(0, 30));
  }

  Widget _defaultPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: (width != null && width! < 40) ? 18 : 32,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: (width != null && width! < 40) ? 18 : 28,
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// Displays an interactive full-size modal dialog with zoom & pan for any product image.
  static Future<void> showImageModal(
    BuildContext context, {
    required String? image,
    required String title,
    String? subtitle,
    Widget? leadingFooter,
    List<Widget>? actions,
  }) async {
    final hasImage = image != null && image.trim().isNotEmpty;
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.55).clamp(560.0, 760.0);
    final dialogMaxHeight = (screenSize.height * 0.88).clamp(500.0, 880.0);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: dialogMaxHeight),
            child: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(dialogContext)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasImage) ...[
                            Container(
                              width: double.infinity,
                              constraints:
                                  const BoxConstraints(maxHeight: 460),
                              decoration: BoxDecoration(
                                color: Theme.of(dialogContext)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Theme.of(dialogContext)
                                        .colorScheme
                                        .outlineVariant),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Center(
                                child: ProductImageViewer(
                                  image: image,
                                  fit: BoxFit.contain,
                                  interactive: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.zoom_in,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Pinch or drag to zoom and inspect image',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Theme.of(dialogContext)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 48, horizontal: 24),
                              decoration: BoxDecoration(
                                color: Theme.of(dialogContext)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Theme.of(dialogContext)
                                        .colorScheme
                                        .outlineVariant),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 54,
                                    color: Theme.of(dialogContext)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'No Image Available',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'This product does not currently have an image attached.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(dialogContext)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: Theme.of(dialogContext)
                                .colorScheme
                                .outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (leadingFooter != null) leadingFooter,
                        const Spacer(),
                        if (actions != null)
                          ...actions
                        else
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Close'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
