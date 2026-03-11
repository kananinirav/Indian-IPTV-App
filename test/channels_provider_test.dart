import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/model/channel.dart';
import 'package:ip_tv/provider/channels_provider.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('ChannelsProvider helpers', () {
    test('extractChannelName returns the last comma segment', () {
      final provider = ChannelsProvider();
      const line = '#EXTINF:-1,My Channel HD';
      expect(provider.extractChannelName(line), 'My Channel HD');
    });

    test('extractLogoUrl returns the first valid quoted URL', () {
      final provider = ChannelsProvider();
      const line =
          '#EXTINF:-1 tvg-logo="https://example.com/logo.png",Channel';
      expect(provider.extractLogoUrl(line), 'https://example.com/logo.png');
    });

    test('isValidUrl accepts http/https only', () {
      final provider = ChannelsProvider();
      expect(provider.isValidUrl('http://example.com'), true);
      expect(provider.isValidUrl('https://example.com'), true);
      expect(provider.isValidUrl('ftp://example.com'), false);
    });

    test('filterChannels matches case-insensitively', () {
      final provider = ChannelsProvider();
      provider.channels = [
        Channel(
          name: 'News One',
          logoUrl: 'logo1',
          streamUrl: 'stream1',
        ),
        Channel(
          name: 'Sports Live',
          logoUrl: 'logo2',
          streamUrl: 'stream2',
        ),
        Channel(
          name: 'Daily NEWS 24',
          logoUrl: 'logo3',
          streamUrl: 'stream3',
        ),
      ];

      final results = provider.filterChannels('news');
      expect(results.length, 2);
      expect(results[0].name, 'News One');
      expect(results[1].name, 'Daily NEWS 24');
    });

    test('getDefaultLogoUrl returns the asset path', () {
      final provider = ChannelsProvider();
      expect(provider.getDefaultLogoUrl(), 'assets/images/tv-icon.png');
    });

    test('loadFilteredChannelNames reads names from the filtered asset', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final provider = ChannelsProvider();
      final loaded = await provider.loadFilteredChannelNames();
      expect(loaded, isNotEmpty);

      final rawConfig =
          File('assets/filtered_ordered_channels.yml').readAsStringSync();
      final config = loadYaml(rawConfig) as YamlMap;
      final list = config['channels'] as YamlList;
      final expectedName = list.first.toString();
      expect(loaded.first, expectedName);
    });

    test('filtered list is synchronized with the all channels list', () {
      final allRaw =
          File('assets/all_channels_available.yml').readAsStringSync();
      final filteredRaw =
          File('assets/filtered_ordered_channels.yml').readAsStringSync();

      final allNames = _readYamlNames(allRaw);
      final filteredNames = _readYamlNames(filteredRaw);
      expect(allNames, isNotEmpty);
      expect(filteredNames, isNotEmpty);

      final allSet = allNames.toSet();
      final seen = <String>{};
      for (final name in filteredNames) {
        expect(allSet.contains(name), isTrue,
            reason: 'Missing in all_channels_available.yml: $name');
        expect(seen.add(name), isTrue,
            reason: 'Duplicate in filtered_ordered_channels.yml: $name');
      }
    });
  });
}

List<String> _readYamlNames(String raw) {
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
    result.add(name);
  }

  return result;
}
