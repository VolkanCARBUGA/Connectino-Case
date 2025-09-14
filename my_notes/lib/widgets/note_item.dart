import 'package:flutter/material.dart';
import 'package:my_notes/models/note_model.dart';
import 'package:my_notes/providers/notes_provider.dart';
import 'package:my_notes/widgets/button_widget.dart';
import 'package:my_notes/widgets/input_widget.dart';

class NoteItem extends StatelessWidget {
  const NoteItem({
    super.key,
    required this.size,
    required this.note,
    required this.notesProvider,
  });

  final Size size;
  final NoteModel note;
  final NotesProvider notesProvider;

  // Tarihi Türkçe formatında döndüren fonksiyon
  String _formatDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return 'Bugün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (noteDate == today.subtract(const Duration(days: 1))) {
      return 'Dün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          textAlign: TextAlign.center,
          'Not Düzenle',
          style: TextStyle(fontSize: 25),
        ),
        contentPadding: EdgeInsets.all(size.width * 0.02),
        actionsPadding: EdgeInsets.zero,
        buttonPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(10),
            bottom: Radius.circular(10),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputWidget(controller: titleController, hintText: 'Başlık'),
            SizedBox(height: size.height * 0.02),
            InputWidget(
              maxLines: 3,
              controller: contentController,
              hintText: 'İçerik',
            ),
            SizedBox(height: size.height * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ButtonWidget(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  text: 'İptal',
                  color: Colors.red,
                  textColor: Colors.white,
                  width: size.width * 0.2,
                  height: size.height * 0.05,
                ),
                ButtonWidget(
                  text: 'Kaydet',
                  color: Colors.green,
                  textColor: Colors.white,
                  width: size.width * 0.2,
                  height: size.height * 0.05,
                  onPressed: () {
                    // Güncellenmiş notu oluştur
                    final updatedNote = NoteModel(
                      title: titleController.text,
                      content: contentController.text,
                      createdAt: note.createdAt,
                      updatedAt: DateTime.now(),
                      isPinned: note.isPinned,
                      userId: note.userId,
                    );
                    // ID'yi mevcut nottan al
                    updatedNote.id = note.id;

                    notesProvider.updateNote(updatedNote);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            SizedBox(height: size.height * 0.02),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    VoidCallback onPressed,
    String label,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.grey[300],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        content: Text(message,style: TextStyle(color: Colors.black,fontSize: 16),),
        action: SnackBarAction(

          label: label,
          onPressed: onPressed,
          textColor: Colors.white,
          backgroundColor: Colors.green,
        ),
      ),
    );
  }

  void _deleteNote(BuildContext context) {
    notesProvider.deleteNote(note.id);
    _showSnackBar(context, '${note.title} başarıyla silindi', () {
      notesProvider.addNote(note);
    }, 'Geri Al');
  }

  void _togglePin(BuildContext context) {
    notesProvider.togglePinNote(note.id);
    
    final message = note.isPinned ? 'Not sabitlemesi kaldırıldı' : 'Not sabitlendi';
    _showSnackBar(context, message, () {
      // Geri alma işlemi için pin durumunu tekrar değiştir
      notesProvider.togglePinNote(note.id);
    }, 'Geri Al');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: size.width * 0.02,
        vertical: size.height * 0.01,
      ),
      padding: EdgeInsets.all(size.width * 0.02),
      decoration: BoxDecoration(
        color: note.isPinned ? Colors.orange[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: note.isPinned ? Border.all(color: Colors.orange[300]!, width: 1) : null,
      ),

      child: ListTile(
        onTap: () => _showEditDialog(context),
        title: Row(
          children: [
            if (note.isPinned) ...[
              Icon(
                Icons.push_pin,
                color: Colors.orange,
                size: 16,
              ),
              SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                note.title,
                style: TextStyle(
                  fontWeight: note.isPinned ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              note.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: size.height * 0.01),
            Text(
              'Oluşturulma Tarihi: ${_formatDate(note.createdAt)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                _togglePin(context);
              },
              icon: Icon(
                note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: note.isPinned ? Colors.orange : Colors.grey,
                size: 20,
              ),
              tooltip: note.isPinned ? 'Sabitlemeyi kaldır' : 'Sabitle',
            ),
            IconButton(
              onPressed: () {
                _deleteNote(context);
              },
              icon: const Icon(Icons.delete),
              tooltip: 'Sil',
            ),
          ],
        ),
      ),
    );
  }
}
