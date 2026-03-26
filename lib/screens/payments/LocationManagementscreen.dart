import 'dart:async';
import '../../models/gift_models.dart';
import '../../utils/global_imports.dart';

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  State<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isExpanded = false;
  bool _showNotificationDot = true;

  bool _isLoading = false;
  bool _isNextPageLoading = false;
  String? _revokingGiftId;

  List<GiftResult> _giftList = [];
  List<GiftResult> _filteredList = [];
  int _currentPage = 1;
  int _totalRecords = 0;
  final int _pageSize = 20;
  DateTime? _lastFetchTime; // ✅ cache timestamp

  bool get _hasMore => _giftList.length < _totalRecords;

  String _selectedStatus = 'All Status';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce; // ✅ debounce timer

  final List<String> _statusOptions = [
    'All Status',
    'Pending',
    'Accepted',
    'Rejected',
    'Revoked',
  ];

  @override
  void initState() {
    super.initState();
    _fetchGifts(); // ✅ direct call — no addPostFrameCallback delay
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isNextPageLoading &&
        _hasMore) {
      _fetchGifts(loadMore: true);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      _applyFilters,
    );
  }

  Future<void> _fetchGifts({bool loadMore = false}) async {
    if (loadMore && _isNextPageLoading) return;
    if (!loadMore && _isLoading) return;

    if (!loadMore &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inSeconds < 30 &&
        _giftList.isNotEmpty) {
      return;
    }

    setState(() {
      if (loadMore) {
        _isNextPageLoading = true;
      } else {
        _isLoading = true;
        _currentPage = 1;
      }
    });

    try {
      final int page = loadMore ? _currentPage + 1 : 1;
      final int size = loadMore ? _pageSize : 10;

      final ApiService apiService = ApiService(AppConstant.SENT_GIFTS);
      final response = await apiService.get('?page=$page&pageSize=$size');

      if (!mounted) return;

      final GiftModel model = GiftModel.fromJson(
        Map<String, dynamic>.from(response),
      );

      setState(() {
        _totalRecords = model.totalRecords;
        _currentPage = model.page;

        if (loadMore) {
          _giftList.addAll(model.results);
        } else {
          _giftList = model.results;
          _lastFetchTime = DateTime.now();
        }

        _isLoading = false;
        _isNextPageLoading = false;
        _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isNextPageLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredList = _giftList.where((item) {
        final matchesStatus = _selectedStatus == 'All Status' ||
            item.status.toLowerCase() == _selectedStatus.toLowerCase();
        final matchesSearch = query.isEmpty ||
            item.recipientUserName.toLowerCase().contains(query) ||
            item.recipientEmail.toLowerCase().contains(query) ||
            item.senderUserName.toLowerCase().contains(query);
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Future<void> _revertGift(String giftId) async {
    setState(() => _revokingGiftId = giftId);

    try {
      final ApiService apiService = ApiService(AppConstant.REVOKE_GIFTS);
      await apiService.post({'gift_id': giftId});

      if (!mounted) return;

      setState(() => _revokingGiftId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revoked successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _lastFetchTime = null;
      _fetchGifts();
    } catch (e) {
      if (!mounted) return;
      setState(() => _revokingGiftId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to revoke: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRevokeConfirmation(String giftId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.undo_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Revoke Gift',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to revoke this gift? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _revertGift(giftId);
                },
                child: const Text(
                  'Revoke',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'revoked':
        return Colors.red;
      case 'rejected':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _capitalize(String s) =>
      s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmer(width: 180, height: 13),
          const SizedBox(height: 8),
          _shimmer(width: 220, height: 13),
          const SizedBox(height: 8),
          _shimmer(width: 120, height: 13),
          const SizedBox(height: 8),
          _shimmer(width: 100, height: 13),
          const SizedBox(height: 14),
          _shimmer(width: double.infinity, height: 44),
        ],
      ),
    );
  }

  Widget _shimmer({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);

    return SafeArea(
      child: Consumer<ThemeProvider>(
        builder: (buildContext, themeProvider, child) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: themeProvider.getTheme.colorScheme.surface,
            appBar: CustomAppBar(
              isExpanded: _isExpanded,
              showNotificationDot: _showNotificationDot,
              onExpandPressed: (isExpanded) =>
                  setState(() => _isExpanded = isExpanded),
              onSearchPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
            drawer: CustomDrawer(),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 5, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Purchase License',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const Text(
                            'Manage Share Locations',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: CustomSpacing.two),
                      Text(
                        'Shared Location Management',
                        style: typography.Body1.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: CustomSpacing.two),
                      Text(
                        'Manage shared locations, track usage, and reclaim unused allocations.',
                        style: typography.Caption.copyWith(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by name or email',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white38,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AppColors.primaryMain),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'User List',
                            style: typography.Body1.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                dropdownColor: const Color(0xFF1E1E1E),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white54,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                items: _statusOptions.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(_capitalize(status)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  _selectedStatus = value!;
                                  _applyFilters();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          itemCount: 5,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          itemBuilder: (_, __) => _buildSkeletonCard(),
                        )
                      : _filteredList.isEmpty
                          ? Center(
                              child: Text(
                                'No records found',
                                style: typography.Body1.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                _lastFetchTime = null;
                                await _fetchGifts();
                              },
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                itemCount: _filteredList.length +
                                    (_isNextPageLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _filteredList.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  return _buildGiftCard(
                                    _filteredList[index],
                                    typography,
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGiftCard(GiftResult item, CustomTypography typography) {
    final isPending = item.status.toLowerCase() == 'pending';
    final isRevoking = _revokingGiftId == item.giftId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'User Name',
                      item.recipientUserName.isNotEmpty
                          ? item.recipientUserName
                          : item.recipientEmail,
                      valueColor: AppColors.primaryMain,
                      typography: typography,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      'Email',
                      item.recipientEmail,
                      valueColor: AppColors.primaryMain,
                      typography: typography,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      'Locations Count',
                      item.credits.toString(),
                      valueColor: AppColors.primaryMain,
                      typography: typography,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      'Valid Until',
                      _formatDate(item.expiresAt),
                      valueColor: AppColors.primaryMain,
                      typography: typography,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(item.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _getStatusColor(item.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  _capitalize(item.status),
                  style: TextStyle(
                    color: _getStatusColor(item.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: isPending && !isRevoking
                  ? () => _showRevokeConfirmation(item.giftId)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPending ? AppColors.primaryMain : Colors.white12,
                foregroundColor: isPending ? Colors.black87 : Colors.white38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: isRevoking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black87,
                      ),
                    )
                  : Text(
                      'Revoke',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isPending ? Colors.black87 : Colors.white38,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    required CustomTypography typography,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label : ',
            style: typography.Caption.copyWith(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          TextSpan(
            text: value,
            style: typography.Caption.copyWith(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
