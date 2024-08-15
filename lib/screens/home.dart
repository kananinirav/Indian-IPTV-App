import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ip_tv/model/channel.dart';
import 'package:ip_tv/screens/player.dart';

import '../provider/channels_provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> with SingleTickerProviderStateMixin {
  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  TextEditingController searchController = TextEditingController();
  final ChannelsProvider channelsProvider = ChannelsProvider();
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('Live Tv'),
      ),
      body: SingleChildScrollView(child: sampleVideoGrid()),
    ));
  }

  Widget sampleVideoGrid() {
    return SingleChildScrollView(
      child: Column(
        children: [
          GridView(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
            ),
            children: filteredChannels
                .map((channel) => InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => Player(
                              url: channel.streamUrl,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Column(
                            children: [
                              Image.network(
                                channel.logoUrl,
                                height: 150,
                                width: 150,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/tv-icon.png',
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.contain,
                                  );
                                },
                              ),
                              const SizedBox(height: 8.0),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    channel.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          )),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
