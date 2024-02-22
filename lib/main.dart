import 'package:flutter/material.dart';
import 'screens/home.dart';

void main() => runApp(M3UPlayer());

class M3UPlayer extends StatefulWidget {
  @override
  _M3UPlayerState createState() => _M3UPlayerState();
}

class _M3UPlayerState extends State<M3UPlayer> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Live Tv',
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Channel List'),
          ),
          body: const Home()),
    );
  }
}
