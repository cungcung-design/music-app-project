import 'package:flutter/material.dart';
import '../../models/artist.dart';

class ArtistSection extends StatefulWidget {
  final List<Artist> artists;
  final void Function(Artist) onArtistTap;

  const ArtistSection(
      {super.key, required this.artists, required this.onArtistTap});

  @override
  State<ArtistSection> createState() => _ArtistSectionState();
}

class _ArtistSectionState extends State<ArtistSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.artists.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            "Artists",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // --- ARTIST LIST ---
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: widget.artists.length,
            itemBuilder: (context, index) {
              final artist = widget.artists[index];

              return GestureDetector(
                onTap: () => widget.onArtistTap(artist),
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      // 🎤 ARTIST IMAGE
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: artist.artistProfileUrl != null &&
                                  artist.artistProfileUrl!.isNotEmpty
                              ? Image.network(
                                  artist.artistProfileUrl!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white54,
                                ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 🧑 ARTIST NAME
                      SizedBox(
                        width: 90,
                        child: Text(
                          artist.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
