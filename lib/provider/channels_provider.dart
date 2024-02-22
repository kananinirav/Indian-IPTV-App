import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/channel.dart';

class ChannelsProvider with ChangeNotifier {
  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  String sourceUrl =
      'https://raw.githubusercontent.com/aniketda/iptv2050/main/iptv';

  Future<List<Channel>> fetchM3UFile() async {
    final response = await http.get(Uri.parse(sourceUrl));
    if (response.statusCode == 200) {
      String fileText = response.body;
      List<String> lines = fileText.split('\n');

      String? name;
      String? logoUrl;
      String? streamUrl;

      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (line.startsWith('#EXTINF:')) {
          List<String> parts = line.split(',');
          name = parts[1];
          List<String> logoParts = parts[0].split('"');
          logoUrl = logoParts.length > 3
              ? logoParts[3]
              : 'https://fastly.picsum.photos/id/125/536/354.jpg?hmac=EYT3s6VXrAoggrr4fXsOIIcQ3Grc13fCmXkqcE2FusY';
        } else if (line.isNotEmpty) {
          streamUrl = line;
          if (name != null && name.isNotEmpty) {
            channels.add(Channel(
              name: name,
              logoUrl: logoUrl ??
                  'https://fastly.picsum.photos/id/928/200/200.jpg?hmac=5MQxbf-ANcu87ZaOn5sOEObpZ9PpJfrOImdC7yOkBlg',
              streamUrl: streamUrl,
            ));
          }
          name = null;
          logoUrl = null;
          streamUrl = null;
        }
      }
      return channels;
    } else {
      throw Exception('Failed to load M3U file');
    }
  }

  List<Channel> filterChannels(String query) {
    filteredChannels = channels
        .where((channel) =>
            channel.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return filteredChannels;
  }
}
