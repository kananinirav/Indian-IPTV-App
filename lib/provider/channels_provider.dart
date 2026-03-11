import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

import '../model/channel.dart';

class ChannelsProvider with ChangeNotifier {
  static const String playlistUrl =
      'https://raw.githubusercontent.com/FunctionError/PiratesTv/main/combined_playlist.m3u';
  static const String _filteredChannelsAsset =
      'assets/filtered_ordered_channels.yml';

  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  String sourceUrl = playlistUrl;

  Future<List<Channel>> fetchM3UFile() async {
    final filteredNames = await loadFilteredChannelNames();
    final remoteIndex = await _fetchRemoteChannels();
    final result = <Channel>[];
    final seen = <String>{};

    for (final name in filteredNames) {
      final key = normalizeName(name);
      if (key.isEmpty || seen.contains(key)) {
        continue;
      }
      seen.add(key);
      final remote = remoteIndex[key];
      if (remote == null) {
        result.add(Channel(
          name: name,
          logoUrl: getDefaultLogoUrl(),
          streamUrl: '',
          groupTitle: '',
        ));
      } else {
        result.add(Channel(
          name: name,
          logoUrl: remote.logoUrl,
          streamUrl: remote.streamUrl,
          groupTitle: remote.groupTitle,
        ));
      }
    }

    channels = result;
    filteredChannels = result;
    return channels;
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

  String? extractGroupTitle(String line) {
    final matches = RegExp(r'group-title="([^"]*)"').allMatches(line);
    for (final match in matches) {
      final value = match.group(1);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  bool isValidUrl(String url) {
    return url.startsWith('https') || url.startsWith('http');
  }

  String normalizeName(String value) {
    final lower = value.toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    return cleaned.replaceAll(RegExp(r'\s+'), ' ');
  }

  List<Channel> filterChannels(String query) {
    filteredChannels = channels
        .where((channel) =>
            channel.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return filteredChannels;
  }

  Future<List<String>> loadFilteredChannelNames() async {
    return _loadChannelNamesFromAsset(_filteredChannelsAsset);
  }

  Future<List<String>> _loadChannelNamesFromAsset(String path) async {
    final raw = await rootBundle.loadString(path);
    final data = loadYaml(raw);
    return _namesFromYaml(data);
  }

  List<String> _namesFromYaml(dynamic data) {
    final rawList = _extractChannelsList(data);
    if (rawList == null) {
      return [];
    }

    final names = <String>[];
    final seen = <String>{};
    for (final entry in rawList) {
      if (entry == null) {
        continue;
      }
      final name = entry.toString().trim();
      if (name.isEmpty) {
        continue;
      }
      final key = normalizeName(name);
      if (key.isEmpty || seen.contains(key)) {
        continue;
      }
      seen.add(key);
      names.add(name);
    }

    return names;
  }

  YamlList? _extractChannelsList(dynamic data) {
    if (data is YamlList) {
      return data;
    }
    if (data is YamlMap) {
      final raw = data['channels'];
      if (raw is YamlList) {
        return raw;
      }
    }
    return null;
  }

  Future<Map<String, Channel>> _fetchRemoteChannels() async {
    final response = await http.get(Uri.parse(sourceUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load M3U file');
    }
    final parsed = _parsePlaylist(response.body);
    final index = <String, Channel>{};
    for (final channel in parsed) {
      final key = normalizeName(channel.name);
      index.putIfAbsent(key, () => channel);
    }
    return index;
  }

  List<Channel> _parsePlaylist(String text) {
    final result = <Channel>[];
    String? name;
    String logoUrl = getDefaultLogoUrl();
    String groupTitle = '';

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }
      if (line.startsWith('#EXTINF:')) {
        name = extractChannelName(line);
        logoUrl = extractLogoUrl(line) ?? getDefaultLogoUrl();
        groupTitle = extractGroupTitle(line) ?? '';
        continue;
      }

      if (name == null) {
        continue;
      }

      result.add(Channel(
        name: name,
        logoUrl: logoUrl,
        streamUrl: line,
        groupTitle: groupTitle,
      ));
      name = null;
      logoUrl = getDefaultLogoUrl();
      groupTitle = '';
    }

    return result;
  }
}
