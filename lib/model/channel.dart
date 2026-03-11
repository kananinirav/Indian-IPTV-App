class Channel {
  final String name;
  final String logoUrl;
  final String streamUrl;
  final String groupTitle;

  Channel({
    required this.name,
    required this.logoUrl,
    required this.streamUrl,
    this.groupTitle = '',
  });
}
