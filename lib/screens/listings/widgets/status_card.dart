import '../../../utils/global_imports.dart';

class StatusCardsPage extends StatelessWidget {
  StatusCardsPage({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> cardData = [
    {
      "title": "Construction",
      "status": "Missing",
      "statusColor": Colors.red,
      "percentage": "+4%",
    },
    {
      "title": "Occupancy",
      "status": "Outdated",
      "statusColor": Colors.orange,
      "percentage": "+4%",
    },
    {
      "title": "Construction",
      "status": "Missing",
      "statusColor": Colors.red,
      "percentage": "+4%",
    },
    {
      "title": "Occupancy",
      "status": "Outdated",
      "statusColor": Colors.orange,
      "percentage": "+4%",
    },
    // add more if needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: ListView.builder(
          itemCount: cardData.length,
          padding: const EdgeInsets.only(top: 16),
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final item = cardData[index];
            return StatusCard(
              title: item['title'],
              status: item['status'],
              statusColor: item['statusColor'],
              percentage: item['percentage'],
              onUpdate: () {
                // handle update action
              },
              onSend: () {
                // handle send to vendor
              },
            );
          },
        ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final String percentage;
  final VoidCallback onUpdate;
  final VoidCallback onSend;

  const StatusCard({
    Key? key,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.percentage,
    required this.onUpdate,
    required this.onSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 8),

            // Status
            Row(
              children: [
                const Text("Status : ",
                    style: TextStyle(color: Colors.white70)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Percentage
            Text(
              "Percentage : $percentage",
              style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    type: ButtonType.elevated,
                    onPressed: () async {},
                    child: _buildButtonChild(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.two),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    type: ButtonType.outlined,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Send to Vendor",
                        style: TextStyle(color: AppColors.blue100)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonChild(BuildContext context) {
    final locationListProvider = Provider.of<LocationListProvider>(context);
    final locationProfileProvider =
        Provider.of<MyLocationListProvider>(context);

    var typography = CustomTypography(context);
    if (locationListProvider.isAddLocationLoading ||
        locationProfileProvider.isLoading) {
      return Center(
        child: SizedBox(
          height: 25,
          width: 25,
          child: CircularProgressIndicator(
            color: AppColors.black,
          ),
        ),
      );
    } else {
      return Text(
        "Update",
        style: typography.ButtonLarge.copyWith(
          color: Colors.black,
        ),
      );
    }
  }
}
