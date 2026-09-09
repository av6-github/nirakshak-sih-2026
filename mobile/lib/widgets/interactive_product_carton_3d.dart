import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../core/theme.dart';
import '../core/api_client.dart';

class InteractiveProductCarton3D extends StatefulWidget {
  final Map<String, dynamic> declarations;
  final Map<String, dynamic> imageUrls;
  final String? productName;
  final String? category;
  final String? mrp;
  final String? mfgDate;
  final String? expDate;
  final String? batchNo;
  final String? netQuantity;
  final String? manufacturer;

  const InteractiveProductCarton3D({
    super.key,
    this.declarations = const {},
    this.imageUrls = const {},
    this.productName,
    this.category,
    this.mrp,
    this.mfgDate,
    this.expDate,
    this.batchNo,
    this.netQuantity,
    this.manufacturer,
  });

  @override
  State<InteractiveProductCarton3D> createState() => _InteractiveProductCarton3DState();
}

class _InteractiveProductCarton3DState extends State<InteractiveProductCarton3D>
    with SingleTickerProviderStateMixin {
  // Base rotation angles matching luxury 3D carton perspective
  double _rotX = 0.28; // ~16 deg
  double _rotY = -0.31; // ~-18 deg
  double _rotZ = 0.05; // ~3 deg

  late AnimationController _animController;
  late Animation<double> _returnAnimation;
  double _startX = 0.0;
  double _startY = 0.0;
  double _baseRotX = 0.28;
  double _baseRotY = -0.31;
  
  PaletteGenerator? _palette;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _extractPalette();
  }

  Future<void> _extractPalette() async {
    final urls = widget.imageUrls;
    final frontUrl = urls['front'] ?? urls['FRONT'] ?? urls.values.firstWhere((v) => v != null && v.toString().isNotEmpty, orElse: () => null);
    if (frontUrl != null && frontUrl.toString().isNotEmpty) {
      final urlStr = frontUrl.toString().startsWith('http') ? frontUrl.toString() : '${ApiClient.getBaseUrl}$frontUrl';
      try {
        final palette = await PaletteGenerator.fromImageProvider(
          NetworkImage(urlStr),
          maximumColorCount: 10,
        );
        if (mounted) {
          setState(() {
            _palette = palette;
          });
        }
      } catch (e) {
        debugPrint('Palette extraction error: $e');
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _animController.stop();
    _startX = details.localPosition.dx;
    _startY = details.localPosition.dy;
    _baseRotX = _rotX;
    _baseRotY = _rotY;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final deltaX = details.localPosition.dx - _startX;
      final deltaY = details.localPosition.dy - _startY;
      _rotY = (_baseRotY + deltaX * 0.012).clamp(-1.2, 1.2);
      _rotX = (_baseRotX - deltaY * 0.012).clamp(-0.8, 0.8);
      _rotZ = (_rotY * -0.1).clamp(-0.15, 0.15);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final startX = _rotX;
    final startY = _rotY;
    final startZ = _rotZ;

    _returnAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _animController.reset();
    _animController.addListener(() {
      final t = _returnAnimation.value;
      setState(() {
        _rotX = startX + (0.28 - startX) * t;
        _rotY = startY + (-0.31 - startY) * t;
        _rotZ = startZ + (0.05 - startZ) * t;
      });
    });
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final decl = widget.declarations;

    final name = (widget.productName != null && widget.productName!.isNotEmpty)
        ? widget.productName!
        : (decl['generic_product_name'] ?? decl['product_name'] ?? 'Not Detected');
    final mfg = (widget.manufacturer != null && widget.manufacturer!.isNotEmpty)
        ? widget.manufacturer!
        : (decl['manufacturer_name'] ?? 'Not Detected');
    final price = (widget.mrp != null && widget.mrp!.isNotEmpty)
        ? (widget.mrp!.startsWith('₹') ? widget.mrp! : '₹ ${widget.mrp}')
        : (decl['mrp'] != null ? '₹ ${decl['mrp']}' : 'Not Detected');
    final mfgD = (widget.mfgDate != null && widget.mfgDate!.isNotEmpty)
        ? widget.mfgDate!
        : (decl['manufacturing_date'] ?? decl['mfg_date'] ?? 'Missing');
    final expD = (widget.expDate != null && widget.expDate!.isNotEmpty)
        ? widget.expDate!
        : (decl['expiry_date'] ?? decl['exp_date'] ?? 'Missing');
    final batch = (widget.batchNo != null && widget.batchNo!.isNotEmpty)
        ? widget.batchNo!
        : (decl['batch_number'] ?? decl['batch_no'] ?? 'Missing');
    final netQty = (widget.netQuantity != null && widget.netQuantity!.isNotEmpty)
        ? widget.netQuantity!
        : (decl['net_quantity'] != null ? '${decl['net_quantity']} ${decl['unit'] ?? ''}'.trim() : 'Missing');

    final urls = widget.imageUrls;
    final frontUrlRaw = urls['front'] ?? urls['FRONT'] ?? urls.values.firstWhere((v) => v != null && v.toString().isNotEmpty, orElse: () => null);
    String? frontUrl;
    if (frontUrlRaw != null && frontUrlRaw.toString().isNotEmpty) {
      frontUrl = frontUrlRaw.toString().startsWith('http') ? frontUrlRaw.toString() : '${ApiClient.getBaseUrl}$frontUrlRaw';
    }

    final dominantColor = _palette?.dominantColor?.color;
    final darkVibrantColor = _palette?.darkVibrantColor?.color;
    final aura1 = dominantColor ?? AppTheme.auraCyan;
    final aura2 = darkVibrantColor ?? AppTheme.auraMint;

    return Container(
      width: double.infinity,
      height: 185,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.07),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Dot Grid & Soft Glows
            Positioned(
              top: -24,
              right: -24,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: aura1.withValues(alpha: 0.2),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: aura2.withValues(alpha: 0.22),
                ),
              ),
            ),

            // Dynamic Floor Shadow
            Positioned(
              bottom: 12,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateX(1.3)
                  ..scale(1.0 + (_rotY.abs() * 0.3), 0.6),
                child: Container(
                  width: 220,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF334155).withValues(alpha: 0.22),
                        blurRadius: 22,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: aura2.withValues(alpha: 0.18),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3D Gesture Target & Transform
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0018) // 3D perspective depth
                    ..rotateX(_rotX)
                    ..rotateY(_rotY)
                    ..rotateZ(_rotZ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Left Flap (Emerald side or Dominant Color)
                      Container(
                        width: 32,
                        height: 84,
                        decoration: BoxDecoration(
                          color: darkVibrantColor ?? const Color(0xFF059669),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                          border: Border(
                            right: BorderSide(color: dominantColor ?? AppTheme.emerald800, width: 1.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              offset: const Offset(-2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                '${netQty.toUpperCase()} TUBE',
                                style: const TextStyle(
                                  color: Color(0xFFD1FAE5),
                                  fontFamily: 'monospace',
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Text(
                              '●',
                              style: TextStyle(color: Colors.white60, fontSize: 6),
                            ),
                          ],
                        ),
                      ),

                      // Main Front Face (Pharmaceutical Carton)
                      Container(
                        width: 210,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFDC2626), // Red 600
                              Color(0xFFEF4444), // Red 500
                              Color(0xFFE11D48), // Rose 600
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                          border: Border.all(
                            color: dominantColor ?? const Color(0xFF991B1B).withValues(alpha: 0.8),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              offset: const Offset(4, 6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Glossy sheen reflection
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: 0.18),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Top Row: Title & Details
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 10,
                                                letterSpacing: -0.2,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black38,
                                                    offset: Offset(0, 1),
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              mfg,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.95),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 7.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7F1D1D).withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.red.withValues(alpha: 0.3),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Batch: $batch',
                                              style: const TextStyle(
                                                color: Color(0xFFFEE2E2),
                                                fontSize: 5.5,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            Text(
                                              'Exp: $expD',
                                              style: const TextStyle(
                                                color: Color(0xFFFEE2E2),
                                                fontSize: 5.5,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            Text(
                                              'MRP: $price',
                                              style: const TextStyle(
                                                color: Color(0xFFFDE68A),
                                                fontSize: 6,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Bottom Label Banner
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.category ?? 'Packaged Commodity',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF1E293B),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 6,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          netQty,
                                          style: const TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 6.5,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Interactive 3D Pill Badge
            Positioned(
              bottom: 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.threed_rotation_rounded,
                      size: 11,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Interactive 3D',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
