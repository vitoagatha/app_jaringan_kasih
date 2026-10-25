import 'dart:typed_data';

import 'package:flutter/material.dart';

class FundingCover extends StatefulWidget {
  final Uri? uri;
  final Uint8List? preview;
  final String label;
  const FundingCover({super.key, this.uri, this.preview, required this.label});
  @override
  State<FundingCover> createState() => _FundingCoverState();
}

class _FundingCoverState extends State<FundingCover> {
  int _attempt = 0;
  Widget _error(BuildContext context, Object error, StackTrace? stack) =>
      Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Foto tidak dapat dimuat.',
                  textAlign: TextAlign.center),
              if (widget.preview == null)
                TextButton.icon(
                    onPressed: () => setState(() => _attempt++),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Muat ulang foto')),
            ])),
      );

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: widget.label,
        child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: widget.preview != null
                    ? Image.memory(widget.preview!,
                        fit: BoxFit.cover,
                        cacheWidth: 1024,
                        errorBuilder: _error)
                    : widget.uri != null
                        ? Image.network(widget.uri.toString(),
                            key: ValueKey('${widget.uri}-$_attempt'),
                            fit: BoxFit.cover,
                            cacheWidth: 1024,
                            errorBuilder: _error,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                    ? child
                                    : const Center(
                                        child: CircularProgressIndicator(
                                            semanticsLabel:
                                                'Memuat foto pendanaan')))
                        : const Center(
                            child: Icon(Icons.image_outlined,
                                size: 48,
                                semanticLabel: 'Belum ada foto pendanaan')),
              ),
            )),
      );
}
