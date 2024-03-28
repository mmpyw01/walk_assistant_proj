import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_mapbox_navigation_example/mqtt.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
//import 'package:alan_voice/alan_voice.dart';
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  FlutterTts flutterTts = FlutterTts();

  Future<void> speakText(String text) async {
    await flutterTts.setSpeechRate(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }
  MqttServerClient ? client;
  late StreamSubscription<List<MqttReceivedMessage<MqttMessage>>> mqttSubscription;

  String? _platformVersion;
  String? _instruction;

  final _origin = WayPoint(
      name: "Way Point 1",
      latitude: 13.728104,
      longitude:  100.778055,
      isSilent: false);
  final _destination = WayPoint(
      name: "Destination",
      latitude: 13.729958536738934,
      longitude: 100.77534020837754,
      isSilent: false);
  final _stop2 = WayPoint(
      name: "Way Point 3",
      latitude: 38.91040213277608,
      longitude: -77.03848242759705,
      isSilent: false);
  final _stop3 = WayPoint(
      name: "Way Point 4",
      latitude: 38.909650771013034,
      longitude: -77.03850388526917,
      isSilent: true);


  final _home = WayPoint(
      name: "Home",
      latitude: 37.77440680146262,
      longitude: -122.43539772352648,
      isSilent: false);

  final _store = WayPoint(
      name: "Store",
      latitude: 37.76556957793795,
      longitude: -122.42409811526268,
      isSilent: false);

  bool _isMultipleStop = false;
  double? _distanceRemaining, _durationRemaining;
  MapBoxNavigationViewController? _controller;
  bool _routeBuilt = false;
  bool _isNavigating = false;
  bool _inFreeDrive = false;
  late MapBoxOptions _navigationOption;


  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initialize() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    _navigationOption = MapBoxNavigation.instance.getDefaultOptions();
    _navigationOption.simulateRoute = false;
    _navigationOption.mode = MapBoxNavigationMode.walking;
    _navigationOption.language = "en";
    //_navigationOption.initialLatitude = 36.1175275;
    //_navigationOption.initialLongitude = -115.1839524;
    MapBoxNavigation.instance.registerRouteEventListener(_onEmbeddedRouteEvent);


  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Walk Assistant'),
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
              onPressed: (){
                showSearch(context: context, delegate: Search());
            }, icon: const Icon(Icons.search))
          ],
        ),
        body: Center(
          child: Column(children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Text('Running on: $_platformVersion\n'),
                    Container(
                      color: Colors.grey,
                      width: double.infinity,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: (Text(
                          "Full Screen Navigation",
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        )),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          child: const Text("Start A to B"),
                          onPressed: () async {
                            var wayPoints = <WayPoint>[];
                            wayPoints.add(_origin);
                            wayPoints.add(_destination);
                            var opt = MapBoxOptions.from(_navigationOption);
                            opt.simulateRoute = false;
                            opt.mode = MapBoxNavigationMode.walking;
                            opt.voiceInstructionsEnabled = true;
                            opt.bannerInstructionsEnabled = true;
                            opt.units = VoiceUnits.metric;
                            opt.language = "en-EN";
                            await MapBoxNavigation.instance
                                .startNavigation(wayPoints: wayPoints, options: opt);

                          },
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        ElevatedButton(
                          child: const Text("Start Multi Stop"),
                          onPressed: () async {
                            _isMultipleStop = true;
                            var wayPoints = <WayPoint>[];
                            wayPoints.add(_origin);
                            wayPoints.add(_stop2);
                            wayPoints.add(_stop3);
                            wayPoints.add(_destination);

                            MapBoxNavigation.instance.startNavigation(
                                wayPoints: wayPoints,
                                options: MapBoxOptions(
                                    mode: MapBoxNavigationMode.walking,
                                    simulateRoute: false,
                                    language: "en",
                                    allowsUTurnAtWayPoints: true,
                                    units: VoiceUnits.metric));
                            //after 10 seconds add a new stop
                            await Future.delayed(const Duration(seconds: 10));
                            var stop = WayPoint(
                                name: "Gas Station",
                                latitude: 38.911176544398,
                                longitude: -77.04014366543564,
                                isSilent: false);
                            MapBoxNavigation.instance
                                .addWayPoints(wayPoints: [stop]);
                          },
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        ElevatedButton(
                          child: const Text("Free Drive"),
                          onPressed: () async {
                            await MapBoxNavigation.instance.startFreeDrive();
                          },
                        ),
                      ],
                    ),
                    Container(
                      color: Colors.grey,
                      width: double.infinity,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: (Text(
                          "Embedded Navigation",
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        )),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isNavigating
                              ? null
                              : () {
                                  if (_routeBuilt) {
                                    _controller?.clearRoute();
                                  } else {
                                    var wayPoints = <WayPoint>[];
                                    wayPoints.add(_home);
                                    wayPoints.add(_store);
                                    _isMultipleStop = wayPoints.length > 2;
                                    _controller?.buildRoute(
                                        wayPoints: wayPoints,
                                        options: _navigationOption);
                                  }
                                },
                          child: Text(_routeBuilt && !_isNavigating
                              ? "Clear Route"
                              : "Build Route"),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        ElevatedButton(
                          onPressed: _routeBuilt && !_isNavigating
                              ? () {
                                  _controller?.startNavigation();
                                }
                              : null,
                          child: const Text('Start '),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        ElevatedButton(
                          onPressed: _isNavigating
                              ? () {
                                  _controller?.finishNavigation();
                                }
                              : null,
                          child: const Text('Cancel '),
                        )
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _inFreeDrive
                          ? null
                          : () async {
                              _inFreeDrive =
                                  await _controller?.startFreeDrive() ?? false;
                            },
                      child: const Text("Free Drive "),
                    ),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          "Long-Press Embedded Map to Set Destination",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.grey,
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: (Text(
                          _instruction == null
                              ? "Banner Instruction Here"
                              : _instruction!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        )),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20.0, right: 20, top: 20, bottom: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Text("Duration Remaining: "),
                              Text(_durationRemaining != null
                                  ? "${(_durationRemaining! / 60).toStringAsFixed(0)} minutes"
                                  : "---")
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              const Text("Distance Remaining: "),
                              Text(_distanceRemaining != null
                                  ? "${(_distanceRemaining!/1000).toStringAsFixed(1)} kilometer"
                                  : "---")
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider()
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 300,
              child: Container(
                color: Colors.grey,
                child: MapBoxNavigationView(
                    options: _navigationOption,
                    onRouteEvent: _onEmbeddedRouteEvent,
                    onCreated:
                        (MapBoxNavigationViewController controller) async {
                      _controller = controller;
                      controller.initialize();
                    }),
              ),
            )
          ]),
        ),
      ),
    );
  }

  Future<void> _onEmbeddedRouteEvent(e) async {
    _distanceRemaining = await MapBoxNavigation.instance.getDistanceRemaining();
    _durationRemaining = await MapBoxNavigation.instance.getDurationRemaining();

    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        if (progressEvent.currentStepInstruction != null) {
          _instruction = progressEvent.currentStepInstruction;
        }
        break;
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        setState(() {
          _routeBuilt = true;
        });
        break;
      case MapBoxEvent.route_build_failed:
        setState(() {
          _routeBuilt = false;
        });
        break;
      case MapBoxEvent.navigation_running:
        setState(() {
          _isNavigating = true;
        });
        break;
      case MapBoxEvent.on_arrival:
        if (!_isMultipleStop) {
          await Future.delayed(const Duration(seconds: 0));
          await _controller?.finishNavigation();
        } else {}
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _routeBuilt = false;
          _isNavigating = false;
        });
        break;
      default:
        break;
    }
    setState(() {});
  }
}

class Search extends SearchDelegate {
  @override
  List<String> searchTerm = [
    'KMITL',
    'Suvannabhum',
  ];

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: (){
          query = '';
        },)
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: (){
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
      );

  }

  @override
  Widget buildResults(BuildContext context) {
    List<String> matchQuery = [];
    for (var item in searchTerm) {
      if (item.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(item);
      }
    }
    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context,index) {
        var result = matchQuery[index];
        return ListTile(
          title: Text(result),
        );
      },
      );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchQuery = [];
    for (var item in searchTerm) {
      if (item.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(item);
      }
    }
    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context,index) {
        var result = matchQuery[index];
        return ListTile(
          title: Text(result),
        );
      },
      );
  }
}