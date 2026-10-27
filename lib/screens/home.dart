import 'dart:async';

import 'package:flutter/material.dart';
import '/screens/player.dart';
import '../model/channel.dart';
import '../model/stream_source.dart';
import '../provider/channels_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  List<StreamSource> streamSources = [];
  StreamSource? selectedSource;
  TextEditingController searchController = TextEditingController();
  final ChannelsProvider channelsProvider = ChannelsProvider();
  bool _isLoading = true;
  Timer? _debounceTimer;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    fetchStreamSources();
  }

  Future<void> fetchStreamSources() async {
    try {
      final sources = await channelsProvider.fetchStreamSources();
      if (!mounted) return;
      setState(() {
        streamSources = sources;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('There was a problem loading stream categories'),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchChannels(StreamSource source) async {
    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      selectedSource = source;
      searchController.clear();
    });

    try {
      final data = await channelsProvider.fetchM3UFile(source.streamUrl);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        channels = data;
        filteredChannels = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('There was a problem loading channels'),
          ),
        );
      }
      setState(() {
        selectedSource = null;
        _isLoading = false;
      });
    }
  }

  void backToCategories() {
    _loadGeneration++;
    setState(() {
      selectedSource = null;
      channels = [];
      filteredChannels = [];
      searchController.clear();
    });
  }

  void filterChannels(String query) {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final filteredData = channelsProvider.filterChannels(query);
      setState(() {
        filteredChannels = filteredData;
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (selectedSource == null) {
      return _buildCategoryList();
    }

    return _buildChannelList();
  }

  Widget _buildCategoryList() {
    if (streamSources.isEmpty) {
      return const Center(child: Text('No stream categories available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: streamSources.length,
      itemBuilder: (context, index) {
        final source = streamSources[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => fetchChannels(source),
            child: Text(
              source.name,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: backToCategories,
              ),
              Expanded(
                child: Text(
                  selectedSource!.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            onChanged: filterChannels,
            decoration: const InputDecoration(
              labelText: 'Search',
              hintText: 'Search channels...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: filteredChannels.isEmpty
              ? const Center(child: Text('No channels found'))
              : ListView.builder(
                  itemCount: filteredChannels.length,
                  itemBuilder: (context, index) {
                    final channel = filteredChannels[index];
                    final logoUrl = channel.logoUrl;
                    return ListTile(
                      leading: logoUrl.startsWith('http')
                          ? Image.network(
                              logoUrl,
                              width: 50,
                              height: 50,
                              cacheWidth: 100,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset('assets/images/tv-icon.png',
                                      width: 50, height: 50, fit: BoxFit.contain),
                            )
                          : Image.asset('assets/images/tv-icon.png',
                              width: 50, height: 50, fit: BoxFit.contain),
                      title: Text(channel.name),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Player(
                              channel: channel,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
