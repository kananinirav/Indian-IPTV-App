import 'package:flutter/material.dart';
import '../model/channel.dart';
import '../provider/channels_provider.dart';
import '../screens/player.dart';

class ChannelListPage extends StatelessWidget {
  final String groupTitle;

  ChannelListPage({required this.groupTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupTitle),
      ),
      body: ChannelListView(groupTitle: groupTitle),
    );
  }
}

class ChannelListView extends StatelessWidget {
  final String groupTitle;

  ChannelListView({required this.groupTitle});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Channel>>(
      future: ChannelsProvider().getChannelsByGroupTitle(groupTitle),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final channels = snapshot.data ?? [];

        return ListView.builder(
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            return ListTile(
              title: Text(channel.name),
              //subtitle: Text(channel.streamUrl),
              leading: Image.network(channel.logoUrl,width: 55,height: 55,),
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Player(
                      name: channel.name,
                      streamUrl: channel.streamUrl,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}