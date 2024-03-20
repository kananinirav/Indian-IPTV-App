import 'package:flutter/material.dart';
import 'package:ip_tv/screens/homepage.dart';


void main() => runApp(const M3UPlayer());

class M3UPlayer extends StatefulWidget {
  const M3UPlayer({super.key});

  @override
  _M3UPlayerState createState() => _M3UPlayerState();
}

class _M3UPlayerState extends State<M3UPlayer> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Live Tv',
      home: GroupTitleListView(),
    );
  }
}
