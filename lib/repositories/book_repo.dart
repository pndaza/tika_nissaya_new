import 'package:tika_nissaya/models/book.dart';
import 'package:tika_nissaya/repositories/database.dart';

abstract class BookRepository {
  Future<List<Book>> fetchBooks();
}

class DatabaseBookRepository extends BookRepository {
  DatabaseBookRepository(this.databaseProvider, this.bookDao);
  final DatabaseHelper databaseProvider;
  final BookDao bookDao;

  @override
  Future<List<Book>> fetchBooks() async {
    final db = await databaseProvider.database;
    final results = await db.query(bookDao.tableName, columns: [
      bookDao.columnID,
      bookDao.columnName,
      bookDao.columnCategory,
      bookDao.columnFirstPage,
      bookDao.columnLastPage,
      bookDao.columnCount
    ]);
    return bookDao.fromList(results);
  }
}
