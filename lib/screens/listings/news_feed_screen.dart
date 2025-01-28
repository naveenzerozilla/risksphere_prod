import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/screens/event/notification_map_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/enums.dart';
import '../../design_system/components/custom_button.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../providers/drawer_selection_provider.dart';
import '../../providers/news_feed_provider.dart';
import '../../service/language_service.dart';
import '../jobMonitoringSystem/job_monitoring_screen.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({Key? key}) : super(key: key);

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  String _selectedHazard = "All";
  DateTime? _startDate;
  DateTime? _endDate;
  ScrollController _scrollController = ScrollController();

  bool _isExpanded = false;
  bool _showNotificationDot = true;

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NewsFeedProvider>(context, listen: false).fetchNewsFeed();
      Provider.of<NewsFeedProvider>(context, listen: false).fetchEvent();
    });
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          isExpanded: _isExpanded,
          showDropdown: true,
          showNotificationDot: _showNotificationDot,
          onExpandPressed: (isExpanded) {
            setState(() {
              _isExpanded = isExpanded;
            });
          },
          onSearchPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        drawer: CustomDrawer(),
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/mesh.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Column(
              children: [
                _buildTabBar(typography),
                _buildSearchAndFilter(typography),
                Expanded(child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNewsFeedList(context, typography),
                    _buildEventFeedList(context, typography),
                    _getComingSoonUI(),
                    _getComingSoonUI(),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(CustomTypography typography) {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_left, color: Colors.grey),
            onPressed: _scrollLeft,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelStyle: typography.Subtitle2,
                labelColor: Colors.lightBlueAccent,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.lightBlueAccent,
                tabAlignment:
              TabAlignment.start,
                tabs: [
                  Consumer<NewsFeedProvider>(
                    builder: (context, newsFeedProvider, child) {
                      return Tab(
                        child: Row(
                          children: [
                            Text('Activity Feed', style: typography.Subtitle2),
                            if (newsFeedProvider.activityHits > 0)
                              SizedBox(width: 6),
                            if (newsFeedProvider.activityHits > 0)
                              SizedBox(
                                height: 25,
                                child: Chip(
                                  labelPadding: EdgeInsets.all(0),
                                  materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                  label: Text(
                                    newsFeedProvider.activityHits.toString(),
                                    style: typography
                                        .BottomNavigationActiveLabel
                                        .copyWith(height: -0.6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  Consumer<NewsFeedProvider>(
                    builder: (context, newsFeedProvider, child) {
                      return Tab(
                        child: Row(
                          children: [
                            Text('Event Feed', style: typography.Subtitle2),
                            if (newsFeedProvider.eventHits > 0)
                              SizedBox(width: 6),
                            if (newsFeedProvider.eventHits > 0)
                              SizedBox(
                                height: 25,
                                child: Chip(
                                  labelPadding: EdgeInsets.all(0),
                                  materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                  label: Text(
                                    newsFeedProvider.eventHits.toString(),
                                    style: typography
                                        .BottomNavigationActiveLabel
                                        .copyWith(height: -0.6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  _buildTab("News Feed", ""),
                  _buildTab("Pending Actions", ""),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_right, color: Colors.grey),
            onPressed: _scrollRight,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, String count) {
    return Tab(
      child: Row(
        children: [
          Text(label),
          SizedBox(width: 6),
          //future need to uncommand
          // Chip(
          //   label: Text(count, style: TextStyle(fontSize: 12)),
          //   padding: EdgeInsets.zero,
          //   backgroundColor: Colors.blueAccent,
          // ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(CustomTypography typography) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: typography.Body2,
                  decoration: InputDecoration(
                    hintText: 'Search keyword',
                    filled: true,
                    fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    Provider.of<NewsFeedProvider>(context, listen: false)
                        .fetchNewsFeed(keyword: value);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hazard Dropdown
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Consumer<NewsFeedProvider>(
                    builder: (context, provider, child) {
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: provider.selectedHazard,
                          onChanged: (String? newValue) {
                            provider.updateSelectedHazard(newValue!);
                            provider.fetchNewsFeed();
                          },
                          items: ['All', 'Earthquake', 'Hurricane', 'Flood']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Text(value, style: typography.Body2),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Date Range Picker
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton(
                    onPressed: () => _selectDateRange(context),
                    child: Consumer<NewsFeedProvider>(
                      builder: (context, provider, child) {
                        String dateText = provider.startDate != null &&
                            provider.endDate != null
                            ? "${DateFormat('MM/dd/yyyy').format(provider.startDate!)} - ${DateFormat('MM/dd/yyyy').format(provider.endDate!)}"
                            : "Select Date";
                        return Text(
                          dateText,
                          textAlign: TextAlign.center,
                          style: typography.Body2,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Date range selection logic
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: Provider.of<NewsFeedProvider>(context, listen: false)
          .startDate !=
          null &&
          Provider.of<NewsFeedProvider>(context, listen: false).endDate != null
          ? DateTimeRange(
          start: Provider.of<NewsFeedProvider>(context, listen: false)
              .startDate!,
          end: Provider.of<NewsFeedProvider>(context, listen: false).endDate!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      Provider.of<NewsFeedProvider>(context, listen: false)
          .updateDateRange(picked.start, picked.end);
      Provider.of<NewsFeedProvider>(context, listen: false).fetchNewsFeed();
    }
  }


  Widget _buildNewsFeedList(BuildContext context, CustomTypography typography) {
    return Consumer<NewsFeedProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.fetchNewsFeed();  // Force refresh regardless of content
          },
          child:
          provider.isActivityLoading?
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
            ),
          ):
          provider.newsFeed.isEmpty && !provider.isActivityLoading
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh even when list is empty
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 200),
                  child: Text(
                    'No News Feed Available',
                    style: typography.Body1,
                  ),
                ),
              ),
            ],
          )
              : ListView.builder(
            itemCount: provider.newsFeed.length,
            itemBuilder: (context, index) {
              var item = provider.newsFeed[index];
              return _buildNewsCard(item, typography);
            },
          ),
        );
      },
    );
  }



  Widget _buildNewsCard(Map<String, dynamic> item, CustomTypography typography) {
    final notification = item['message']?['notification']??{};
    final title = notification['title'];
    final body = notification['body'];
    // Handle updated_at as either a map or a string
    dynamic updatedAt = item['updated_at'];
    int timestamp;

    if (updatedAt != null) {
      if (updatedAt is Map && updatedAt.containsKey('_seconds')) {
        timestamp = updatedAt['_seconds'] * 1000;
      } else if (updatedAt is String) {
        try {
          timestamp = DateFormat("MMMM d, yyyy 'at' h:mm:ss a 'UTC'").parseUTC(updatedAt).millisecondsSinceEpoch;
        } catch (e) {
          print('Error parsing date: $e');
          timestamp = DateTime.now().millisecondsSinceEpoch; // Fallback to current time
        }
      } else {
        timestamp = DateTime.now().millisecondsSinceEpoch;
      }
    } else {
      timestamp = DateTime.now().millisecondsSinceEpoch;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SvgPicture.asset(
                  'assets/images/earthquake.svg',
                  width: 40,
                  height: 40,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  DateFormat('MM/dd/yyyy HH:mm')
                      .format(DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal()),
                  style: typography.Caption!.copyWith(color: Colors.white54),
                ),
              ),
            ],
          ),
          ListTile(
            titleAlignment: ListTileTitleAlignment.top,
            title: Text(
              title??"",
              style: typography.Body1,
            ),
            subtitle: Column(
              children: [
                SizedBox(height: 4),
                _buildExpandableDescription(body??"", typography),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () {
                  print("View Event for $title");
                  String processId = item['process_id'] ?? '';  // Ensure process_id is available
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobMonitoringDashboard(
                        initialProcessId: processId,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View Event',
                  style: typography.ButtonLarge.copyWith(
                    color: Colors.black,
                  ),
                ),
                type: ButtonType.elevated,
              ),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Builds the expandable description with a clickable "More" link
  Widget _buildExpandableDescription(String description, CustomTypography typography) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isExpanded = false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Tooltip(
                message: description,
                triggerMode: TooltipTriggerMode.tap,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: description.length > 50
                            ? (isExpanded ? description : '${description.substring(0, 50)}...')
                            : description,
                        style: typography.Body2,
                      ),
                      if (description.length > 50 && !isExpanded)
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isExpanded = true;
                              });
                            },
                            child: Text(
                              ' More',
                              style: typography.Body2.copyWith(
                                color: AppColors.primaryMain,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildEventFeedList(BuildContext context, CustomTypography typography) {
    return Consumer<NewsFeedProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.fetchEvent();  // Force refresh regardless of content
          },
          child: provider.isEventLoading
              ? Center(
            child: CircularProgressIndicator(),
          )
              :
          provider.eventFeed.isEmpty && !provider.isEventLoading
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh even when list is empty
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 200),
                  child: Text(
                    'No Events Available',
                    style: typography.Body1,
                  ),
                ),
              ),
            ],
          )
              : ListView.builder(
            itemCount: provider.eventFeed.length,
            itemBuilder: (context, index) {
              var item = provider.eventFeed[index];
              return _buildEventCard(item, typography);
            },
          ),
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> item, CustomTypography typography) {
    final notification = item['notification_body']??{};
    final title = notification['title'];
    final body = notification['body'];
    // Handle updated_at as either a map or a string
    dynamic updatedAt = item['updated_at'];
    int timestamp;

    if (updatedAt != null) {
      if (updatedAt is Map && updatedAt.containsKey('_seconds')) {
        timestamp = updatedAt['_seconds'] * 1000;
      } else if (updatedAt is String) {
        try {
          timestamp = DateFormat("MMMM d, yyyy 'at' h:mm:ss a 'UTC'").parseUTC(updatedAt).millisecondsSinceEpoch;
        } catch (e) {
          print('Error parsing date: $e');
          timestamp = DateTime.now().millisecondsSinceEpoch; // Fallback to current time
        }
      } else {
        timestamp = DateTime.now().millisecondsSinceEpoch;
      }
    } else {
      timestamp = DateTime.now().millisecondsSinceEpoch;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SvgPicture.asset(
                  'assets/images/earthquake.svg',
                  width: 40,
                  height: 40,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  DateFormat('MM/dd/yyyy HH:mm')
                      .format(DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal()),
                  style: typography.Caption!.copyWith(color: Colors.white54),
                ),
              ),
            ],
          ),
          ListTile(
            titleAlignment: ListTileTitleAlignment.top,
            title: Text(
              title??"",
              style: typography.Body1,
            ),
            subtitle: Column(
              children: [
                SizedBox(height: 4),
                _buildExpandableDescription(body??"", typography),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () {
                  print("View Event for $title");
                  String eventId = item['event_id'] ?? '';  // Ensure process_id is available
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationMapScreen(
                          notificationData: {
                        'title': title,
                        'body': body,
                        'timestamp': timestamp,
                        'eventId': eventId,
                      }),
                    ),
                  );
                },
                child: Text(
                  'View Event',
                  style: typography.ButtonLarge.copyWith(
                    color: Colors.black,
                  ),
                ),
                type: ButtonType.elevated,
              ),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }



  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 100,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 100,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  _getComingSoonUI() {
    var typography = CustomTypography(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Expanded(
                    child: Text(
                        LanguageService.getTranslated(
                            context, 'coming_soon_title'),
                        style: typography.H4),
                  ),
                  SizedBox(
                    height: CustomSpacing.two,
                  ),
                  Text(
                      LanguageService.getTranslated(
                          context, 'coming_soon_subtitle'),
                      style: typography.Body1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
