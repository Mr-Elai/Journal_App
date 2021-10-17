import 'package:flutter/material.dart';
import 'package:journal_app/pages/edit_entry.dart';
import 'package:journal_app/classes/database.dart';
import 'package:intl/intl.dart'; // Format Dates

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Database _database;
  DatabaseFileRoutines dbf = DatabaseFileRoutines();
  Future<List<Journal>> _loadJournals() async {
    await DatabaseFileRoutines().readJournals().then((journalsJson) {
      _database = dbf.databaseFromJson(journalsJson);
      _database.journal.sort((comp1, comp2) => comp2.date.compareTo(comp1.date)); });
    return _database.journal; }

  void _addOrEditJournal({required bool add, required int index, required Journal journal}) async {
    JournalEdit _journalEdit = JournalEdit(action: '', journal: journal); _journalEdit = await Navigator.push(
    context, MaterialPageRoute(
      builder: (context) => EditEntry( add: add,
        index: index,
        journalEdit: _journalEdit,
      ),
      fullscreenDialog: true ),
  );
  switch (_journalEdit.action) {
    case 'Save': if (add) {
      setState(() { _database.journal.add(_journalEdit.journal);
      });
    } else {
      setState(() {
        _database.journal[index] = _journalEdit.journal;
      }); }
    DatabaseFileRoutines().writeJournals(dbf.databaseToJson(_database));
    break;
    case 'Cancel':
      break; default: break;
  }
  }

  Widget _buildListViewSeparated(AsyncSnapshot snapshot) {
    return ListView.separated(
      itemCount: snapshot.data.length,
      itemBuilder: (BuildContext context, int index) {
        String _titleDate = DateFormat.yMMMd().format(DateTime.parse(snapshot .data[index].date));
        String _subtitle = snapshot.data[index].mood + "\n" + snapshot .data[index].note;
        return Dismissible(
          key: Key(snapshot.data[index].id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 16.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight, padding: EdgeInsets.only(right: 16.0), child: Icon(
            Icons.delete,
            color: Colors.white, ),
          ),
          child: ListTile (
            leading: Column(
              children: <Widget>[
                Text(DateFormat.d().format(DateTime.parse(snapshot.data[index].date)),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 32.0,
                      color: Colors.blue),),
                Text(DateFormat.E().format(DateTime.parse(snapshot.data[index].date))),
              ], ),
            title: Text(
              _titleDate,
              style: TextStyle(fontWeight: FontWeight.bold),
          ),
            subtitle: Text(_subtitle),
            onTap: () {
              _addOrEditJournal( add: false,
                index: index,
                journal: snapshot.data[index], );
            },
          ),
          onDismissed: (direction) { setState(() {
            _database.journal.removeAt(index); });
          DatabaseFileRoutines().writeJournals(dbf.databaseToJson(_database));
          },
        );
        },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(
          color: Colors.grey,
        );
        },);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal App'),
      ),
      body: FutureBuilder(
        initialData: [],
          future: _loadJournals(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return !snapshot.hasData
                ? Center(child: CircularProgressIndicator()) : _buildListViewSeparated(snapshot);
          },
      ),
      bottomNavigationBar: BottomAppBar (
        shape: CircularNotchedRectangle(),
        child: Padding(padding: EdgeInsets.all(24),),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton( tooltip: 'Add Journal Entry',
        onPressed: () {
          _addOrEditJournal(add: true, index: -1, journal: Journal(id: '', date: '', note: '', mood: ''));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}