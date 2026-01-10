import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            onChanged: search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search songs...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: searchResults.isEmpty
              ? const Center(
                  child: Text(
                    'No results',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final song = searchResults[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.music_note,
                        color: Colors.green,
                      ),
                      title: Text(
                        song.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: song.artistName != null
                          ? Text(
                              song.artistName!,
                              style: const TextStyle(color: Colors.grey),
                            )
                          : null,
                      onTap: () {
                        // TODO: Play song
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
