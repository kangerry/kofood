import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'image_picker_stub.dart';

Future<List<PickedData>> pickImages(int remaining) async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.multiple = true;
  input.click();
  await input.onChange.first;
  final files = input.files;
  if (files == null || files.isEmpty) return [];
  final take = files.take(remaining);
  final result = <PickedData>[];
  for (final f in take) {
    final reader = html.FileReader();
    final c = Completer<Uint8List>();
    reader.onLoadEnd.listen((_) {
      final r = reader.result;
      if (r is Uint8List) {
        c.complete(r);
      } else if (r is ByteBuffer) {
        c.complete(Uint8List.view(r));
      } else if (r is List<int>) {
        c.complete(Uint8List.fromList(r));
      } else {
        c.completeError(StateError('Unsupported file result'));
      }
    });
    reader.readAsArrayBuffer(f);
    final bytes = await c.future;
    result.add(PickedData(f.name, bytes));
  }
  return result;
}
