import 'package:libro/exports.dart';
import 'package:libro/features/upload/view/widgets/book_upload_form.dart';

class UploadMainScreen extends StatelessWidget {
  final int initialTabIndex; // Added to control which tab opens first

  const UploadMainScreen({
    super.key,
    this.initialTabIndex = 0, // Default is 0 (Sell)
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTabIndex, // Set the initial index here
      child: Scaffold(
        backgroundColor: whiteColor,
        appBar: AppBar(
          title: Text("Upload Book", style: AppStyles.headingMedium),
          centerTitle: true,
          elevation: 0,
          backgroundColor: whiteColor,
          bottom: TabBar(
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryColor,
            indicatorWeight: 3,
            labelStyle: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: "Sell"),
              Tab(text: "Rent"),
              Tab(text: "Exchange"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BookUploadForm(uploadType: 'Sell'),
            BookUploadForm(uploadType: 'Rent'),
            BookUploadForm(uploadType: 'Exchange'),
          ],
        ),
      ),
    );
  }
}
