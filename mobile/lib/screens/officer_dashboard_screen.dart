import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'details_screen.dart';

class OfficerDashboardScreen extends ConsumerStatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  ConsumerState<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends ConsumerState<OfficerDashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _queue = [];
  bool _isLoading = true;

  List<dynamic> _trustRatings = [];
  bool _isTrustLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQueue();
    _loadTrustRatings();
  }

  Future<void> _loadQueue() async {
    try {
      final scansQueue = await _apiClient.fetchReviewQueue();
      final complaintsQueue = await _apiClient.fetchComplaints();

      final combinedQueue = [
        ...scansQueue.map((s) => {'type': 'SCAN', ...s}),
        ...complaintsQueue.map((c) => {'type': 'COMPLAINT', ...c}),
      ];

      // Sort by date (assuming created_at exists, else keep order)
      combinedQueue.sort((a, b) {
        final dateA = a['created_at'] ?? '';
        final dateB = b['created_at'] ?? '';
        return dateB.compareTo(dateA);
      });

      setState(() {
        _queue = combinedQueue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _queue = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load queue: ${e.toString()}'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadTrustRatings() async {
    setState(() => _isTrustLoading = true);
    try {
      final ratings = await _apiClient.fetchManufacturerRatings();
      setState(() {
        _trustRatings = ratings;
        _isTrustLoading = false;
      });
    } catch (e) {
      setState(() {
        _isTrustLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load trust ratings: $e')),
        );
      }
    }
  }

  Future<void> _handleRate(String name, String rating, String? notes) async {
    final auth = ref.read(authProvider);
    try {
      await _apiClient.rateManufacturer(name, auth.userId, rating, notes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$rating rating assigned to $name.')),
        );
        _loadTrustRatings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning rating: $e')),
        );
      }
    }
  }

  Future<void> _handleDecision(String scanId, String decision) async {
    final auth = ref.read(authProvider);
    try {
      await _apiClient.submitReview(scanId, auth.userId, decision, 'Officer verification action');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Decision $decision recorded for scan $scanId.')),
        );
        _loadQueue();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleComplaintDecision(String complaintId, String decision) async {
    final auth = ref.read(authProvider);
    try {
      final status = decision == 'ACCEPT' ? 'RESOLVED' : 'REJECTED';
      await _apiClient.reviewComplaint(complaintId, auth.userId, status, 'Officer reviewed complaint');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Complaint $decision recorded.')),
        );
        _loadQueue();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showManufacturerHistory(String manufacturerName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
    );

    try {
      final data = await _apiClient.fetchManufacturerHistory(manufacturerName);
      if (mounted) {
        Navigator.pop(context); // close loading
        _buildHistoryDialog(data);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: ${e.toString()}')),
        );
      }
    }
  }

  void _buildHistoryDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        final history = data['history'] as List<dynamic>? ?? [];
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: Text('${data['manufacturer_name']} History', style: const TextStyle(fontSize: 18, color: AppTheme.accentCyan)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Scans: ${data['total_scans']}'),
                Text('Compliance Score: ${data['compliance_score']}%'),
                const Divider(color: Colors.grey),
                Expanded(
                  child: history.isEmpty
                      ? const Center(child: Text('No historical data available'))
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];
                            final status = item['status'] ?? 'UNKNOWN';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item['product_name'] ?? 'Unknown Product', style: const TextStyle(fontSize: 14)),
                              subtitle: Text(item['date']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 12)),
                              trailing: Text(
                                status,
                                style: TextStyle(
                                  color: status == 'PASS' ? AppTheme.successGreen : (status == 'FAIL' ? AppTheme.dangerRed : Colors.grey),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final scans = _queue.where((q) => q['type'] == 'SCAN').toList();
    final complaints = _queue.where((q) => q['type'] == 'COMPLAINT').toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enforcement Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: () => context.go('/login'),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppTheme.accentCyan,
            labelColor: AppTheme.accentCyan,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'AI SCANS'),
              Tab(text: 'COMPLAINTS'),
              Tab(text: 'TRUST PORTAL'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
            : TabBarView(
                children: [
                  _buildQueueList(scans),
                  _buildQueueList(complaints),
                  _buildTrustPortal(),
                ],
              ),
      ),
    );
  }

  Widget _buildQueueList(List<dynamic> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No items in this queue.'));
    }

    final pending = items.where((i) {
      if (i['type'] == 'COMPLAINT') return i['status'] == 'SUBMITTED';
      return i['is_resolved'] != true;
    }).toList();

    final resolved = items.where((i) {
      if (i['type'] == 'COMPLAINT') return i['status'] != 'SUBMITTED';
      return i['is_resolved'] == true;
    }).toList();

    final pendingByBrand = <String, List<dynamic>>{};
    for (var item in pending) {
      final brand = item['manufacturer_name'] ?? item['shopkeeper_name'] ?? 'Unknown Brand';
      pendingByBrand.putIfAbsent(brand, () => []).add(item);
    }

    final listItems = [];
    if (pending.isNotEmpty) {
      listItems.add('HEADER:Pending Requests');
      pendingByBrand.forEach((brand, brandItems) {
        listItems.add('SUBHEADER:$brand');
        listItems.addAll(brandItems);
      });
    }

    if (resolved.isNotEmpty) {
      listItems.add('HEADER:Resolved Requests');
      listItems.addAll(resolved);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        final item = listItems[index];
        if (item is String) {
          if (item.startsWith('HEADER:')) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                item.substring(7),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
              ),
            );
          } else if (item.startsWith('SUBHEADER:')) {
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4, left: 8),
              child: Text(
                item.substring(10),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            );
          }
        }

        final isItemResolved = item['type'] == 'COMPLAINT' ? item['status'] != 'SUBMITTED' : item['is_resolved'] == true;
        final status = item['overall_compliance'] ?? item['status'] ?? 'REVIEW';
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsScreen(item: Map<String, dynamic>.from(item as Map)),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['type'] == 'SCAN'
                            ? 'Scan: ${(item['scan_id'] ?? '').toString().length > 8 ? (item['scan_id'] ?? '').toString().substring(0, 8) + '...' : item['scan_id']}'
                            : 'Complaint: ${(item['complaint_id'] ?? '').toString().length > 8 ? (item['complaint_id'] ?? '').toString().substring(0, 8) + '...' : item['complaint_id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isItemResolved
                            ? Colors.grey.withValues(alpha: 0.2)
                            : (status == 'FAIL' || status == 'SUBMITTED' ? AppTheme.dangerRed : AppTheme.warningOrange).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isItemResolved ? (item['decision'] ?? item['status'] ?? 'RESOLVED') : status,
                        style: TextStyle(
                          color: isItemResolved
                              ? Colors.grey
                              : (status == 'FAIL' || status == 'SUBMITTED' ? AppTheme.dangerRed : AppTheme.warningOrange),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (item['type'] == 'COMPLAINT') ...[
                  Text(
                    'Shop: ${item['shopkeeper_name'] ?? 'Unknown'}\n'
                    'Address: ${item['shop_address'] ?? 'Unknown'}\n'
                    'Paid: ₹${item['paid_price']} | MRP: ₹${item['printed_mrp']}\n'
                    'Details: ${item['description'] ?? ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (item['receipt_image_url'] != null || item['product_image_url'] != null) ...[
                    const SizedBox(height: 12),
                    const Text('Attached Evidence:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item['receipt_image_url'] != null)
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                '${ApiClient.getBaseUrl}${item['receipt_image_url']}',
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (c,e,s) => Container(height: 100, color: Colors.grey[800], child: const Icon(Icons.broken_image)),
                              ),
                            ),
                          ),
                        if (item['receipt_image_url'] != null && item['product_image_url'] != null)
                          const SizedBox(width: 8),
                        if (item['product_image_url'] != null)
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                '${ApiClient.getBaseUrl}${item['product_image_url']}',
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (c,e,s) => Container(height: 100, color: Colors.grey[800], child: const Icon(Icons.broken_image)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ] else ...[
                  Text(
                    item['reason'] ?? 'AI Flagged compliance discrepancy requiring human officer audit.',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (item['image_urls'] != null && (item['image_urls'] as Map).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Scan Photos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: (item['image_urls'] as Map).entries.map<Widget>((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  Image.network(
                                    '${ApiClient.getBaseUrl}${entry.value}',
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c,e,s) => Container(height: 80, width: 80, color: Colors.grey[800], child: const Icon(Icons.broken_image)),
                                  ),
                                  Positioned(
                                    bottom: 0, left: 0, right: 0,
                                    child: Container(
                                      color: Colors.black54,
                                      padding: const EdgeInsets.all(2),
                                      child: Text(entry.key.toString().toUpperCase(), style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  if (item['manufacturer_name'] != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _showManufacturerHistory(item['manufacturer_name']),
                        icon: const Icon(Icons.history, size: 14, color: AppTheme.accentCyan),
                        label: Text('View ${item['manufacturer_name']} History', style: const TextStyle(color: AppTheme.accentCyan, fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ],
                if (!isItemResolved) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 80) / 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (item['type'] == 'COMPLAINT') {
                              _handleComplaintDecision(item['complaint_id'], 'ACCEPT');
                            } else {
                              _handleDecision(item['scan_id'], 'ACCEPT');
                            }
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('ACCEPT', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 80) / 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (item['type'] == 'COMPLAINT') {
                              _handleComplaintDecision(item['complaint_id'], 'REJECT');
                            } else {
                              _handleDecision(item['scan_id'], 'REJECT');
                            }
                          },
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('REJECT', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dangerRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (item['type'] == 'SCAN')
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/scan'),
                            icon: const Icon(Icons.camera_alt, size: 16, color: AppTheme.warningOrange),
                            label: const Text('RESCAN PRODUCT', style: TextStyle(color: AppTheme.warningOrange, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.warningOrange),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildTrustPortal() {
    if (_isTrustLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan));
    }
    if (_trustRatings.isEmpty) {
      return const Center(
        child: Text(
          'No manufacturers found.\nScan products to build the database.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trustRatings.length,
      itemBuilder: (context, index) {
        final mfr = _trustRatings[index];
        final rating = mfr['officer_rating'];
        Color ratingColor = Colors.grey;
        if (rating == 'GREEN') ratingColor = AppTheme.successGreen;
        if (rating == 'YELLOW') ratingColor = AppTheme.warningOrange;
        if (rating == 'RED') ratingColor = AppTheme.dangerRed;

        return Card(
          color: AppTheme.cardDark,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        mfr['manufacturer_name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ratingColor.withOpacity(0.2),
                        border: Border.all(color: ratingColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        rating ?? 'UNRATED',
                        style: TextStyle(color: ratingColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Scans: ${mfr['total_scans']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    Text('AI Score: ${mfr['ai_compliance_score']}%', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                if (mfr['officer_notes'] != null && mfr['officer_notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('"${mfr['officer_notes']}"', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showRatingDialog(mfr['manufacturer_name'], rating),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.accentCyan),
                      foregroundColor: AppTheme.accentCyan,
                    ),
                    child: Text(rating != null ? 'UPDATE RATING' : 'ASSIGN RATING'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRatingDialog(String name, String? currentRating) {
    String? selectedRating = currentRating;
    String notes = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardDark,
              title: Text('Rate: $name', style: const TextStyle(color: AppTheme.accentCyan)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Assign an official officer trust rating.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRating,
                    dropdownColor: AppTheme.cardDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Rating',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'GREEN', child: Text('GREEN (Trusted)', style: TextStyle(color: AppTheme.successGreen))),
                      DropdownMenuItem(value: 'YELLOW', child: Text('YELLOW (Warning)', style: TextStyle(color: AppTheme.warningOrange))),
                      DropdownMenuItem(value: 'RED', child: Text('RED (Critical)', style: TextStyle(color: AppTheme.dangerRed))),
                    ],
                    onChanged: (val) => setDialogState(() => selectedRating = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (val) => notes = val,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: selectedRating == null ? null : () {
                    Navigator.pop(context);
                    _handleRate(name, selectedRating!, notes);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan, foregroundColor: AppTheme.surfaceDark),
                  child: const Text('SUBMIT'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

