import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final String pesan;
  const LoadingOverlay({super.key, this.pesan = 'Memproses...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(pesan),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
