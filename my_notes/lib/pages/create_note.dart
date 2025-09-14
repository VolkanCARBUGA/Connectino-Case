import 'package:flutter/material.dart';
import 'package:my_notes/models/note_model.dart';
import 'package:my_notes/providers/auth_provider.dart';
import 'package:my_notes/providers/notes_provider.dart';
import 'package:my_notes/widgets/button_widget.dart';
import 'package:my_notes/widgets/info_container.dart';
import 'package:my_notes/widgets/input_widget.dart';
import 'package:provider/provider.dart';

class CreateNote extends StatefulWidget {
  const CreateNote({super.key});

  @override
  State<CreateNote> createState() => _CreateNoteState();
}

class _CreateNoteState extends State<CreateNote> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
 void _addNote(dynamic authProvider,dynamic notesProvider)async {
  try {
    if(_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty){
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Başlık ve içerik boş olamaz!')),
        );
      }
      return;
    }
    final userId = authProvider.user?.uid ?? "guest";
    final newNote = NoteModel(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      isPinned: false,
        userId: userId, createdAt: DateTime.now(),
      );
      
      // Kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not local storage\'a kaydediliyor...')),
        );
      }
      
      await notesProvider.addNote(newNote);
      
      // Not başarıyla eklendikten sonra biraz bekle ve sayfayı kapat
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not başarıyla eklendi!')),
        );
        // Kısa bir gecikme ekle
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pop(context);
      }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }
     
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var notesProvider = Provider.of<NotesProvider>(context);
    var authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Note')),
      body: Column(
        children: [
          SizedBox(height: size.height * 0.05),

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

          Column(
           
            children: [
              InputWidget(controller: _titleController, hintText: 'Title'),
              SizedBox(height: size.height * 0.02),
              InputWidget(controller: _contentController,
              maxLines: 2,
               hintText: 'Content'),
              SizedBox(height: size.height * 0.02),

               ButtonWidget(
                 text: 'Create Note',
                 color: Colors.green,
                 textColor: Colors.white,
                 width: size.width * 0.9,
                 height: size.height * 0.07,
                 isLoading: notesProvider.isLoading,
                 onPressed: () async {
                  _addNote(authProvider,notesProvider);
                 },
               )
            ],
          ),
        ],
      ),
    );
  }
}
