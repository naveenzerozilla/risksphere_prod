import 'dart:convert';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';

// For storing our result
class Suggestion {
  final String placeId;
  final String description;

  Suggestion(this.placeId, this.description);

  @override
  String toString() {
    return 'Suggestion(description: $description, placeId: $placeId)';
  }
}

class PlaceApiProvider {
  final client = Client();
  final String sessionToken;

  PlaceApiProvider(this.sessionToken);

  static final String androidKey = 'AIzaSyB3NiU-vWDp1TUIARsRKqLBvTGAVcka0yI';
  static final String iosKey = 'AIzaSyB3NiU-vWDp1TUIARsRKqLBvTGAVcka0yI';
  final apiKey = Platform.isAndroid ? androidKey : iosKey;

  Future<List<Suggestion>> fetchSuggestions(String input, String lang) async {
    final request = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=geocode|establishment&language=$lang&key=$apiKey&sessiontoken=$sessionToken';

    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        return result['predictions']
            .map<Suggestion>((p) => Suggestion(p['place_id'], p['description']))
            .toList();
      }
      if (result['status'] == 'ZERO_RESULTS') {
        return [];
      }
      return [];
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final request = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=place_id,types,geometry,name,formatted_address,address_component&key=$apiKey';
    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        return result['result'];
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch place details');
    }
  }

  Future<LatLng> getLatLngFromPlaceId(String placeId) async {
    final request = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=place_id,types,geometry,name,formatted_address&key=$apiKey';
    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        final location = result['result']['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch location from place ID');
    }
  }
}
