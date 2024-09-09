import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'barcode_scanner_simple.dart';

import 'database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // print(await bdb.books());
  // bdb.insertBook(Book.withIsbn(isbn13: 9791035807191));
  // print(await bdb.books());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const QuickBib());
  print('Huh seems a-synchronous in fact');
}

class QuickBib extends StatelessWidget {
  const QuickBib({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StatefulBookDB(initialize: true),
      child: MaterialApp(
        title: 'QuickBib — Your personal bookbase !',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

//dontpayattention
// class QuickBibState extends ChangeNotifier {
// BookDB bdb = BookDB.instance;
//
// void updateDB() {
// current = WordPair.random();
// notifyListeners();
// }

// get books => bdb.books();
//
// void addBook()
//
// }

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = ScannerPage();
      case 1:
        page = BookBasePage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Symbols.document_scanner),
                    label: Text('Scanner'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Symbols.library_books),
                    label: Text('Bookbase'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class ScannerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<StatefulBookDB>();

    // appState.insertBook(Book.sample);
    // return const Center(child: Text('No input method for the moment'));
    // builder: (context) => BarcodeScannerWithOverlay(),
    return const BarcodeScannerSimple();
  }
}

class BookBasePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<StatefulBookDB>();
    print("Appstate changed, got updated");
    if (appState.books.isEmpty) {
      return const Center(
        child: Text('No books yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.books.length} books in the library:'),
        ),
        for (var book in appState.books)
          ListTile(
            leading: const Icon(Symbols.book_2),
            title: Text(book.title),
          ),
      ],
    );
  }
}

// class BigCard extends StatelessWidget {
  // const BigCard({
    // super.key,
    // required this.pair,
  // });
//
  // final WordPair pair;
//
  // @override
  // Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final style = theme.textTheme.displayMedium!.copyWith(
      // color: theme.colorScheme.onPrimary,
    // );
//
    // return Card(
      // color: theme.colorScheme.primary,
      // child: Padding(
        // padding: const EdgeInsets.all(20),
        // child: Text(
          // pair.asLowerCase,
          // style: style,
          // semanticsLabel: "${pair.first} ${pair.second}",
        // ),
      // ),
    // );
  // }
// }
