import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/database_service.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../utils/toast.dart';
import 'album_detail_page.dart';
import '../widgets/album_dialog.dart';

class ManageAlbumsPage extends StatefulWidget {
  const ManageAlbumsPage({super.key});

  @override
  State<ManageAlbumsPage> createState() => _ManageAlbumsPageState();
}

class _ManageAlbumsPageState extends State<ManageAlbumsPage> {
  final DatabaseService db = DatabaseService();
  List<Album> albums = [];
  List<Artist> artists = [];
  List<Song> songs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      albums = await db.getAlbums();
      artists = await db.getArtists();
      songs = await db.getSongsWithDetails();
    } catch (e) {
      showToast(context, "Failed to load data: $e", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showAddAlbumDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlbumDialog(db: db),
    );
    if (result == true) {
      loadData();
    }
  }

  void _showEditAlbumDialog(Album album) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlbumDialog(db: db, album: album),
    );
    if (result == true) {
      loadData();
    }
  }

  void _showDeleteAlbumDialog(Album album) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Album',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${album.name}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await db.deleteAlbum(album.id);
        showToast(context, 'Album deleted successfully', isError: false);
        loadData();
      } catch (e) {
        showToast(context, 'Failed to delete album: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAlbumDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.all(16),
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final album = albums.removeAt(oldIndex);
            albums.insert(newIndex, album);
          });
        },
        children: albums.map((album) {
          final artist = artists.firstWhere(
            (a) => a.id == album.artistId,
            orElse: () => Artist(id: '', name: 'Unknown', bio: ''),
          );

          return Container(
            key: ValueKey(album.id),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              leading: Hero(
                tag: 'album-${album.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    album.albumProfileUrl ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.album, color: Colors.green, size: 50),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      album.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditAlbumDialog(album),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteAlbumDialog(album),
                  ),
                ],
              ),
              subtitle: Text(
                artist.name,
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumDetailPage(album: album),
                ),
              ).then((_) => loadData()),
            ),
          );
        }).toList(),
      ),
    );
  }
}
