import 'package:isar/isar.dart';

part 'notes.g.dart';

@collection
class Notes {
  Notes({
    required this.uuid,
    this.name,
  }) : id = Isar.autoIncrement;
  final Id id;

  @Index(unique: true)
  final String uuid;

  final String? name;
}
