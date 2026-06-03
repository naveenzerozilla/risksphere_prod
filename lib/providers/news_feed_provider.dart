import 'dart:convert';
import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:RiskSphere/design_system/components/custom_toast.dart';
import 'package:RiskSphere/service/api_service.dart';
import 'package:RiskSphere/utils/api_constants.dart';
import 'package:http/http.dart' as http;

class NewsFeedProvider extends ChangeNotifier {
  bool _isActivityLoading = false;
  bool _isActivityLoadMore = false;
  int _activityPage = 1;
  bool _hasMoreActivity = true;

  bool get isActivityLoading => _isActivityLoading;

  bool get isActivityLoadMore => _isActivityLoadMore;

  bool get hasMoreActivity => _hasMoreActivity;

  set isActivityLoading(bool value) {
    _isActivityLoading = value;
    notifyListeners();
  }

  set isActivityLoadMore(bool value) {
    _isActivityLoadMore = value;
    notifyListeners();
  }

  bool _isEventLoading = false;
  bool _isEventLoadMore = false;

  bool get isEventLoading => _isEventLoading;

  bool get isEventLoadMore => _isEventLoadMore;

  set isEventLoading(bool value) {
    _isEventLoading = value;
    notifyListeners();
  }

  set isEventLoadMore(bool value) {
    _isEventLoadMore = value;
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

  String _newsItemKey(Map<String, dynamic> item) {
    final id = item['id'] ?? item['notification_id'] ?? item['process_id'];
    return id?.toString() ?? jsonEncode(item);
  }

  String _eventItemKey(Map<String, dynamic> item) {
    final id = item['id'] ?? item['event_id'] ?? item['process_id'];
    return id?.toString() ?? jsonEncode(item);
  }

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

  Future<void> fetchNewsFeed({
    bool isLoadMore = false,
    DateTime? startDate,
    DateTime? endDate,
    String? hazard,
    String? keyword,
  }) async {
    if (isLoadMore) {
      if (_isActivityLoadMore || _isActivityLoading || !_hasMoreActivity)
        return;
      isActivityLoadMore = true;
      _activityPage++;
    } else {
      if (_isActivityLoading) return; // Prevent duplicate requests
      isActivityLoading = true;
      _activityPage = 1;
      _hasMoreActivity = true;
    }
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        log('User not logged in');
        return;
      }

      ApiService apiService =
          ApiService('${AppConstant.GET_NEWS_FEED}/$userId');
      String url = _selectedHazard == "All"
          ? '?page=$_activityPage&page_size=10&pageSize=10'
          : '?page=$_activityPage&page_size=10&pageSize=10&activity=${_selectedHazard.toLowerCase()}';
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
        final parsedResults =
            results.map((item) => Map<String, dynamic>.from(item)).toList();
        final int serverActivityCount = response['notification_count'] is int
            ? response['notification_count'] as int
            : parsedResults.length;

        if (isLoadMore) {
          final existingIds = _newsFeed.map(_newsItemKey).toSet();
          final uniqueNewItems = parsedResults
              .where((item) => !existingIds.contains(_newsItemKey(item)))
              .toList();
          _newsFeed.addAll(uniqueNewItems);
          if (uniqueNewItems.isEmpty) {
            _hasMoreActivity = false;
          }
        } else {
          _newsFeed = parsedResults;
        }

        if (parsedResults.isEmpty) {
          _hasMoreActivity = false;
        }

        // Keep total chip count stable across load-more responses.
        _activityHits = _newsFeed.length;
        if (serverActivityCount > _activityHits) {
          _activityHits = serverActivityCount;
        }
        log('News Feed Loaded: $_activityHits items');
      } else {
        if (isLoadMore) {
          _activityPage = (_activityPage > 1) ? _activityPage - 1 : 1;
          _hasMoreActivity = false;
        } else {
          _newsFeed = [];
          _activityHits = 0;
          _hasMoreActivity = false;
        }
        log('No results found');
      }
    } catch (e, stackTrace) {
      if (isLoadMore) {
        _activityPage = (_activityPage > 1) ? _activityPage - 1 : 1;
      }
      log('Error fetching news feed: $e');
      log(stackTrace.toString());
    } finally {
      if (isLoadMore) {
        isActivityLoadMore = false;
      } else {
        isActivityLoading = false;
      }
    }
  }

  int _eventPage = 1;
  bool _hasMoreEvent = true;

  bool get hasMoreEvent => _hasMoreEvent;

  // bool isEventLoading = false;

  Future<void> fetchEvent({
    bool isLoadMore = false,
    DateTime? startDate,
    DateTime? endDate,
    String? hazard,
    String? keyword,
  }) async {
    if (isLoadMore) {
      if (isEventLoading || isEventLoadMore || !_hasMoreEvent) return;
      isEventLoadMore = true;
      _eventPage++;
    } else {
      if (isEventLoading) return;
      isEventLoading = true;
      _eventPage = 1;
      _eventFeed.clear();
      _hasMoreEvent = true;
    }

    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) return;

      ApiService apiService =
          ApiService('${AppConstant.GET_EVENT_FEED}/$userId');

      String url = '?page=$_eventPage&pageSize=20';

      var response = await apiService.get(url);

      if (response != null && response.containsKey('result')) {
        List<dynamic> results = response['result'];
        final parsedResults =
            results.map((e) => Map<String, dynamic>.from(e)).toList();

        if (parsedResults.isEmpty) {
          if (isLoadMore) {
            _eventPage = (_eventPage > 1) ? _eventPage - 1 : 1;
          }
          _hasMoreEvent = false;
        } else {
          if (isLoadMore) {
            final existingIds = _eventFeed.map(_eventItemKey).toSet();
            final uniqueNewItems = parsedResults
                .where((item) => !existingIds.contains(_eventItemKey(item)))
                .toList();
            _eventFeed.addAll(uniqueNewItems);
            if (uniqueNewItems.isEmpty) {
              _hasMoreEvent = false;
            }
          } else {
            _eventFeed = parsedResults;
          }
        }

        if (isLoadMore) {
          if (_eventFeed.length > _eventHits) {
            _eventHits = _eventFeed.length;
          }
        } else {
          _eventHits = _eventFeed.length;
        }
        notifyListeners();
      }
    } catch (e) {
      if (isLoadMore) {
        _eventPage = (_eventPage > 1) ? _eventPage - 1 : 1;
      }
      log('Error: $e');
    } finally {
      if (isLoadMore) {
        isEventLoadMore = false;
      } else {
        isEventLoading = false;
      }
    }
  }

  Future<String?> fetchMapUrl(String eventId) async {
    try {
      ApiService apiService = ApiService('${AppConstant.GET_MAP_URL}');

      var response = await apiService.post({'event_id': eventId});

      print("MAP API RESPONSE 👉 $response");

      //  DIRECT RESPONSE (YOUR CASE)
      if (response != null && response.containsKey('map_url')) {
        return response['map_url'];
      }

      //  BACKUP (if API changes later)
      if (response != null &&
          response.containsKey('result') &&
          response['result'] != null) {
        return response['result']['map_url'];
      }

      log('Map URL not found in response');
    } catch (e, stackTrace) {
      log('Error fetching map url: $e');
      log(stackTrace.toString());
    }

    return null;
  }


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
