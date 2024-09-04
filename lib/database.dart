// Current retrieval strategy :
// GET https://isbnsearch.org/isbn/9791035807191
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Book {
  // TODO merge id and isbn13
  final int id;
  final int? isbn13;

  final String title;
  final String author;
  final String publisher;

  final DateTime publicationDate;
  final DateTime discoveryDate;

  const Book(
      {required this.id,
      this.isbn13,
      required this.title,
      required this.author,
      required this.publisher,
      required this.publicationDate,
      required this.discoveryDate});

  /// Currently sets all fields to blank and dates to Epoch
  Book.withIsbn({required int this.isbn13})
      : id = isbn13,
        title = "",
        author = "",
        publisher = "",
        publicationDate = DateTime.utc(1970, 1, 1),
        discoveryDate = DateTime.utc(1970, 1, 1);

  /// Requires the the map to contain dates as ints containing milliseconds since epoch
  Book.fromMap({required Map<String, Object?> properties})
      : isbn13 = properties['isbn13'] as int,
        id = properties['id'] as int,
        title = properties['title'] as String,
        author = properties['author'] as String,
        publisher = properties['publisher'] as String,
        publicationDate = DateTime.fromMillisecondsSinceEpoch(
            properties['publicationDate'] as int),
        discoveryDate = DateTime.fromMillisecondsSinceEpoch(
            properties['discoveryDate'] as int);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'isbn13': isbn13,
      'title': title,
      'author': author,
      'publisher': publisher,
      'publicationDate': publicationDate.millisecondsSinceEpoch,
      'discoveryDate': discoveryDate.millisecondsSinceEpoch
    };
  }

  @override
  String toString() {
    // FIXME see if map's toString is effectively overriden
    return toMap().toString();
  }
}

///    Singleton class used to interface with the books database
class BookDB {
  BookDB._privateConstructor();

  static const String DB_FILENAME = 'books_db.db';
  static const String TABLE_NAME = 'books';
  // For the moment dates are stored as number of seconds since Epoch
  static const String SQL_INITIALISATION_INSTRUCTION =
      'CREATE TABLE $TABLE_NAME(id INTEGER PRIMARY KEY, isbn13 INTEGER, title TEXT, author TEXT, publisher TEXT, publicationDate INTEGER, discoveryDate INTEGER)';
  static final BookDB instance = BookDB._privateConstructor();

  Future<Database>? _database;

  Future<void> ensureInitialized() async {
    WidgetsFlutterBinding.ensureInitialized();
    print('Just got asked, database: $_database, ...');
    _database = openDatabase(
      join(await getDatabasesPath(), DB_FILENAME),
      onCreate: (db, version) {
        return db.execute(SQL_INITIALISATION_INSTRUCTION);
      },
      version: 1,
    );
    print('..., i just tried to initialize, here\'s _database: $_database');
  }

  Future<void> insertBook(Book book) async {
    final db = await _database;

    // FIXME find a way to get rid of this ugly !
    await db!.insert(
      TABLE_NAME,
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Set<Book>> books() async {
    final db = await _database;

    final List<Map<String, Object?>> bookMaps = await db!.query(TABLE_NAME);

    return bookMaps.map((bm) => Book.fromMap(properties: bm)).toSet();
  }
}
