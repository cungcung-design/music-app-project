import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';

class SongsPage extends StatefulWidget {
  final DatabaseService db;
  const SongsPage({Key? key, required this.db}) : super(key: key);

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  List<Song> songs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    setState(() => loading = true);
    try {
      songs = await widget.db.getSongs();
      setState(() => loading = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      itemBuilder: (_, index) {
        final song = songs[index];
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            color: Colors.grey[800],
            child: song.audioUrl != null && song.audioUrl!.isNotEmpty
                ? Image.network(song.audioUrl!, fit: BoxFit.cover)
                : const Icon(Icons.music_note, color: Colors.white),
          ),
          title: Text(song.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            'Artist ID: ${song.artistId}',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: const Icon(Icons.play_arrow, color: Colors.green),
        );
      },
    );
  }
}
