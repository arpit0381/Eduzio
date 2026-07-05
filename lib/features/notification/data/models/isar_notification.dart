import 'package:isar/isar.dart';

part 'isar_notification.g.dart';

@collection
class CachedNotification6200 {
  Id id = Isar.autoIncrement;

  @Index(name: 'remoteId1700', unique: true, replace: true)
  String? remoteId;

  late String title;
  late String body;
  late DateTime receivedAt;
  late bool isRead;
  
  String? type;      // e.g. "homework", "fee", "attendance"
  String? screen;    // e.g. "/homework", "/fees", "/attendance"
  String? payload;   // Serialized JSON map
}
