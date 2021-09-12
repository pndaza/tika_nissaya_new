import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tika_nissaya/models/nsybook.dart';
import 'package:tika_nissaya/screens/nsy_list/nsy_choice_providers.dart';

class NsyChoice extends ConsumerWidget {
  NsyChoice({required this.paliBookID, required this.paliBookPageNumber});
  final String paliBookID;
  final int paliBookPageNumber;

  @override
  Widget build(BuildContext context, watch) {
    final nsyBookState =
        watch(nsyBooksProvider('$paliBookID-$paliBookPageNumber'));
    return Scaffold(
      appBar: AppBar(
        title: const Text('နိဿယ​မူကွဲများ'),
      ),
      body: nsyBookState.when(
          data: (data) {
            return _buildBookShelf(data);
          },
          loading: () => Center(
                child: CircularProgressIndicator(),
              ),
          error: (_, __) => Center(
                child: Text("Something's wrong!"),
              )),
    );
  }

  Widget _buildBookShelf(List<NsyBook> nsyBooks) {
    return GridView.extent(
        maxCrossAxisExtent: 250,
        childAspectRatio: 0.65,
        children: nsyBooks
            .map((nsyBook) => GridItem(
                  nsyBook: nsyBook,
                ))
            .toList());
  }
}

class GridItem extends StatelessWidget {
  const GridItem({Key? key, required this.nsyBook}) : super(key: key);
  final NsyBook nsyBook;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read(nsyChoiceViewController).openBook(context, nsyBook);
      },
      child: Card(
        margin: EdgeInsets.all(4),
        // color: Colors.blueGrey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Image(
                image: AssetImage('assets/books/cover/${nsyBook.id}.png'),
                fit: BoxFit.fill,
              ),
              Container(
                height: 5,
              ),
              Expanded(child: Text('${nsyBook.name}'))
            ],
          ),
        ),
      ),
    );
  }
}
