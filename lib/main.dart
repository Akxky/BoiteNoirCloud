import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'package:timer_builder/timer_builder.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); //connecte flutter à firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterFirebase Demo',
      theme: ThemeData(
        
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Firebase Projet cloud'),
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

  PlatformFile? fichierChoisi;
  Future choisirFichier() async {
    final result = await FilePicker.platform.pickFiles();
    if(result == null) return;

    setState((){
      fichierChoisi = result.files.first;
    });
  }

  Future envoyerFichier() async {
    final path = 'images/${fichierChoisi!.name}';
    final fichier = File(fichierChoisi!.path!);

    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(fichier);
  }

  List<PlatformFile> fichiersChoisis = []; // Nouveau
  // Nouveau
  Future<void> choisirFichiers() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    setState(() {
      fichiersChoisis = result.files;  
    });
  }

  Future<void> envoyerFichiers() async {
  if (fichiersChoisis.isEmpty) return;

  final List<Future<void>> futures = [];

  for (final fichier in fichiersChoisis) {
    final path = 'images/${fichier.name}';
    final fichierAEnvoyer = File(fichier.path!);

    final ref = FirebaseStorage.instance.ref().child(path);
    futures.add(ref.putFile(fichierAEnvoyer));
  }

    await Future.wait(futures); // Attendre que toutes les opérations de téléchargement soient terminées
  }

   Future<void> deleteFilesAfterTenMinutes(String directoryPath) async {
    // Obtenir une référence au répertoire dans Firebase Storage
    final storageReference = FirebaseStorage.instance.ref().child(directoryPath);
    /*
    // Obtenir la liste de tous les fichiers dans le répertoire
    final ListResult listResult = await storageReference.listAll();

    // Calculer la date et l'heure d'il y a 10 minutes
    final tenMinutesAgo = DateTime.now().subtract(Duration(minutes: 10));

    // Parcourir la liste des fichiers et supprimer ceux qui datent de plus de 10 minutes
    for (final item in listResult.items) {
      final metadata = await item.getMetadata();
      if (metadata.timeCreated?.isBefore(tenMinutesAgo) ?? false) {
        await item.delete();
      }
    }*/
    try {
      final ListResult listResult = await storageReference.listAll();

      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));

      for (final item in listResult.items) {
        final metadata = await item.getMetadata();
        if (metadata.timeCreated?.isBefore(tenMinutesAgo) ?? false) {
          await item.delete();
        }
      }
    } catch (e) {
      //print('Erreur lors de la suppression des fichiers : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(   
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(     
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if(fichierChoisi != null)
              Expanded(
                child: Container( 
                  color: Colors.blue[100],
                  child: Center(
                    child: Text(fichierChoisi!.name),
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: choisirFichier,
              child: const Text('Choisir un fichier'),  
            ),
            ElevatedButton(
              onPressed: envoyerFichier,
              child: const Text('Envoyer'),  
            ),
            ElevatedButton(
              onPressed: () async {
                await choisirFichiers();
              },
              child: const Text('Choisir des fichiers'),
            ),
            ElevatedButton(
              onPressed: () async {
                await envoyerFichiers();
              },
              child: const Text('Envoyer les fichiers'),
            ),
            PeriodicTaskRunner(task: () async {
              await deleteFilesAfterTenMinutes('images');
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: choisirFichier,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PeriodicTaskRunner extends StatefulWidget {
  final Function task;

  const PeriodicTaskRunner({Key? key, required this.task}) : super(key: key);

  @override
  _PeriodicTaskRunnerState createState() => _PeriodicTaskRunnerState();
}

class _PeriodicTaskRunnerState extends State<PeriodicTaskRunner> {
  @override
  Widget build(BuildContext context) {
    return TimerBuilder.periodic(Duration(minutes: 1), builder: (context) {
      widget.task();
      return const SizedBox.shrink(); // Retourne un widget vide
    });
  }
}