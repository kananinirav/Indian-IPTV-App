import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/channel.dart';

class ChannelsProvider with ChangeNotifier {
  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  String sourceUrl =
      'https://raw.githubusercontent.com/aniketda/iptv2050/main/iptv';

  Future<List<String>> getGroupTitles() async {
    await fetchM3UFile(); // Fetch channels if not already fetched
    Set<String> groupTitleSet = channels
        .map((channel) => channel.groupTitle ?? 'Other') // Replace null group titles with a default value, e.g., 'Other'
        .toSet();
    return groupTitleSet.toList();
  }

  Future<List<Channel>> getChannelsByGroupTitle(String groupTitle) async {
    await fetchM3UFile(); // Fetch channels if not already fetched
    return channels.where((channel) => channel.groupTitle == groupTitle).toList();
  }
  Future<List<Channel>> fetchM3UFile() async {
    final response = await http.get(Uri.parse(sourceUrl));
    if (response.statusCode == 200) {
      String fileText = response.body;
      List<String> lines = fileText.split('\n');

      String? name;
      String? logoUrl;
      String? streamUrl;
      String? groupTitle;

      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (line.startsWith('#EXTINF:')) {
          List<String> parts = line.split(',');
          name = parts.last;
          // Extract group title
          groupTitle = _extractValueFromTag(line, 'group-title');
          // Extract logo URL
          logoUrl = _extractValueFromTag(line, 'tvg-logo');
        } else if (line.isNotEmpty && !line.startsWith('#')) {
          streamUrl = line;
          if (name != null && name.isNotEmpty && streamUrl != null && streamUrl.isNotEmpty) {
            channels.add(Channel(
              name: name,
              logoUrl: logoUrl ?? 'https://fastly.picsum.photos/id/928/200/200.jpg?hmac=5MQxbf-ANcu87ZaOn5sOEObpZ9PpJfrOImdC7yOkBlg',
              streamUrl: streamUrl,
              groupTitle: groupTitle ?? 'Other',
            ));
          }
          // Reset variables
          name = null;
          logoUrl = null;
          streamUrl = null;
          groupTitle = null;
        }
      }
      return channels;
    } else {
      throw Exception('Failed to load M3U file');
    }
  }

  String? _extractValueFromTag(String line, String tagName) {
    RegExp regex = RegExp('$tagName="([^"]+)"');
    Match? match = regex.firstMatch(line);
    return match?.group(1);
  }

  List<Channel> filterChannels(String query) {
    filteredChannels = channels
        .where((channel) =>
            channel.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return filteredChannels;
  }
}
