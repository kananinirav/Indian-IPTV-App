import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/channel.dart';

class ChannelsProvider with ChangeNotifier {
  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  Map<String, List<Channel>> channelsByCountry = {};
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
      String country = 'India'; // Default country
      String? category;
      int channelNumber = 1;

      for (String line in lines) {
        if (line.startsWith('#EXTINF:')) {
          name = extractChannelName(line);
          logoUrl = extractLogoUrl(line) ?? getDefaultLogoUrl();
          country = extractCountry(line);
          category = extractCategory(line);
        } else if (line.isNotEmpty) {
          streamUrl = line;
          if (name != null) {
            final channel = Channel(
              name: name,
              logoUrl: logoUrl,
              streamUrl: streamUrl,
              number: channelNumber,
              country: country,
              category: category,
            );
            channels.add(channel);
            
            // Group by country
            if (!channelsByCountry.containsKey(country)) {
              channelsByCountry[country] = [];
            }
            channelsByCountry[country]!.add(channel);
            
            channelNumber++;
          }
          // Reset for next channel
          name = null;
          logoUrl = getDefaultLogoUrl();
          streamUrl = null;
          country = 'India';
          category = null;
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

  String extractCountry(String line) {
    // Try to extract from group-title first
    final groupTitleRegex = RegExp(r'group-title="([^"]+)"');
    final groupMatch = groupTitleRegex.firstMatch(line);
    if (groupMatch != null) {
      return groupMatch.group(1) ?? 'India';
    }

    // Try to extract from tvg-country
    final tvgCountryRegex = RegExp(r'tvg-country="([^"]+)"');
    final countryMatch = tvgCountryRegex.firstMatch(line);
    if (countryMatch != null) {
      String countryCode = countryMatch.group(1) ?? '';
      return convertCountryCodeToName(countryCode);
    }

    return 'India'; // Default
  }

  String extractCategory(String line) {
    final categoryRegex = RegExp(r'tvg-category="([^"]+)"');
    final match = categoryRegex.firstMatch(line);
    return match?.group(1) ?? '';
  }

  static const Map<String, String> _countryCodes = {
    'IN': 'India',
    'US': 'United States',
    'UK': 'United Kingdom',
    'GB': 'United Kingdom',
    'CA': 'Canada',
    'AU': 'Australia',
    'PK': 'Pakistan',
    'BD': 'Bangladesh',
    'NP': 'Nepal',
    'LK': 'Sri Lanka',
    'AE': 'UAE',
    'SA': 'Saudi Arabia',
  };

  String convertCountryCodeToName(String code) {
    return _countryCodes[code.toUpperCase()] ?? code;
  }

  Channel? getChannelByNumber(int number) {
    return channels.cast<Channel?>().firstWhere(
      (channel) => channel!.number == number,
      orElse: () => null,
    );
  }

  List<String> getCountries() {
    return channelsByCountry.keys.toList()..sort();
  }

  List<Channel> getChannelsForCountry(String country) {
    return channelsByCountry[country] ?? [];
  }

  List<Channel> filterChannels(String query) {
    filteredChannels = channels
        .where((channel) =>
            channel.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return filteredChannels;
  }
}
