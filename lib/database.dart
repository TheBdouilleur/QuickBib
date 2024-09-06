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

  final DateTime pubDate;
  final DateTime discoveryDate;

  static final Book sample = Book(
      id: 979000000000,
      isbn13: 979000000000,
      title: "Sample Book",
      author: "John Doe",
      publisher: "Publishing Co.",
      pubDate: DateTime.utc(1970, 1, 1),
      discoveryDate: DateTime.utc(1970, 1, 1));

  /// Sets the discovery date to the current date unless provided
  Book({
    required this.id,
    this.isbn13,
    required this.title,
    required this.author,
    required this.publisher,
    required this.pubDate,
    DateTime? discoveryDate,
  }) : discoveryDate = discoveryDate ?? DateTime.now();

  /// Creates a new Book instance with the given ISBN, using Book.sample as a template
  /// DiscDate is assumed now() because the method is intended to be used when scanning only
  Book.withIsbn({required int this.isbn13})
      : id = isbn13,
        title = Book.sample.title,
        author = Book.sample.author,
        publisher = Book.sample.publisher,
        pubDate = Book.sample.pubDate,
        discoveryDate = DateTime.now();

  /// Requires the the map to contain dates as ints containing milliseconds since epoch
  /// Behavior is unspecified otherwise
  Book.fromMap({required Map<String, Object?> properties})
      : isbn13 = properties['isbn13'] as int,
        id = properties['id'] as int,
        title = properties['title'] as String,
        author = properties['author'] as String,
        publisher = properties['publisher'] as String,
        pubDate = DateTime.fromMillisecondsSinceEpoch(
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
      'publicationDate': pubDate.millisecondsSinceEpoch,
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
class StatefulBookDB extends ChangeNotifier {
  static const String DB_FILENAME = 'books_db.db';

  /// Will be replaced by an instance variable in a future release
  static const String TABLE_NAME = 'books';
  // For the moment dates are stored as number of seconds since Epoch
  static const String SQL_INITIALISATION_INSTRUCTION =
      'CREATE TABLE $TABLE_NAME(id INTEGER PRIMARY KEY, isbn13 INTEGER, title TEXT, author TEXT, publisher TEXT, publicationDate INTEGER, discoveryDate INTEGER)';

  // isInitialized is tri-state : null means ensureInitialized has never been called,
  // incomplete that it is being called, and complete that it has successfully finished
  Future<void>? _isInitialized;
  late Database _database;
  var _books = <Book>{};

  /// Triggers BDB initialization — without awaiting it — iff initialize is set
  StatefulBookDB({bool initialize = false}) {
    _books = {};
    if (initialize) ensureInitialized();
  }

  Set<Book> get books => _books;

  /// Public wrapper to _ensureInitialized that ensures it is called only once
  /// This way `await ensureInitialized()` doesn't do anything nor take any time once it has been called
  Future<void> ensureInitialized() async {
    _isInitialized ??= _ensureInitialized();
    return _isInitialized;
  }

  /// Method that opens the database and triggers the refreshing of the books
  /// DO NOT use it directly unless you want to _re_initialize the BDB
  Future<void> _ensureInitialized() async {
    WidgetsFlutterBinding.ensureInitialized();
    _database = await openDatabase(
      join(await getDatabasesPath(), DB_FILENAME),
      onCreate: (db, version) => _creation(db, version),
      version: 1,
    );
    print('..., i just tried to initialize, here\'s _database: $_database');

    // Triggering the refreshing is enough, as it will notify listeners itself when it finishes
    _refreshBooks();
  }

  ///temporary: debug shit
  void _creation(Database db, int version) {
    print("YOHO created");
    db.execute(SQL_INITIALISATION_INSTRUCTION).then((_) {
      // return insertBook(Book.withIsbn(isbn13: 9791035807191));
      return print("YOHO ex-cuted");
    });
  }

  ///Syncs the contents of the DB into the getter `books`
  Future<void> _refreshBooks() async {
    await ensureInitialized();
    print("Fetching thy books Master");

    final List<Map<String, Object?>> bookMaps =
        await _database.query(TABLE_NAME);

    _books = bookMaps.map((bm) => Book.fromMap(properties: bm)).toSet();
    print("Here goeth thy books: $_books");
    notifyListeners();
  }

  /// adds an entry for the book inside the DB
  Future<void> insertBook(Book book) async {
    await ensureInitialized();

    await _database.insert(
      TABLE_NAME,
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _refreshBooks();
  }
}
