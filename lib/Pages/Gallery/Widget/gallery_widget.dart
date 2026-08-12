import 'package:flutter/material.dart';
import 'package:nita/Pages/Gallery/Model/gallery_model.dart';

class PhotoTile extends StatelessWidget {
  final PhotoItem photo;
  const PhotoTile({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(photo.colorHex1), Color(photo.colorHex2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(photo.emoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.72)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
              child: Text(
                photo.caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
