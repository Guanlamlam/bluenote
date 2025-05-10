import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bluenote/service/sqlite_service.dart';
import 'package:bluenote/screens/lost_found_post_page.dart';
import 'package:bluenote/widgets/guanlam/custom_app_bar.dart';
import 'package:bluenote/widgets/guanlam/bottom_nav_bar.dart';


class DraftScreen extends StatefulWidget {
  const DraftScreen({Key? key}) : super(key: key);

  @override
  _DraftScreenState createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  late Future<List<Map<String, dynamic>>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void _loadDrafts() {
    _draftsFuture = SQLiteService.instance.getAllDrafts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: CustomAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Back Arrow and Title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Draft Post",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Draft List Section
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _draftsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No drafts saved.'));
                    }

                    final drafts = snapshot.data!;

                    return ListView.builder(
                      itemCount: drafts.length,
                      itemBuilder: (context, index) {
                        final row = drafts[index];
                        final id = row['id'] as int;
                        final item = row['item'] as String? ?? '';
                        final type = row['type'] as String? ?? '';
                        final timestamp = row['timestamp'] as String? ?? '';

                        Widget? thumb;
                        if ((row['imagePaths'] as String).isNotEmpty) {
                          final paths = (row['imagePaths'] as String).split(
                              '||');
                          if (paths.isNotEmpty && paths.first.isNotEmpty) {
                            thumb = Image.file(
                              File(paths.first),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            );
                          }
                        }

                        return Dismissible(
                          key: ValueKey(id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                                Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) async {
                            await SQLiteService.instance.deleteDraft(id);
                            setState(_loadDrafts);
                          },
                          child: ListTile(
                            leading: thumb,
                            title: Text(item),
                            subtitle: Text('$type · $timestamp'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LostFoundPostPage(draftId: id),
                                ),
                              ).then((_) {
                                setState(_loadDrafts);
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: BottomNavBar(),
    );
  }
}

