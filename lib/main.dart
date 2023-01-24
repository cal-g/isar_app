// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_test_app/schemas/notes.dart';
import 'package:isar_test_app/schemas/sub_notes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      NotesSchema,
      SubNotesSchema,
    ],
    directory: dir.path,
  );
  await isar.writeTxn(() async => await isar.notes.clear());
  await isar.writeTxn(() async => await isar.subNotes.clear());

  var uuid = const Uuid();
  final list = List.generate(20000, (index) => uuid.v4());
  await isar.writeTxn(() async {
    for (int i = 0; i < list.length; i++) {
      await isar.notes.put(
        Notes(
          uuid: list[i],
          name: "Note-$i",
        ),
      );

      await isar.subNotes.put(
        SubNotes(
          uuid: uuid.v4(),
          parentNoteId: list[i],
          name: 'SubNote for Note-$i',
        ),
      );
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final Isar isarInstance;

  var notes = <Notes>[];
  var subNotes = <SubNotes>[];
  var isarSubNoteSubscription = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    isarInstance = Isar.getInstance()!;
  }

  void watchAllNotes() {
    notes.clear();
    subNotes.clear();
    final s = isarInstance.notes.where().build().watch(
          fireImmediately: true,
        );

    s.listen((event) {
      print('event :: ${event.length}');
      notes = event;
      setState(() {});
    });
  }

  void watchSubNotesForEachNote() {
    subNotes.clear();
    final isarSubNotesInstance = isarInstance.subNotes;

    notes.forEach((element) {
      isarSubNoteSubscription.add(
        isarSubNotesInstance
            .filter()
            .parentNoteIdEqualTo(element.uuid, caseSensitive: false)
            .build()
            .watch(fireImmediately: true)
            .listen((event) {
          subNotes.addAll(event);
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          children: [
            const CircularProgressIndicator(),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        onPressed: watchAllNotes,
                        child: const Text('Watch all notes'),
                      ),
                      TextButton(
                        onPressed: watchSubNotesForEachNote,
                        child: const Text('Watch subNotes'),
                      ),
                      TextButton(
                        onPressed: () {
                          print('isar Subnote :: ${subNotes.length}');
                          setState(() {});
                        },
                        child: const Text('Rebuild'),
                      ),
                      TextButton(
                        onPressed: () async {
                          print('cancel');
                          await Future.wait(
                              isarSubNoteSubscription.map((e) => e.cancel()));
                          print('cancelled');
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, index) => SizedBox(
                        // height: 30,
                        child: Column(
                          children: [
                            Text(notes[index].name ?? ""),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                children: subNotes
                                    .where((element) =>
                                        element.parentNoteId ==
                                        notes[index].uuid)
                                    .map((e) => Text(e.name ?? ''))
                                    .toList(),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
