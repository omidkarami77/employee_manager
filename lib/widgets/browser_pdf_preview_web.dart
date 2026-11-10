import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget browserPdfPreview(Uint8List bytes) => _BrowserPdfPreview(bytes: bytes);

class _BrowserPdfPreview extends StatefulWidget {
  const _BrowserPdfPreview({required this.bytes});
  final Uint8List bytes;

  @override
  State<_BrowserPdfPreview> createState() => _BrowserPdfPreviewState();
}

class _BrowserPdfPreviewState extends State<_BrowserPdfPreview> {
  late final String _url;

  @override
  void initState() {
    super.initState();
    _url = web.URL.createObjectURL(
      web.Blob(
        [widget.bytes.toJS].toJS,
        web.BlobPropertyBag(type: 'application/pdf'),
      ),
    );
  }

  @override
  void dispose() {
    web.URL.revokeObjectURL(_url);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton.icon(
        onPressed: () => web.window.open(_url, '_blank'),
        icon: const Icon(Icons.open_in_new),
        label: const Text('باز کردن PDF در تب جدید'),
      ),
      Expanded(
        child: HtmlElementView.fromTagName(
          tagName: 'iframe',
          onElementCreated: (element) {
            final frame = element as web.HTMLIFrameElement;
            frame.src = _url;
            frame.title = 'پیش‌نمایش گزارش PDF';
            frame.style.border = '0';
            frame.style.width = '100%';
            frame.style.height = '100%';
          },
        ),
      ),
    ],
  );
}
