// import 'package:flutter/material.dart';
// import '../../models/song.dart';

// class RecentlyPlayedSection extends StatelessWidget {
//   final List<Song> songs;
//   final Function(Song) onSongTap;

//   const RecentlyPlayedSection({
//     super.key,
//     required this.songs,
//     required this.onSongTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (songs.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 "Recently Played",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.w800, // Extra bold for modern look
//                   letterSpacing: -0.5,
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {}, // Optional: Navigate to full history
//                 child: Text("See All",
//                   style: TextStyle(color: Colors.greenAccent[400], fontWeight: FontWeight.w600)),
//               )
//             ],
//           ),
//         ),
//         SizedBox(
//           height: 220, // Increased height for better breathing room
//           child: ListView.separated(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             scrollDirection: Axis.horizontal,
//             physics: const BouncingScrollPhysics(), // iOS style bounce
//             itemCount: songs.length,
//             separatorBuilder: (_, __) => const SizedBox(width: 20),
//             itemBuilder: (context, index) {
//               final song = songs[index];
//               return GestureDetector(
//                 onTap: () => onSongTap(song),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center, // Center aligned modern look
//                   children: [
//                     // --- MODERN ALBUM CARD ---
//                     Container(
//                       width: 140,
//                       height: 140,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20), // Softer corners
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.4),
//                             blurRadius: 15,
//                             offset: const Offset(0, 8), // Lifted effect
//                           ),
//                         ],
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(20),
//                         child: Stack(
//                           fit: StackFit.expand,
//                           children: [
//                             song.albumImage != null
//                                 ? Image.network(song.albumImage!, fit: BoxFit.cover)
//                                 : Container(
//                                     color: Colors.grey[900],
//                                     child: const Icon(Icons.music_note, color: Colors.white10, size: 50),
//                                   ),
//                             // Subtle overlay gradient
//                             Container(
//                               decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                   begin: Alignment.topCenter,
//                                   end: Alignment.bottomCenter,
//                                   colors: [
//                                     Colors.transparent,
//                                     Colors.black.withOpacity(0.2),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 12),

//                     // --- TYPOGRAPHY ---
//                     SizedBox(
//                       width: 140,
//                       child: Text(
//                         song.name,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 15,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     SizedBox(
//                       width: 140,
//                       child: Text(
//                         song.artistName ?? "Unknown Artist",
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.6),
//                           fontSize: 13,
//                           letterSpacing: 0.2,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../models/song.dart';

class RecentlyPlayedSection extends StatelessWidget {
  final List<Song> songs;
  final Function(Song, List<Song>) onSongTap;

  const RecentlyPlayedSection({
    super.key,
    required this.songs,
    required this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Recently Played",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90, // Reduced height because it's a horizontal capsule
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final song = songs[index];
              return GestureDetector(
                onTap: () => onSongTap(song, songs),
                child: Container(
                  width: 240, // Wider for the row layout
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    // Semi-transparent background (Glass Effect)
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Smaller square image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: song.albumImage != null
                            ? Image.network(
                                song.albumImage!,
                                width: 65,
                                height: 65,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 65,
                                height: 65,
                                color: Colors.white10,
                                child: const Icon(Icons.music_note,
                                    color: Colors.white24),
                              ),
                      ),
                      const SizedBox(width: 12),
                      // Text Info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artistName ?? "Unknown Artist",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
