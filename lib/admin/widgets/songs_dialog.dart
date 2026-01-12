import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../models/album.dart';

class SongDialog extends StatefulWidget {
  final DatabaseService db;
  final Song? song; // null = Add, non-null = Edit
  const SongDialog({super.key, required this.db, this.song});

  @override
  State<SongDialog> createState() => _SongDialogState();
}

class _SongDialogState extends State<SongDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController audioUrlController = TextEditingController();

  List<Artist> artists = [];
  List<Album> albums = [];
  bool isLoading = true;

  String? selectedArtistId;
  String? selectedAlbumId;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.song != null) {
      nameController.text = widget.song!.name;
      selectedArtistId = widget.song!.artistId;
      selectedAlbumId = widget.song!.albumId;
      audioUrlController.text = widget.song!.audioUrl ?? '';
    }
  }

  Future<void> _loadData() async {
    try {
      final artistsData = await widget.db.getArtists();
      final albumsData = await widget.db.getAlbums();
      setState(() {
        artists = artistsData;
        albums = albumsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlertDialog(
        backgroundColor: Colors.grey,
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        widget.song == null ? "Add Song" : "Edit Song",
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Song Name',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter song name" : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedArtistId,
                  decoration: const InputDecoration(
                    hintText: 'Select Artist',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  items: artists.map((artist) {
                    return DropdownMenuItem<String>(
                      value: artist.id,
                      child: Text(
                        artist.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedArtistId = value;
                    });
                  },
                  validator: (val) => val == null ? "Select an artist" : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedAlbumId,
                  decoration: const InputDecoration(
                    hintText: 'Select Album',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  items: albums.map((album) {
                    return DropdownMenuItem<String>(
                      value: album.id,
                      child: Text(
                        album.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAlbumId = value;
                    });
                  },
                  validator: (val) => val == null ? "Select an album" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: audioUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Audio URL',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (widget.song == null) {
                await widget.db.addSong(
                  name: nameController.text,
                  artistId: selectedArtistId!,
                  albumId: selectedAlbumId!,
                  audioUrl: audioUrlController.text,
                );
              } else {
                await widget.db.updateSong(
                  id: widget.song!.id,
                  name: nameController.text,
                  artistId: selectedArtistId!,
                  albumId: selectedAlbumId!,
                  audioUrl: audioUrlController.text,
                );
              }
              Navigator.pop(context, true); // return true to reload
            }
          },
          child: Text(widget.song == null ? "Add" : "Update"),
        ),
      ],
    );
  }
}
