import 'dart:async';

import 'package:flutter/material.dart';
import '/screens/player.dart';
import '../model/channel.dart';
import '../provider/channels_provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  TextEditingController searchController = TextEditingController();
  final ChannelsProvider channelsProvider = ChannelsProvider();
  bool _isLoading = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final data = await channelsProvider.fetchM3UFile();
      setState(() {
        channels = data;
        filteredChannels = data;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('There was a problem finding the data')));
    }
  }

  void filterChannels(String query) async {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final filteredData = channelsProvider.filterChannels(query);
      setState(() {
        filteredChannels = filteredData;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              filterChannels(value);
            },
            decoration: const InputDecoration(
              labelText: 'Search',
              hintText: 'Search channels...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : ListView.builder(
                  itemCount: filteredChannels.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Image.network(
                        filteredChannels[index].logoUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/tv-icon.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                      title: Text(filteredChannels[index].name),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Player(
                              channel: filteredChannels[index],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
