import 'dart:convert';
import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:RiskSphere/design_system/components/custom_toast.dart';
import 'package:RiskSphere/service/api_service.dart';
import 'package:RiskSphere/utils/api_constants.dart';

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

  Map<String, dynamic> get eventInfo => _eventInfo ?? {};

  List<Map<String, dynamic>> _eventDate = [];

  List<Map<String, dynamic>> get eventDate => _eventDate;

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedHazard = "All";

  String get selectedHazard => _selectedHazard;

  // Add these getters to fix the error
  DateTime? get startDate => _startDate;

  DateTime? get endDate => _endDate;

  final Set<String> _loadingIds = {};

  bool isLoading(String id) => _loadingIds.contains(id);

  Future<bool> updateNotificationRead(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final feedId = payload['data']?['id'];
    if (feedId == null) return false;

    try {
      _loadingIds.add(feedId);
      notifyListeners();

      ApiService apiService = ApiService(AppConstant.NOTIFICATION_READ);

      final Map<String, dynamic> response = await apiService.patch(payload);

      if (response['message'] == "Activity feed updated successfully") {
        return true;
      }

      log('API failed: $response');
      return false;
    } catch (e, stackTrace) {
      log('Error updating notification: $e');
      log(stackTrace.toString());
      return false;
    } finally {
      _loadingIds.remove(feedId);
      notifyListeners();
    }
  }

  Future<bool> acceptLocationCredits(
    BuildContext context,
    String giftId,
    String feedId,
  ) async {
    try {
      ApiService apiService = ApiService(AppConstant.ACCEPT_CREDITS);
      final Map<String, dynamic> response = await apiService.post({
        'gift_id': giftId,
        'notification_id': feedId,
      });

      log('acceptLocationCredits response: $response');
      return true;
    } catch (e, stackTrace) {
      log('Error accepting credits: $e');
      log(stackTrace.toString());
      return false;
    }
  }

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

      ApiService apiService =
          ApiService('${AppConstant.GET_NEWS_FEED}/$userId');
      String url = _selectedHazard == "All"
          ? '?page=1&pageSize=100'
          : '?activity=${_selectedHazard.toLowerCase()}';
      // String url = '?hazard=${hazard ?? _selectedHazard}';
      if (startDate != null && endDate != null) {
        final dateFormat = DateFormat('yyyy-MM-dd');
        final formattedStartDate = dateFormat.format(startDate);
        final formattedEndDate = dateFormat.format(endDate);
        url += '&start_date=$formattedStartDate&end_date=$formattedEndDate';
      }

      if (keyword != null && keyword.isNotEmpty) {
        url += '&search=$keyword';
      }

      var response = await apiService.get(url);
      if (response != null && response.containsKey('result')) {
        List<dynamic> results = response['result'];
        _newsFeed =
            results.map((item) => Map<String, dynamic>.from(item)).toList();
        _activityHits = response['notification_count'];
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

      ApiService apiService =
          ApiService('${AppConstant.GET_EVENT_FEED}/$userId');
      String url = '?page=1&page_size=100';

      if (startDate != null && endDate != null) {
        url +=
            '&start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}';
      }

      if (keyword != null && keyword.isNotEmpty) {
        url += '&search=$keyword';
      }

      var response = await apiService.get(url);
      if (response != null && response.containsKey('result')) {
        List<dynamic> results = response['result'];
        _eventFeed =
            results.map((item) => Map<String, dynamic>.from(item)).toList();
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
      ApiService apiService =
          ApiService('${AppConstant.GET_EVENT_INFO}/$eventId');
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
      ApiService apiService =
          ApiService('${AppConstant.GET_EVENT_DATE}/$eventId');
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
      fetchNewsFeed(startDate: _startDate, endDate: _endDate);
    }
    notifyListeners();
  }

  /// Update hazard data and trigger fetch
  Future<void> updateHazardData(
      BuildContext context, Map<String, dynamic> payload) async {
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

  Future<void> signInRoleBasedSwitch(
      BuildContext context, Map<String, dynamic> payload) async {
    try {
      ApiService apiService =
          ApiService('${AppConstant.SWITCH_INDIVIDUAL_URL}');
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
