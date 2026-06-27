import 'package:csv/csv.dart';

void main() {
  try {
    const converter = CsvToListConverter();
    print('Const converter created: $converter');
  } catch (e) {
    print('Const failed: $e');
  }

  try {
    var converter2 = CsvToListConverter();
    print('Normal converter created: $converter2');
  } catch (e) {
    print('Normal failed: $e');
  }
}
