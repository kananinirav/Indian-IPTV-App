import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/channel.dart';
import '../model/stream_source.dart';

class ChannelsProvider with ChangeNotifier {
  static const streamsCatalogUrl =
      'https://raw.githubusercontent.com/kananinirav/Indian-IPTV-App/refs/heads/master/data/streams.csv';

  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  final _playlistCache = LinkedHashMap<String, List<Channel>>();

  Future<List<StreamSource>> fetchStreamSources() async {
    final response = await http
        .get(Uri.parse(streamsCatalogUrl))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to load stream sources');
    }

    final sources = <StreamSource>[];
    final lines = response.body.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase().startsWith('name,')) {
        continue;
      }

      final commaIndex = trimmed.indexOf(',');
      if (commaIndex == -1) continue;

      final name = trimmed.substring(0, commaIndex).trim();
      final streamUrl = trimmed.substring(commaIndex + 1).trim();
      if (name.isNotEmpty && streamUrl.isNotEmpty) {
        sources.add(StreamSource(name: name, streamUrl: streamUrl));
      }
    }

    return sources;
  }

  Future<List<Channel>> fetchM3UFile(String sourceUrl) async {
    final cached = _playlistCache[sourceUrl];
    if (cached != null) {
      _playlistCache.remove(sourceUrl);
      _playlistCache[sourceUrl] = cached;
      channels = cached;
      filteredChannels = cached;
      return cached;
    }

    final response = await http
        .get(Uri.parse(sourceUrl))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final loadedChannels = await compute(_parseM3U, response.body);
      channels = List.unmodifiable(loadedChannels);
      filteredChannels = channels;
      _playlistCache[sourceUrl] = channels;
      while (_playlistCache.length > 2) {
        _playlistCache.remove(_playlistCache.keys.first);
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
    return parts.last.trim();
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
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      filteredChannels = channels;
      return filteredChannels;
    }
    filteredChannels = channels
        .where((channel) =>
            channel.name.toLowerCase().contains(normalizedQuery))
        .toList();
    return filteredChannels;
  }
}

List<Channel> _parseM3U(String fileText) {
  final loadedChannels = <Channel>[];
  String? name;
  var logoUrl = 'assets/images/tv-icon.png';

  for (final rawLine in fileText.split('\n')) {
    final line = rawLine.trim();
    if (line.startsWith('#EXTINF:')) {
      name = line.split(',').last.trim();
      final quotedValues = line.split('"');
      logoUrl = 'assets/images/tv-icon.png';
      for (var i = 1; i < quotedValues.length; i += 2) {
        final candidate = quotedValues[i];
        if (candidate.startsWith('http://') || candidate.startsWith('https://')) {
          logoUrl = candidate;
          break;
        }
      }
    } else if (line.isNotEmpty && !line.startsWith('#')) {
      if (name != null) {
        loadedChannels.add(Channel(
          name: name,
          logoUrl: logoUrl,
          streamUrl: line,
        ));
      }
      name = null;
      logoUrl = 'assets/images/tv-icon.png';
    }
  }

  return loadedChannels;
}
