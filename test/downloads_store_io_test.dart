import 'dart:io';

import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/downloads/data/audio_file_store.dart';
import 'package:ar_rayaan/features/downloads/data/audio_file_store_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('ar_dl'));
  tearDown(() => dir.delete(recursive: true));

  IoAudioFileStore store(http.Client c) =>
      IoAudioFileStore(client: c, dirFor: (ReciterPack _) async => dir);

  test('save stores, lists, plays and removes an ayah', () async {
    final IoAudioFileStore s = store(
      MockClient((_) async => http.Response.bytes(<int>[1, 2, 3], 200)),
    );
    const AyahRef r = AyahRef(1, 1);
    expect(await s.save(ReciterPack.alHusary, r), SaveOutcome.stored);
    expect(await s.storedFiles(ReciterPack.alHusary), <String>{'001001.mp3'});
    expect(await s.playable(ReciterPack.alHusary, r), endsWith('001001.mp3'));
    await s.remove(ReciterPack.alHusary, <AyahRef>[r]);
    expect(await s.storedFiles(ReciterPack.alHusary), isEmpty);
    expect(await s.playable(ReciterPack.alHusary, r), isNull);
  });

  test('a 404, an empty body or a network error is a failure', () async {
    const AyahRef r = AyahRef(1, 2);
    expect(
      await store(MockClient((_) async => http.Response('x', 404)))
          .save(ReciterPack.alHusary, r),
      SaveOutcome.failed,
    );
    expect(
      await store(MockClient((_) async => http.Response.bytes(<int>[], 200)))
          .save(ReciterPack.alHusary, r),
      SaveOutcome.failed,
    );
    expect(
      await store(MockClient((_) async => throw const SocketException('x')))
          .save(ReciterPack.alHusary, r),
      SaveOutcome.failed,
    );
    expect(dir.listSync(), isEmpty);
  });

  test('an already stored ayah is not fetched again', () async {
    int calls = 0;
    final IoAudioFileStore s = store(
      MockClient((_) async {
        calls++;
        return http.Response.bytes(<int>[1], 200);
      }),
    );
    await s.save(ReciterPack.alHusary, const AyahRef(1, 3));
    await s.save(ReciterPack.alHusary, const AyahRef(1, 3));
    expect(calls, 1);
  });

  test('half-written and empty files are not counted', () async {
    File('${dir.path}/001001.mp3.part').writeAsBytesSync(<int>[1]);
    File('${dir.path}/001002.mp3').writeAsBytesSync(<int>[]);
    expect(
      await store(MockClient((_) async => http.Response('', 500)))
          .storedFiles(ReciterPack.alHusary),
      isEmpty,
    );
  });
}
