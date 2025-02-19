import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:RiskSphare/design_system/components/custom_toast.dart';
import 'package:RiskSphare/service/api_service.dart';
import 'package:RiskSphare/utils/api_constants.dart';

class NewsFeedProvider extends ChangeNotifier {
  bool _isActivityLoading = false;
  bool get isActivityLoading => _isActivityLoading;
  set isActivityLoading(bool value) {
    _isActivityLoading = value;
    notifyListeners();
  }

  bool _isEventLoading = false;
  bool get isEventLoading => _isEventLoading;
  set isEventLoading(bool value) {
    _isEventLoading = value;
    notifyListeners();
  }

  bool _isEventInfoLoading = false;
  bool get isEventInfoLoading => _isEventInfoLoading;
  set isEventInfoLoading(bool value) {
    _isEventInfoLoading = value;
    notifyListeners();
  }

  bool _isEventDateLoading = false;
  bool get isEventDateLoading => _isEventDateLoading;
  set isEventDateLoading(bool value) {
    _isEventDateLoading = value;
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _activityHits = 0;
  int get activityHits => _activityHits;

  int _eventHits = 0;
  int get eventHits => _eventHits;

  List<Map<String, dynamic>> _newsFeed = [];
  List<Map<String, dynamic>> get newsFeed => _newsFeed;

  List<Map<String, dynamic>> _eventFeed = [];
  List<Map<String, dynamic>> get eventFeed => _eventFeed;

  Map<String, dynamic>? _eventInfo;
  Map<String, dynamic> get eventInfo => _eventInfo??{};

  List<Map<String, dynamic>> _eventDate = [];
  List<Map<String, dynamic>> get eventDate => _eventDate;


  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedHazard = "All";
  String get selectedHazard => _selectedHazard;

  // Add these getters to fix the error
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;



  /// Fetch News Feed from API and store as list of maps
  Future<void> fetchNewsFeed({
    DateTime? startDate,
    DateTime? endDate,
    String? hazard,
    String? keyword,
  }) async {
    if (_isActivityLoading) return; // Prevent duplicate requests
    isActivityLoading = true;
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        log('User not logged in');
        return;
      }

      ApiService apiService = ApiService('${AppConstant.GET_NEWS_FEED}/$userId');
      String url = '?hazard=${hazard ?? _selectedHazard}';

      if (startDate != null && endDate != null) {
        url += '&start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}';
      }

      if (keyword != null && keyword.isNotEmpty) {
        url += '&search=$keyword';
      }

      var response = await apiService.get(url);
      if (response != null && response.containsKey('result')) {
        List<dynamic> results = response['result'];
        _newsFeed = results.map((item) => Map<String, dynamic>.from(item)).toList();
        _activityHits = _newsFeed.length;
        log('News Feed Loaded: $_activityHits items');
      } else {
        _newsFeed = [];
        _activityHits = 0;
        log('No results found');
      }
    } catch (e, stackTrace) {
      log('Error fetching news feed: $e');
      log(stackTrace.toString());
    } finally {
      isActivityLoading = false;
    }
  }

  /// Fetch Event from API and store as list of maps
  Future<void> fetchEvent({
    DateTime? startDate,
    DateTime? endDate,
    String? hazard,
    String? keyword,
  }) async {
    if (_isEventLoading) return; // Prevent duplicate requests
    isEventLoading = true;
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        log('User not logged in');
        return;
      }

      ApiService apiService = ApiService('${AppConstant.GET_EVENT_FEED}/$userId');
      String url = '?page=1&page_size=100';

      if (startDate != null && endDate != null) {
        url += '&start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}';
      }

      if (keyword != null && keyword.isNotEmpty) {
        url += '&search=$keyword';
      }

      var response = await apiService.get(url);
      if (response != null && response.containsKey('result')) {
        List<dynamic> results = response['result'];
        _eventFeed = results.map((item) => Map<String, dynamic>.from(item)).toList();
        _eventHits = _eventFeed.length;
        log('Event Feed Loaded: $_activityHits items');
      } else {
        _newsFeed = [];
        _eventHits = 0;
        log('No results found');
      }
    } catch (e, stackTrace) {
      log('Error fetching news feed: $e');
      log(stackTrace.toString());
    } finally {
      isEventLoading = false;
    }
  }

  /// Fetch eventInfo from API and store as list of maps
  Future<void> fetchEventInfo({
    String? eventId,
  }) async {
    if (_isEventInfoLoading) return; // Prevent duplicate requests
    isEventInfoLoading = true;
    try {

      ApiService apiService = ApiService('${AppConstant.GET_EVENT_INFO}/$eventId');
      String url = '';


      var response = await apiService.get(url);
      if (response.containsKey('result')) {
        Map<String, dynamic> results = response['result'];
        _eventInfo = results;

      } else {
        log('No info found for id: $eventId');
      }
    } catch (e, stackTrace) {
      log('Error fetching news feed: $e');
      log(stackTrace.toString());
    } finally {
      isEventInfoLoading = false;
    }
  }

  /// Fetch eventDate from API and store as list of maps
  Future<void> fetchEventDate({
    String? eventId,
  }) async {
    if (_isEventDateLoading) return; // Prevent duplicate requests
    isEventDateLoading = true;
    try {
      ApiService apiService = ApiService('${AppConstant.GET_EVENT_DATE}/$eventId');
      String url = '';
      var response = await apiService.get(url);
      if (response.containsKey('result')) {
        List<dynamic> results = response['result'];
        _eventDate =
            results.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        log('No info found for date: $eventId');
      }
    } catch (e, stackTrace) {
      log('Error fetching news feed: $e');
      log(stackTrace.toString());
    } finally {
      isEventDateLoading = false;
    }
  }

  /// Update selected hazard and trigger fetch
  void updateSelectedHazard(String hazard) {
    if (_selectedHazard != hazard) {
      _selectedHazard = hazard;
      fetchNewsFeed();
    }
    notifyListeners();
  }

  /// Update date range and trigger fetch
  void updateDateRange(DateTime? start, DateTime? end) {
    if (_startDate != start || _endDate != end) {
      _startDate = start;
      _endDate = end;
      fetchNewsFeed();
    }
    notifyListeners();
  }

  /// Update hazard data and trigger fetch
  Future<void> updateHazardData(BuildContext context, Map<String, dynamic> payload) async {

    try {
      ApiService apiService = ApiService('${AppConstant.UPDATE_HAZARD}');
      var response = await apiService.post(payload);
      if (response.containsKey('result')) {
        CustomToast.success(context, 'Hazard data updated successfully');
      } else {
        log('Error updating hazard data');
      }

    } catch (e, stackTrace) {
      log('Error fetching news feed: $e');
      log(stackTrace.toString());
    }
  }
}
