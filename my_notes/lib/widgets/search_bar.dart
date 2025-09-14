import 'package:flutter/material.dart';
import 'package:my_notes/providers/notes_provider.dart';
import 'package:provider/provider.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var notesProvider = Provider.of<NotesProvider>(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: size.height * 0.01),
      width: size.width * 0.7,
      height: size.height * 0.06,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          
          hintText: 'Notlarda ara...',
          hintStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: IconButton(
            onPressed: () {
              _searchController.clear();
              notesProvider.clearSearch();
            },
            icon: Icon(Icons.clear, color: Colors.grey[600]),
          ),
        ),
        onChanged: (value) {
          notesProvider.searchNotes(value);
        },
      ),
    );
  }
}