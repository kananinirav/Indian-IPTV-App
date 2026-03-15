import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/screens/player.dart';
import '../model/channel.dart';
import '../provider/channels_provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Map for keyboard key to digit conversion
  final Map<LogicalKeyboardKey, String> _keyToDigit = {
    LogicalKeyboardKey.digit0: '0',
    LogicalKeyboardKey.numpad0: '0',
    LogicalKeyboardKey.digit1: '1',
    LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.digit2: '2',
    LogicalKeyboardKey.numpad2: '2',
    LogicalKeyboardKey.digit3: '3',
    LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.digit4: '4',
    LogicalKeyboardKey.numpad4: '4',
    LogicalKeyboardKey.digit5: '5',
    LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.digit6: '6',
    LogicalKeyboardKey.numpad6: '6',
    LogicalKeyboardKey.digit7: '7',
    LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.digit8: '8',
    LogicalKeyboardKey.numpad8: '8',
    LogicalKeyboardKey.digit9: '9',
    LogicalKeyboardKey.numpad9: '9',
  };

  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  TextEditingController searchController = TextEditingController();
  final ChannelsProvider channelsProvider = ChannelsProvider();
  bool _isLoading = true;
  Timer? _debounceTimer;
  bool _isGroupedView = false;
  String? _selectedCountry;
  String _numberInput = '';
  Timer? _numberInputTimer;
  final FocusNode _focusNode = FocusNode();

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

  void filterChannels(String query) async {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final filteredData = channelsProvider.filterChannels(query);
      setState(() {
        filteredChannels = filteredData;
      });
    });
  }

  void filterByCountry(String? country) {
    setState(() {
      _selectedCountry = country;
      if (country == null) {
        filteredChannels = channels;
      } else {
        filteredChannels = channelsProvider.getChannelsForCountry(country);
      }
    });
  }

  void handleNumberInput(String digit) {
    setState(() {
      _numberInput += digit;
    });

    // Cancel previous timer
    _numberInputTimer?.cancel();

    // Set new timer for 1.5 seconds
    _numberInputTimer = Timer(const Duration(milliseconds: 1500), () {
      navigateToChannel();
    });
  }

  void navigateToChannel() {
    if (_numberInput.isEmpty) return;

    final int? channelNumber = int.tryParse(_numberInput);
    setState(() {
      _numberInput = '';
    });

    if (channelNumber != null) {
      final channel = channelsProvider.getChannelByNumber(channelNumber);
      if (channel != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Player(channel: channel),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Channel #$channelNumber not found')),
        );
      }
    }
  }

  Widget buildChannelListTile(Channel channel) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${channel.number}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Image.network(
            channel.logoUrl,
            width: 50,
            height: 50,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/tv-icon.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              );
            },
          ),
        ],
      ),
      title: Text(channel.name),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Player(channel: channel),
          ),
        );
      },
    );
  }

  Widget buildFlatListView() {
    return ListView.builder(
      itemCount: filteredChannels.length,
      itemBuilder: (context, index) {
        return buildChannelListTile(filteredChannels[index]);
      },
    );
  }

  Widget buildGroupedView() {
    final countries = channelsProvider.getCountries();
    return ListView.builder(
      itemCount: countries.length,
      itemBuilder: (context, index) {
        final country = countries[index];
        final countryChannels = channelsProvider.getChannelsForCountry(country);
        return ExpansionTile(
          leading: const Icon(Icons.flag),
          title: Text(
            country,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${countryChannels.length} channels'),
          children: countryChannels.map((channel) {
            return buildChannelListTile(channel);
          }).toList(),
        );
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _numberInputTimer?.cancel();
    searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          final digit = _keyToDigit[event.logicalKey];
          if (digit != null) {
            handleNumberInput(digit);
          }
        }
      },
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    filterChannels(value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    hintText: 'Search channels...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              // Country filter chips
              if (channelsProvider.getCountries().isNotEmpty)
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedCountry == null,
                          onSelected: (selected) {
                            if (selected) filterByCountry(null);
                          },
                        ),
                      ),
                      ...channelsProvider.getCountries().map((country) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(country),
                            selected: _selectedCountry == country,
                            onSelected: (selected) {
                              if (selected) filterByCountry(country);
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              // Toggle view button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isGroupedView = !_isGroupedView;
                        });
                      },
                      icon: Icon(_isGroupedView ? Icons.list : Icons.folder),
                      label: Text(_isGroupedView ? 'List View' : 'Grouped View'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _isGroupedView
                        ? buildGroupedView()
                        : buildFlatListView(),
              ),
            ],
          ),
          // Number input overlay
          if (_numberInput.isNotEmpty)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _numberInput,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
