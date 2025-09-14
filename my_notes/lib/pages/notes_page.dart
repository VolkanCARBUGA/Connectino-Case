
import 'package:flutter/material.dart';
import 'package:my_notes/providers/auth_provider.dart';
import 'package:my_notes/providers/notes_provider.dart';
import 'package:my_notes/widgets/info_container.dart';
import 'package:my_notes/widgets/note_item.dart';
import 'package:my_notes/widgets/search_bar.dart';
import 'package:provider/provider.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  void initState() {
    super.initState();
    // Anlık olarak notları çek (zaten constructor'da yükleniyor ama emin olmak için)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().fetchNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    var notesProvider = Provider.of<NotesProvider>(context);
    var authProvider = Provider.of<AuthProvider>(context);
   
   
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              await authProvider.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/login', 
                  (route) => false
                );
              }
            },
            icon: const Icon(Icons.logout_outlined),
          ),
          if (notesProvider.isSearching)
            Search(),
          IconButton(
            onPressed: () {
              notesProvider.isSearching = !notesProvider.isSearching;
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // Hata mesajları göster
          if (notesProvider.errorMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(size.width * 0.02),
              child: InfoContainer(
                size: size,
                message: notesProvider.errorMessage,
                color: Colors.red[100]!,
                textColor: Colors.red[800]!,
                onClose: () {
                  notesProvider.clearErrorMessage();
                },
              ),
            ),
          if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(size.width * 0.02),
              child: InfoContainer(
                size: size,
                message: authProvider.errorMessage!,
                color: Colors.red[100]!,
                textColor: Colors.red[800]!,
                onClose: () {
                  authProvider.clearErrorMessage();
                },
              ),
            ),
          // Senkronizasyon durumu göster
          if (notesProvider.isSyncing)
            Padding(
              padding: EdgeInsets.all(size.width * 0.02),
              child: InfoContainer(
                size: size,
                message: notesProvider.syncStatus,
                color: Colors.blue[100]!,
                textColor: Colors.blue[800]!,
                onClose: () {
                  notesProvider.clearSyncStatus();
                },
              ),
            ),
          // Sadece notlar boşsa mesaj göster (arama sonucu mesajı yok)
          (!notesProvider.isSearching && notesProvider.notes.isEmpty && !notesProvider.isLoading)
              ? Center(
                  child: InfoContainer(
                    size: size, 
                    message: 'Henüz not bulunmuyor', 
                    color: Colors.blue, 
                    textColor: Colors.white,
                  ),
                )
              : const SizedBox.shrink(),
          notesProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
                    itemCount: notesProvider.isSearching 
                        ? notesProvider.searchResults.length 
                        : notesProvider.notes.length,
                    itemBuilder: (context, index) {
                      final note = notesProvider.isSearching 
                          ? notesProvider.searchResults[index]
                          : notesProvider.notes[index];
                      
                      return NoteItem(
                        size: size,
                        note: note,
                        notesProvider: notesProvider,
                      );
                    },
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yeni not ekleme işlemi
          Navigator.pushNamed(context, '/addNote');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}


