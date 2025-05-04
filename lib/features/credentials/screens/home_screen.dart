import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'credentials_list_screen.dart';
import 'documents_list_screen.dart';
import 'add_edit_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: TabBarView(
        controller: _tabController,
        children: const [
          CredentialsListScreen(),
          DocumentsListScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.lock),
              text: 'Credentials',
            ),
            Tab(
              icon: Icon(Icons.description),
              text: 'Documents',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () {
          Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditItemScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
} 