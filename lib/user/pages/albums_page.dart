import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/album.dart';
import '../widgets/album_detail_page.dart';

class AlbumsPage extends StatefulWidget {
  final DatabaseService db;
  const AlbumsPage({super.key, required this.db});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  late Future<List<Album>> _albumsFuture;

  @override
  void initState() {
    super.initState();
    _albumsFuture = widget.db.getAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Near black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Albums',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search, color: Colors.white54)),
        ],
      ),
      body: FutureBuilder<List<Album>>(
        future: _albumsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }

          final albums = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              return _SimpleModernCard(
                album: albums[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AlbumDetailPage(db: widget.db, album: albums[index])),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SimpleModernCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _SimpleModernCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Row(
          children: [
            // 1. Large, high-res looking image with slight rounding
            Hero(
              tag: 'album-${album.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  album.albumProfileUrl ?? '',
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 110,
                    height: 110,
                    color: Colors.white10,
                    child: const Icon(Icons.music_note, color: Colors.white24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // 2. Simple, clean text layout
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${album.songCount} Songs', // Dynamic song count
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 3. Subtle "Play" indicator instead of a bulky button
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Listen Now',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
