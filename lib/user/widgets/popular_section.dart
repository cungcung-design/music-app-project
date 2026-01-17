import 'package:flutter/material.dart';
import '../../models/song.dart';


class PopularSection extends StatelessWidget {
  final List<Song> songs;
  final Function(Song, List<Song>) onSongTap;

  const PopularSection(
      {super.key, required this.songs, required this.onSongTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Popular Songs",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => onSongTap(song, songs),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(song.albumImage ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[900], width: 50, height: 50)),
                ),
                title: Text(song.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                subtitle: Text(song.artistName ?? "Unknown Artist",
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                trailing: const Icon(Icons.play_circle_outline,
                    color: Colors.white38),
              );
            },
          ),
        ],
      ),
    );
  }
}
