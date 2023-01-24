import 'package:isar/isar.dart';

part 'sub_notes.g.dart';

@collection
class SubNotes {
  SubNotes({
    required this.uuid,
    required this.parentNoteId,
    this.name,
  }) : id = Isar.autoIncrement;

  final Id id;

  @Index(unique: true)
  final String uuid;

  final String parentNoteId;

  final String? name;
}
