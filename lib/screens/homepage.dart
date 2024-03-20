import 'package:flutter/material.dart';
import 'package:ip_tv/screens/home.dart';
import '../provider/channels_provider.dart';
import '../model/channel.dart';
import '../widget/group_card.dart';

class GroupTitleListView extends StatefulWidget {
  const GroupTitleListView({super.key});

  @override
  _GroupTitleListViewState createState() => _GroupTitleListViewState();
}

class _GroupTitleListViewState extends State<GroupTitleListView> {
  late Future<List<String>> _groupTitlesFuture;

  @override
  void initState() {
    super.initState();
    _groupTitlesFuture = ChannelsProvider().getGroupTitles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Channel List'),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => const Search()));
          },
          child: const Icon(Icons.search)),
      body: FutureBuilder<List<String>>(
        future: _groupTitlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final groupTitles = snapshot.data ?? [];

          return ListView.builder(
            itemCount: groupTitles.length,
            itemBuilder: (context, index) {
              final groupTitle = groupTitles[index];
              return FutureBuilder<List<Channel>>(
                future: ChannelsProvider().getChannelsByGroupTitle(groupTitle),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text(groupTitle),
                      subtitle: const CircularProgressIndicator(),
                      leading: const Icon(Icons.folder),
                    );
                  }
                  if (snapshot.hasError) {
                    return ListTile(
                      title: Text(groupTitle),
                      subtitle: Text('Error: ${snapshot.error}'),
                      leading: const Icon(Icons.error),
                    );
                  }
                  const defaultLogoUrl =
                      'https://fastly.picsum.photos/id/928/200/200.jpg?hmac=5MQxbf-ANcu87ZaOn5sOEObpZ9PpJfrOImdC7yOkBlg';
                  final channels = snapshot.data ?? [];
                  final logoUrl = channels.isNotEmpty
                      ? channels[0].logoUrl
                      : defaultLogoUrl;
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ChannelListPage(groupTitle: groupTitle),
                        ),
                      );
                    },
                    child: Card(
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.network(
                              logoUrl,
                              width: 48, // Adjust the width as needed
                              height: 48, // Adjust the height as needed
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 8.0),
                              child: Text(
                                groupTitle,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
