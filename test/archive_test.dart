import 'dart:io';
import 'package:archive/archive_io.dart';

void main() async {
  print("Creating dummy files...");
  await File('test_db.db').writeAsString('dummy db');
  await File('test_salt.salt').writeAsString('dummy salt');
  
  print("Packing...");
  final archive = Archive();
  final dbBytes = await File('test_db.db').readAsBytes();
  final saltBytes = await File('test_salt.salt').readAsBytes();
  
  archive.addFile(ArchiveFile('app_vault.db', dbBytes.length, dbBytes));
  archive.addFile(ArchiveFile('vault.salt', saltBytes.length, saltBytes));
  
  final zipBytes = ZipEncoder().encode(archive);
  await File('test.cvault').writeAsBytes(zipBytes!);
  
  print("Unpacking...");
  final bytes = await File('test.cvault').readAsBytes();
  final decodedArchive = ZipDecoder().decodeBytes(bytes);
  
  print("Archive length: \${decodedArchive.length}");
  for (final file in decodedArchive) {
    if (file.isFile) {
      print("File: \${file.name}");
      try {
        var content = file.content as List<int>;
        print("Content length: \${content.length}");
      } catch (e) {
        print("Error casting content of type \${file.content.runtimeType}: \$e");
      }
    }
  }
}
