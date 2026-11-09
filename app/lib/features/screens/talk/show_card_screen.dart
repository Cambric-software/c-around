import 'package:flutter/material.dart';

import '../../../app/app_services.dart';

/// A full-screen card that shows one sentence to another person.
///
/// This is the fastest way for a non-verbal user to answer a question in a
/// noisy place: the text is enormous, the background is black and the contrast
/// is fixed rather than following the app theme.
class ShowCardScreen extends StatelessWidget {
  /// Create a card.
  const ShowCardScreen({
    super.key,
    required this.services,
    required this.text,
  });

  /// Application services, used by the speak button.
  final AppServices services;

  /// Sentence to display.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 96),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                tooltip: 'Close card',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(52, 52),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: FilledButton.icon(
                onPressed: () => services.announcer.speakDirect(text),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Speak this'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
