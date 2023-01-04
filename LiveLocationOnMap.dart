import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mechanify_garage/util/color_constant.dart';
import 'package:mechanify_garage/widget/loading.dart';

class MapScreen extends StatefulWidget {
  final LatLng userDestination;
  const MapScreen({super.key, required this.userDestination});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;

  final Completer<GoogleMapController> _controller = Completer();
  BitmapDescriptor userIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor mechanicIcon = BitmapDescriptor.defaultMarker;

  void getCurrentLocation() async {
    Location location = Location();
    await location.getLocation().then(
      (location) {
        setState(() {
          currentLocation = location;
        });
      },
    );
    GoogleMapController googleMapController = await _controller.future;
    location.onLocationChanged.listen((newlocation) {
      setState(() {
        currentLocation = newlocation;
      });
      googleMapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(newlocation.latitude!, newlocation.longitude!),
              zoom: 13.5)));
      setState(() {});
    });
    getPolyPoints();
  }

  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'Replace With Your API',
      PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!),
      PointLatLng(
          widget.userDestination.latitude, widget.userDestination.longitude),
    );
    if (result.points.isNotEmpty) {
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
      setState(() {});
    }
  }

  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(ImageConfiguration.empty, "")
        .then((icon) => mechanicIcon = icon);
    BitmapDescriptor.fromAssetImage(ImageConfiguration.empty, "")
        .then((icon) => userIcon = icon);
  }

  @override
  void initState() {
    getCurrentLocation();
    getPolyPoints();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var screensize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ColorsConstant.primary,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(50, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Garage Name",
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        color: ColorsConstant.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.5),
                  ),
                ),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: const BoxDecoration(
                      color: ColorsConstant.white,
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                    child: const Text(
                      "Mechanic",
                      style: TextStyle(
                          color: ColorsConstant.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: currentLocation == null
          ? const Center(child: Loader())
          : SafeArea(
              child: GoogleMap(
                zoomControlsEnabled: false,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                      currentLocation!.latitude!, currentLocation!.longitude!),
                  zoom: 13.5,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('CurrentLocation'),
                    position: LatLng(currentLocation!.latitude!,
                        currentLocation!.longitude!),
                    icon: mechanicIcon,
                  ),
                  Marker(
                    markerId: const MarkerId("destination"),
                    position: widget.userDestination,
                    icon: userIcon,
                  ),
                },
                onMapCreated: (mapController) {
                  _controller.complete(mapController);
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId("routes"),
                    points: polylineCoordinates,
                    color: const Color(0xFF7B61FF),
                    width: 6,
                  ),
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          GoogleMapController controller = await _controller.future;
          controller
              .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
            target:
                LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
            zoom: 14,
          )));
          setState(() {});
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
