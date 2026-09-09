import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_card.dart';
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
            backgroundColor: AppTheme.dangerRed,
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
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.emerald500)),
    );

    try {
      final data = await _apiClient.fetchManufacturerHistory(manufacturerName);
      if (mounted) {
        Navigator.pop(context);
        _buildHistoryDialog(data);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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
          backgroundColor: AppTheme.baseBackground,
          title: Text('${data['manufacturer_name']} History', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Scans: ${data['total_scans']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate800)),
                Text('Compliance Score: ${data['compliance_score']}%', style: const TextStyle(fontSize: 12, color: AppTheme.emerald600, fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: history.isEmpty
                      ? const Center(child: Text('No historical data available', style: TextStyle(color: AppTheme.slate500)))
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];
                            final status = item['status'] ?? 'UNKNOWN';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item['product_name'] ?? 'Unknown Product', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate900)),
                              subtitle: Text(item['date']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.slate500)),
                              trailing: Text(
                                status,
                                style: TextStyle(
                                  color: status == 'PASS' ? AppTheme.successGreen : (status == 'FAIL' ? AppTheme.dangerRed : AppTheme.slate500),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.slate900, foregroundColor: Colors.white),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            indicatorColor: AppTheme.slate900,
            labelColor: AppTheme.slate900,
            unselectedLabelColor: AppTheme.slate500,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              Tab(text: 'AI SCANS'),
              Tab(text: 'COMPLAINTS'),
              Tab(text: 'TRUST PORTAL'),
            ],
          ),
        ),
        body: AuraBackground(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.emerald500))
              : TabBarView(
                  children: [
                    _buildQueueList(scans),
                    _buildQueueList(complaints),
                    _buildTrustPortal(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildQueueList(List<dynamic> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No items in this queue.', style: TextStyle(color: AppTheme.slate500)));
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
              padding: const EdgeInsets.only(top: 14, bottom: 6),
              child: Text(
                item.substring(7),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.slate900),
              ),
            );
          } else if (item.startsWith('SUBHEADER:')) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
              child: Text(
                item.substring(10),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate500),
              ),
            );
          }
        }

        final isItemResolved = item['type'] == 'COMPLAINT' ? item['status'] != 'SUBMITTED' : item['is_resolved'] == true;
        final status = item['overall_compliance'] ?? item['status'] ?? 'REVIEW';

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          borderRadius: 16,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailsScreen(item: Map<String, dynamic>.from(item as Map))),
            );
          },
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.slate900),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isItemResolved
                          ? AppTheme.slate100
                          : (status == 'FAIL' || status == 'SUBMITTED' ? AppTheme.dangerRed.withValues(alpha: 0.12) : AppTheme.warningAmberLight),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isItemResolved ? (item['decision'] ?? item['status'] ?? 'RESOLVED') : status,
                      style: TextStyle(
                        color: isItemResolved
                            ? AppTheme.slate500
                            : (status == 'FAIL' || status == 'SUBMITTED' ? AppTheme.dangerRed : AppTheme.warningAmber),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (item['type'] == 'COMPLAINT') ...[
                Text(
                  'Shop: ${item['shopkeeper_name'] ?? 'Unknown'}\n'
                  'Address: ${item['shop_address'] ?? 'Unknown'}\n'
                  'Paid: ₹${item['paid_price']} | MRP: ₹${item['printed_mrp']}\n'
                  'Details: ${item['description'] ?? ''}',
                  style: const TextStyle(color: AppTheme.slate700, fontSize: 12),
                ),
              ] else ...[
                Text(
                  item['reason'] ?? 'AI Flagged compliance discrepancy requiring officer review.',
                  style: const TextStyle(color: AppTheme.slate700, fontSize: 12),
                ),
                if (item['manufacturer_name'] != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showManufacturerHistory(item['manufacturer_name']),
                    child: Text(
                      'View ${item['manufacturer_name']} History →',
                      style: const TextStyle(color: AppTheme.emerald600, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
              if (!isItemResolved) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (item['type'] == 'COMPLAINT') {
                            _handleComplaintDecision(item['complaint_id'], 'ACCEPT');
                          } else {
                            _handleDecision(item['scan_id'], 'ACCEPT');
                          }
                        },
                        icon: const Icon(Icons.check, size: 14, color: Colors.white),
                        label: const Text('ACCEPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emerald600,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (item['type'] == 'COMPLAINT') {
                            _handleComplaintDecision(item['complaint_id'], 'REJECT');
                          } else {
                            _handleDecision(item['scan_id'], 'REJECT');
                          }
                        },
                        icon: const Icon(Icons.close, size: 14, color: Colors.white),
                        label: const Text('REJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.dangerRed,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrustPortal() {
    if (_isTrustLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.emerald500));
    }
    if (_trustRatings.isEmpty) {
      return const Center(
        child: Text(
          'No manufacturers found.\nScan products to build the compliance database.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.slate500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trustRatings.length,
      itemBuilder: (context, index) {
        final mfr = _trustRatings[index];
        final rating = mfr['officer_rating'];
        Color ratingColor = AppTheme.slate500;
        if (rating == 'GREEN') ratingColor = AppTheme.successGreen;
        if (rating == 'YELLOW') ratingColor = AppTheme.warningOrange;
        if (rating == 'RED') ratingColor = AppTheme.dangerRed;

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      mfr['manufacturer_name'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ratingColor.withValues(alpha: 0.15),
                      border: Border.all(color: ratingColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rating ?? 'UNRATED',
                      style: TextStyle(color: ratingColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Scans: ${mfr['total_scans']}', style: const TextStyle(color: AppTheme.slate500, fontSize: 12)),
                  Text('AI Compliance: ${mfr['ai_compliance_score']}%', style: const TextStyle(color: AppTheme.slate800, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showRatingDialog(mfr['manufacturer_name'], rating),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.slate900),
                    foregroundColor: AppTheme.slate900,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(rating != null ? 'UPDATE TRUST RATING' : 'ASSIGN TRUST RATING', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
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
              backgroundColor: AppTheme.baseBackground,
              title: Text('Rate: $name', style: const TextStyle(color: AppTheme.slate900, fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Assign an official Legal Metrology officer trust rating.', style: TextStyle(color: AppTheme.slate500, fontSize: 12)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedRating,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: AppTheme.slate900),
                    decoration: const InputDecoration(
                      labelText: 'Rating',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'GREEN', child: Text('GREEN (High Trust / Compliant)', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 'YELLOW', child: Text('YELLOW (Minor Infractions)', style: TextStyle(color: AppTheme.warningOrange, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 'RED', child: Text('RED (Critical Violations)', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold))),
                    ],
                    onChanged: (val) => setDialogState(() => selectedRating = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (val) => notes = val,
                    style: const TextStyle(color: AppTheme.slate900),
                    decoration: const InputDecoration(
                      labelText: 'Officer Audit Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.slate500)),
                ),
                ElevatedButton(
                  onPressed: selectedRating == null ? null : () {
                    Navigator.pop(context);
                    _handleRate(name, selectedRating!, notes);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.slate900, foregroundColor: Colors.white),
                  child: const Text('SUBMIT'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
