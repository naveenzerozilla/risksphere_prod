import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:RiskSphere/screens/event/notification_map_screen.dart';
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
import 'package:dropdown_button2/dropdown_button2.dart';

import '../payments/transaction_summary.dart';

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
  final ScrollController _tabScrollController = ScrollController();
  final ScrollController _newsFeedScrollController = ScrollController();
  final ScrollController _eventFeedScrollController = ScrollController();

  bool _isExpanded = false;
  bool _showNotificationDot = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NewsFeedProvider>(context, listen: false).fetchNewsFeed();
      Provider.of<NewsFeedProvider>(context, listen: false).fetchEvent();
    });

    _newsFeedScrollController.addListener(_onNewsFeedScroll);
    _eventFeedScrollController.addListener(_onEventFeedScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _tabScrollController.dispose();
    _newsFeedScrollController.dispose();
    _eventFeedScrollController.dispose();
    super.dispose();
  }

  void _onNewsFeedScroll() {
    if (_newsFeedScrollController.position.pixels >=
        _newsFeedScrollController.position.maxScrollExtent - 200) {
      Provider.of<NewsFeedProvider>(context, listen: false)
          .fetchNewsFeed(isLoadMore: true);
    }
  }

  void _onEventFeedScroll() {
    if (_eventFeedScrollController.position.pixels >=
        _eventFeedScrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<NewsFeedProvider>(context, listen: false);
      if (provider.hasMoreEvent && !provider.isEventLoadMore) {
        provider.fetchEvent(isLoadMore: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    return SafeArea(
      child: PopScope(
        onPopInvokedWithResult: (canPop, result) {
          //print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
          Provider.of<DrawerSelectionProvider>(context, listen: false)
              .setSelectedItem("dashboard");
        },
        child: Scaffold(
          appBar: CustomAppBar(
            isExpanded: _isExpanded,
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
                  Expanded(
                      child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNewsFeedList(context, typography),
                      _buildEventFeedList(context, typography),
                      _getNewFeedComingSoonUI(),
                      _getNewPendingActionSoonUI(),
                    ],
                  )),
                ],
              ),
            ],
          ),
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
              controller: _tabScrollController,
              scrollDirection: Axis.horizontal,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelStyle: typography.Subtitle2,
                labelColor: Colors.lightBlueAccent,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.lightBlueAccent,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Consumer<NewsFeedProvider>(
                    builder: (context, newsFeedProvider, child) {
                      return Tab(
                        child: Row(
                          children: [
                            Text(
                                LanguageService.getTranslated(
                                    context, "activity_feed"),
                                style: typography.Subtitle2),
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
                                    style:
                                        typography.BottomNavigationActiveLabel
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
                            Text(
                                LanguageService.getTranslated(
                                    context, "event_feed"),
                                style: typography.Subtitle2),
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
                                    style:
                                        typography.BottomNavigationActiveLabel
                                            .copyWith(height: -0.6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  _buildTab(
                      LanguageService.getTranslated(context, "news_feed"), ""),
                  _buildTab(
                      LanguageService.getTranslated(context, "pending_actions"),
                      ""),
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
                    hintText: LanguageService.getTranslated(
                        context, "search_keyword"),
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
                        child: DropdownButton2<String>(
                          isExpanded: true,
                          dropdownStyleData: DropdownStyleData(
                            width: MediaQuery.of(context).size.width / 2.2,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          value: ['All', 'Geocoding', 'Hazard']
                                  .contains(provider.selectedHazard)
                              ? provider.selectedHazard
                              : 'All',
                          onChanged: (String? newValue) {
                            provider.updateSelectedHazard(newValue!);
                            Future.microtask(() => provider.fetchNewsFeed());
                          },
                          items: ['All', 'Geocoding', 'Hazard']
                              .map((String value) {
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
              Provider.of<NewsFeedProvider>(context, listen: false).endDate !=
                  null
          ? DateTimeRange(
              start: Provider.of<NewsFeedProvider>(context, listen: false)
                  .startDate!,
              end: Provider.of<NewsFeedProvider>(context, listen: false)
                  .endDate!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      Provider.of<NewsFeedProvider>(context, listen: false)
          .updateDateRange(picked.start, picked.end);
      // Provider.of<NewsFeedProvider>(context, listen: false).fetchNewsFeed();
    }
  }

  Widget _buildNewsFeedList(BuildContext context, CustomTypography typography) {
    return Consumer<NewsFeedProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider
                .fetchNewsFeed(); // Force refresh regardless of content
          },
          child: provider.isActivityLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
                  ),
                )
              : provider.newsFeed.isEmpty && !provider.isActivityLoading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      // Ensures pull-to-refresh even when list is empty
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
                      controller: _newsFeedScrollController,
                      itemCount: provider.newsFeed.length +
                          (provider.isActivityLoadMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.newsFeed.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        var item = provider.newsFeed[index];
                        return _buildNewsCard(item, typography);
                      },
                    ),
        );
      },
    );
  }

  String formatNewsFeedDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return DateFormat('hh:mm a').format(date).toLowerCase();
    }

    if (dateOnly == yesterday) {
      return 'Yesterday';
    }

    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _buildNewsCard(
      Map<String, dynamic> item, CustomTypography typography) {
    final notification = item['notification_body'] ?? {};
    final title = notification['title'] ?? '';
    final body = notification['body'] ?? '';
    final activityType = item['type'];
    final readStatus = item['is_read'];
    final isRevoked = item['is_revoked'];
    final feedId = item['id'];
    dynamic updatedAt = item['updated_at'];
    int timestamp;

    if (updatedAt != null) {
      if (updatedAt is Map && updatedAt.containsKey('_seconds')) {
        timestamp = updatedAt['_seconds'] * 1000;
      } else if (updatedAt is String) {
        try {
          timestamp = DateFormat("MMMM d, yyyy 'at' h:mm:ss a 'UTC'")
              .parseUTC(updatedAt)
              .millisecondsSinceEpoch;
        } catch (e) {
          print('Error parsing date: $e');
          timestamp =
              DateTime.now().millisecondsSinceEpoch; // Fallback to current time
        }
      } else {
        timestamp = DateTime.now().millisecondsSinceEpoch;
      }
    } else {
      timestamp = DateTime.now().millisecondsSinceEpoch;
    }
    return Consumer<NewsFeedProvider>(
      builder: (context, provider, _) {
        final isLoading = feedId != null && provider.isLoading(feedId);

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: (isLoading ||
                  isRevoked == true ||
                  (readStatus == true && activityType == 'location_gift'))
              ? null
              : () async {
                  if (feedId == null) return;

                  final payload = {
                    "data": {"id": feedId}
                  };

                  final isSuccess =
                      await provider.updateNotificationRead(context, payload);

                  if (!context.mounted) return;
                  if (!isSuccess) return;

                  if (activityType == 'location_gift') {
                    final giftId = item['payload']?['gift_id'] ?? '';

                    if (giftId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gift ID not found.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final creditAccepted = await provider.acceptLocationCredits(
                        context, giftId, feedId);

                    if (!context.mounted) return;

                    if (creditAccepted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Credits accepted successfully! 🎁',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentTransactionsPage(
                            initialTabIndex: 1,
                          ),
                        ),
                      ).then((_) {
                        if (!context.mounted) return;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Provider.of<NewsFeedProvider>(context, listen: false)
                              .fetchNewsFeed();
                        });
                      });
                    } else {
                      Provider.of<NewsFeedProvider>(context, listen: false)
                          .fetchNewsFeed();
                    }

                    return;
                  } else {
                    final processId = item['process_id'] ?? '';

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobMonitoringDashboard(
                          initialProcessId: processId,
                        ),
                      ),
                    ).then((_) {
                      if (!context.mounted) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Provider.of<NewsFeedProvider>(context, listen: false)
                            .fetchNewsFeed();
                      });
                    });
                  }
                },
          // onTap: (isLoading || isRevoked == true)
          //     ? null
          //     : () async {
          //         if (feedId == null) return;
          //
          //         final payload = {
          //           "data": {"id": feedId}
          //         };
          //         final isSuccess =
          //             await provider.updateNotificationRead(context, payload);
          //
          //         if (!context.mounted) return;
          //         if (!isSuccess) return;
          //
          //         if (activityType == 'location_gift') {
          //           final giftId = item['payload']?['gift_id'] ?? '';
          //           if (giftId.isEmpty) {
          //             ScaffoldMessenger.of(context).showSnackBar(
          //               const SnackBar(
          //                 content: Text('Gift ID not found.'),
          //                 backgroundColor: Colors.red,
          //               ),
          //             );
          //             return;
          //           }
          //
          //           final creditAccepted = await provider.acceptLocationCredits(
          //               context, giftId, feedId);
          //
          //           if (!context.mounted) return;
          //           if (creditAccepted) {
          //             ScaffoldMessenger.of(context).showSnackBar(
          //               SnackBar(
          //                 content: Text(
          //                   creditAccepted
          //                       ? 'Credits accepted successfully! 🎁'
          //                       : 'Failed to accept credits.',
          //                 ),
          //                 backgroundColor:
          //                     creditAccepted ? Colors.green : Colors.red,
          //               ),
          //             );
          //           }
          //
          //           if (creditAccepted) {
          //             Navigator.push(
          //               context,
          //               MaterialPageRoute(
          //                 builder: (context) => PaymentTransactionsPage(
          //                   initialTabIndex: 1,
          //                 ),
          //               ),
          //             ).then((_) {
          //               if (!context.mounted) return;
          //               WidgetsBinding.instance.addPostFrameCallback((_) {
          //                 Provider.of<NewsFeedProvider>(context, listen: false)
          //                     .fetchNewsFeed();
          //               });
          //             });
          //           } else {
          //             Provider.of<NewsFeedProvider>(context, listen: false)
          //                 .fetchNewsFeed();
          //           }
          //
          //           return;
          //         } else {
          //           final processId = item['process_id'] ?? '';
          //
          //           Navigator.push(
          //             context,
          //             MaterialPageRoute(
          //               builder: (context) => JobMonitoringDashboard(
          //                 initialProcessId: processId,
          //               ),
          //             ),
          //           ).then((_) {
          //             if (!context.mounted) return;
          //             WidgetsBinding.instance.addPostFrameCallback((_) {
          //               Provider.of<NewsFeedProvider>(context, listen: false)
          //                   .fetchNewsFeed();
          //             });
          //           });
          //         }
          //       },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: (isLoading || isRevoked == true) ? 0.5 : 1,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: (readStatus != true)
                        ? Border.all(color: AppColors.primaryMain, width: 0.1)
                        : null,
                    color: (readStatus != true)
                        ? AppColors.primaryMain
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (readStatus != true)
                          ? Color.fromRGBO(39, 38, 44, 1)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white10,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: activityType.toString().toLowerCase() ==
                                    "location_gift"
                                ? Icon(
                                    Icons.notifications_none_outlined,
                                    color: isRevoked == true
                                        ? Colors.grey
                                        : Colors.white70,
                                  )
                                : SvgPicture.asset(
                                    activityType == "hazard"
                                        ? 'assets/images/hazard_icon.svg'
                                        : 'assets/images/geocode.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white70,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: typography.Body1.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Text(
                                        formatNewsFeedDate(timestamp),
                                        style: typography.Caption.copyWith(
                                          color: Colors.white54,
                                        ),
                                      ),
                                      if (!isLoading && readStatus != true)
                                        Positioned(
                                          top: -4,
                                          right: -8,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      if (isLoading)
                                        const Positioned(
                                          top: -4,
                                          right: -8,
                                          child: SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildExpandableDescription(body, typography),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the expandable description with a clickable "More" link
  Widget _buildExpandableDescription(
      String description, CustomTypography typography) {
    bool isExpanded = false;
    return StatefulBuilder(
      builder: (context, setState) {
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
                              ? (isExpanded
                                  ? description
                                  : '${description.substring(0, 50)}...')
                              : description,
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              fontSize: 14)),
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

  Widget _buildEventFeedList(
      BuildContext context, CustomTypography typography) {
    return Consumer<NewsFeedProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.fetchEvent(); // Force refresh regardless of content
          },
          child: provider.isEventLoading && provider.eventFeed.isEmpty
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : provider.eventFeed.isEmpty && !provider.isEventLoading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      // Ensures pull-to-refresh even when list is empty
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
                      controller: _eventFeedScrollController,
                      itemCount: provider.eventFeed.length +
                          (provider.isEventLoadMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.eventFeed.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        var item = provider.eventFeed[index];
                        return _buildEventCard(item, typography);
                      },
                    ),
        );
      },
    );
  }

  Widget _buildEventCard(
      Map<String, dynamic> item, CustomTypography typography) {
    final notification = item['notification_body'] ?? {};
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
          timestamp = DateFormat("MMMM d, yyyy 'at' h:mm:ss a 'UTC'")
              .parseUTC(updatedAt)
              .millisecondsSinceEpoch;
        } catch (e) {
          print('Error parsing date: $e');
          timestamp =
              DateTime.now().millisecondsSinceEpoch; // Fallback to current time
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  DateFormat('MM/dd/yyyy HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal()),
                  style: typography.Caption!.copyWith(color: Colors.white54),
                ),
              ),
            ],
          ),
          ListTile(
            titleAlignment: ListTileTitleAlignment.top,
            title: Text(
              title ?? "",
              style: typography.Body1,
            ),
            subtitle: Column(
              children: [
                SizedBox(height: 4),
                _buildExpandableDescription(body ?? "", typography),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () {
                  print("View Event for $title");
                  String eventId =
                      item['event_id'] ?? ''; // Ensure process_id is available
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NotificationMapScreen(notificationData: {
                        'title': title,
                        'body': body,
                        'timestamp': timestamp,
                        'eventId': eventId,
                      }),
                    ),
                  );
                },
                child: Text(
                  'View Summary',
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
    _tabScrollController.animateTo(
      _tabScrollController.offset - 100,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _tabScrollController.animateTo(
      _tabScrollController.offset + 100,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  _getNewFeedComingSoonUI() {
    var typography = CustomTypography(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Column(
                children: [
                  Text("Stay Informed—News Feed Coming Soon! ",
                      textAlign: TextAlign.center,
                      // LanguageService.getTranslated(
                      //     context, 'coming_soon_title'),
                      style: typography.H4),
                  SizedBox(height: 8),
                  Text(
                      LanguageService.getTranslated(
                          context, 'coming_soon_subtitle'),
                      textAlign: TextAlign.center,
                      style: typography.Body1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _getNewPendingActionSoonUI() {
    var typography = CustomTypography(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Column(
                children: [
                  Text("Stay Informed—Pending Feed Coming Soon! ",
                      textAlign: TextAlign.center,
                      // LanguageService.getTranslated(
                      //     context, 'coming_soon_title'),
                      style: typography.H4),
                  SizedBox(height: 8),
                  Text(
                      LanguageService.getTranslated(
                          context, 'coming_soon_subtitle'),
                      textAlign: TextAlign.center,
                      style: typography.Body1),
                ],
              ),
            ),
          ],
        ),
      ),
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
