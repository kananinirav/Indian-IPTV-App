import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/model/channel.dart';
import 'package:ip_tv/provider/channels_provider.dart';
import 'package:yaml/yaml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Playlist integration', () {
    late String playlistText;

    setUpAll(() async {
      final result = await Process.run(
        'curl',
        [
          '-fsSL',
          ChannelsProvider.playlistUrl,
        ],
      );
      expect(
        result.exitCode,
        0,
        reason: 'Failed to download playlist: ${result.stderr}',
      );
      playlistText = result.stdout as String;
    });

    test(
      'all_channels_available matches remote playlist',
      () async {
        final provider = ChannelsProvider();
        final playlist = _parsePlaylist(playlistText, provider);
        expect(playlist, isNotEmpty);

        final playlistUnique = _dedupeByName(playlist, provider);
        final playlistNames = playlistUnique
            .map((channel) => provider.normalizeName(channel.name))
            .toList();

        final allRaw =
            File('assets/all_channels_available.yml').readAsStringSync();
        final allNames = _parseYamlNames(allRaw, provider);
        expect(allNames, isNotEmpty);
        expect(allNames.length, playlistUnique.length);
        expect(allNames, playlistNames);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    test(
      'filtered list is a subset of the remote playlist',
      () async {
        final provider = ChannelsProvider();
        final playlist = _parsePlaylist(playlistText, provider);
        expect(playlist, isNotEmpty);

        final playlistUnique = _dedupeByName(playlist, provider);
        final playlistIndex = _indexByName(playlistUnique, provider);

        final allRaw =
            File('assets/all_channels_available.yml').readAsStringSync();
        final allNames = _parseYamlNames(allRaw, provider);
        expect(allNames, isNotEmpty);

        final filteredRaw =
            File('assets/filtered_ordered_channels.yml').readAsStringSync();
        final filteredNames = _parseYamlNames(filteredRaw, provider);
        expect(filteredNames, isNotEmpty);
        expect(filteredNames.length, lessThanOrEqualTo(allNames.length));

        final allKeys = allNames.toSet();
        final seen = <String>{};
        for (final name in filteredNames) {
          final key = provider.normalizeName(name);
          expect(allKeys.contains(key), isTrue,
              reason: 'Filtered channel missing in all: $name');
          expect(seen.add(key), isTrue,
              reason: 'Duplicate in filtered list: $name');
          expect(playlistIndex.containsKey(key), isTrue,
              reason: 'Filtered channel missing in playlist: $name');
        }
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });
}

List<Channel> _parsePlaylist(String text, ChannelsProvider provider) {
  final channels = <Channel>[];
  String? name;
  String logoUrl = provider.getDefaultLogoUrl();
  String groupTitle = '';

  for (final rawLine in const LineSplitter().convert(text)) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }
    if (line.startsWith('#EXTINF:')) {
      name = provider.extractChannelName(line);
      logoUrl = provider.extractLogoUrl(line) ?? provider.getDefaultLogoUrl();
      groupTitle = provider.extractGroupTitle(line) ?? '';
      continue;
    }

    if (name == null) {
      continue;
    }

    channels.add(Channel(
      name: name,
      logoUrl: logoUrl,
      streamUrl: line,
      groupTitle: groupTitle,
    ));
    name = null;
    logoUrl = provider.getDefaultLogoUrl();
    groupTitle = '';
  }

  return channels;
}

List<String> _parseYamlNames(String raw, ChannelsProvider provider) {
  final data = loadYaml(raw);
  if (data is! YamlMap) {
    return [];
  }
  final rawChannels = data['channels'];
  if (rawChannels is! YamlList) {
    return [];
  }

  final result = <String>[];
  for (final entry in rawChannels) {
    if (entry == null) {
      continue;
    }
    final name = entry.toString().trim();
    if (name.isEmpty) {
      continue;
    }
    result.add(provider.normalizeName(name));
  }

  return result;
}

List<Channel> _dedupeByName(List<Channel> channels, ChannelsProvider provider) {
  final seen = <String>{};
  final result = <Channel>[];
  for (final channel in channels) {
    final key = provider.normalizeName(channel.name);
    if (key.isEmpty || seen.contains(key)) {
      continue;
    }
    seen.add(key);
    result.add(channel);
  }
  return result;
}

Map<String, Channel> _indexByName(
  List<Channel> channels,
  ChannelsProvider provider,
) {
  final map = <String, Channel>{};
  for (final channel in channels) {
    map.putIfAbsent(provider.normalizeName(channel.name), () => channel);
  }
  return map;
}
