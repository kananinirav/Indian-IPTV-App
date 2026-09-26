import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tv/model/channel.dart';
import 'package:ip_tv/model/stream_source.dart';
import 'package:ip_tv/screens/player.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../provider/channels_provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  List<StreamSource> streamSources = [];
  StreamSource? selectedSource;
  final ChannelsProvider channelsProvider = ChannelsProvider();
  bool _isLoading = true;

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final FocusNode _gridFocusNode = FocusNode();
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _initSpeech();
    fetchStreamSources();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      WakelockPlus.disable();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    searchController.dispose();
    searchFocusNode.dispose();
    _gridFocusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (e) { if (mounted) setState(() => _isListening = false); },
      onStatus: (s) {
        if (s == SpeechToText.doneStatus || s == SpeechToText.notListeningStatus) {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        localeId: 'en_IN',
        cancelOnError: true,
        listenMode: ListenMode.search,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    searchController.text = words;
    searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: words.length));
    _filterChannels(words);
    if (result.finalResult) {
      _stopListening();
      searchFocusNode.unfocus();
    }
  }

  void _filterChannels(String query) {
    final result = channelsProvider.filterChannels(query);
    if (mounted) setState(() => filteredChannels = result);
  }

  Future<void> fetchStreamSources() async {
    try {
      final sources = await channelsProvider.fetchStreamSources();
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
    setState(() {
      _isLoading = true;
      selectedSource = source;
      searchController.clear();
    });
    try {
      final data = await channelsProvider.fetchM3UFile(source.streamUrl);
      setState(() {
        channels = data;
        filteredChannels = data;
        _isLoading = false;
      });
    } catch (e) {
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
    _stopListening();
    searchController.clear();
    setState(() {
      selectedSource = null;
      channels = [];
      filteredChannels = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(selectedSource?.name ?? 'Live Tv'),
          leading: selectedSource != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: backToCategories,
                )
              : null,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : selectedSource == null
                ? _buildCategoryGrid()
                : sampleVideoGrid(),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (streamSources.isEmpty) {
      return const Center(child: Text('No stream categories available'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.2,
      ),
      itemCount: streamSources.length,
      itemBuilder: (context, index) {
        final source = streamSources[index];
        return InkWell(
          onTap: () => fetchChannels(source),
          child: Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  source.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget sampleVideoGrid() {
    return Column(
      children: [
        Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              searchFocusNode.unfocus();
              _gridFocusNode.requestFocus();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: _filterChannels,
            onSubmitted: (_) => searchFocusNode.unfocus(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search channels...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        _filterChannels('');
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : null,
                    ),
                    tooltip: _isListening ? 'Stop listening' : 'Voice search',
                    onPressed: _speechAvailable
                        ? (_isListening ? _stopListening : _startListening)
                        : null,
                  ),
                ],
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          ),
        ),
        Expanded(
          child: Focus(
            focusNode: _gridFocusNode,
            child:
          SingleChildScrollView(
            child: Column(
              children: [
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                  ),
                  children: filteredChannels
                      .map((channel) => InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => Player(
                                    url: channel.streamUrl,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(1.0),
                              child: Column(
                                children: [
                                  Image.network(
                                    channel.logoUrl,
                                    height: 150,
                                    width: 150,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/tv-icon.png',
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.contain,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8.0),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        channel.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}
