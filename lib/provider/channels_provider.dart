import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/channel.dart';

class ChannelsProvider with ChangeNotifier {
  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  String sourceUrl =
      'https://raw.githubusercontent.com/FunctionError/PiratesTv/main/combined_playlist.m3u';

  Future<List<Channel>> fetchM3UFile() async {
    final response = await http.get(Uri.parse(sourceUrl));
    if (response.statusCode == 200) {
      String fileText = response.body;
      List<String> lines = fileText.split('\n');

      String? name;
      String logoUrl = getDefaultLogoUrl();
      String? streamUrl;

      for (String line in lines) {
        if (line.startsWith('#EXTINF:')) {
          name = extractChannelName(line);
          logoUrl = extractLogoUrl(line) ?? getDefaultLogoUrl();
        } else if (line.isNotEmpty) {
          streamUrl = line;
          if (name != null) {
            channels.add(Channel(
              name: name,
              logoUrl: logoUrl,
              streamUrl: streamUrl,
            ));
          }
          // Reset for next channel
          name = null;
          logoUrl = getDefaultLogoUrl();
          streamUrl = null;
        }
      }
      return channels;
    } else {
      throw Exception('Failed to load M3U file');
    }
  }

  String getDefaultLogoUrl() {
    return 'assets/images/tv-icon.png';
  }

  String? extractChannelName(String line) {
    List<String> parts = line.split(',');
    return parts.last;
  }

  String? extractLogoUrl(String line) {
    List<String> parts = line.split('"');
    if (parts.length > 1 && isValidUrl(parts[1])) {
      return parts[1];
    } else if (parts.length > 5 && isValidUrl(parts[5])) {
      return parts[5];
    }
    return null;
  }

  bool isValidUrl(String url) {
    return url.startsWith('https') || url.startsWith('http');
  }

  List<Channel> filterChannels(String query) {
    filteredChannels = channels
        .where((channel) =>
            channel.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return filteredChannels;
  }
}
