class Channel {
  final String name;
  final String logoUrl;
  final String streamUrl;
  final int number;
  final String country;
  final String? category;

  Channel({
    required this.name,
    required this.logoUrl,
    required this.streamUrl,
    required this.number,
    required this.country,
    this.category,
  });
}
