import 'package:isar/isar.dart';
part 'note_model.g.dart';

@collection
class NoteModel {
  Id id = Isar.autoIncrement;
  String title;
  String content;
  bool isPinned;
  String userId;
  DateTime createdAt;
  DateTime? updatedAt;

  NoteModel({
    required this.title,
    required this.content,
    required this.isPinned,
    required this.userId,
    this.updatedAt,
    required this.createdAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isPinned: json['isPinned'] ?? false,
      userId: json['userId'] ?? '',
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    )..id = json['id'] ?? Isar.autoIncrement;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isPinned': isPinned,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  NoteModel copyWith({
    Id? id,
    String? title,
    String? content,
    bool? isPinned,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    )..id = id ?? this.id;
  }
}