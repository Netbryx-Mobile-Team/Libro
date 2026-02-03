import 'package:cloud_firestore/cloud_firestore.dart';



import 'package:libro/exports.dart';

import 'package:libro/features/home/view/widgets/book_grid_view.dart'; // Reusing your grid

class ViewAllBooksScreen extends ConsumerWidget {
  final String title;

  final String collection;

  const ViewAllBooksScreen({
    super.key,

    required this.title,

    required this.collection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: whiteColor,

      appBar: AppBar(
        title: Text(title, style: AppStyles.headingMedium),

        centerTitle: true,

        elevation: 0,

        backgroundColor: whiteColor,

        iconTheme: const IconThemeData(color: blackColor),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collection)
            .orderBy('uploadDate', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No books found."));
          }

          final books = snapshot.data!.docs
              .map(
                (doc) => BookModel.fromMap(
                  doc.data() as Map<String, dynamic>,

                  doc.id,
                ),
              )
              .toList();

          return BookGridView(books: books);
        },
      ),
    );
  }
}
