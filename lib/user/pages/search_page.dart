import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';
import '../widgets/playing_song_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final db = DatabaseService();
  List<Song> searchResults = [];
  final TextEditingController _controller = TextEditingController();

  void search(String query) async {
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }
    final results = await db.searchSongs(query);
    setState(() => searchResults = results);
  }

  void _playSong(Song song) {
    final service = AudioPlayerService();
    // Set search results as the current playlist
    service.setPlaylist(searchResults);
    service.playSong(song);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NowPlayingPage(song: song),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
     
      appBar: AppBar(
        backgroundColor:Colors.transparent,
        elevation: 0,
        toolbarHeight: 60, 
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 10.0), 
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _controller,
              onChanged: search,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search songs...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                prefixIcon: Icon(Icons.search, color: Colors.green),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: IconButton(
                icon: const Icon(Icons.clear, color: Colors.white70),
                onPressed: () {
                  _controller.clear();
                  search('');
                },
              ),
            ),
        ],
      ),
      body: searchResults.isEmpty && _controller.text.isNotEmpty
          ? const Center(
              child: Text(
                'No results found',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final song = searchResults[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: song.albumImage != null
                        ? Image.network(
                            song.albumImage!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note, color: Colors.green),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, color: Colors.green),
                          ),
                  ),
                  title: Text(
                    song.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    song.artistName ?? 'Unknown Artist',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () => _playSong(song),
                );
              },
            ),
    );
  }
}