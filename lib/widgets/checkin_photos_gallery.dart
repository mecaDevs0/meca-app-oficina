import 'package:flutter/material.dart';

import '../services/evidence_service.dart';

class CheckinPhotosGallery extends StatefulWidget {
  const CheckinPhotosGallery({
    super.key,
    required this.bookingId,
    required this.hasCheckIn,
    this.onAddPhotos,
  });

  final String bookingId;
  final bool hasCheckIn;
  final VoidCallback? onAddPhotos;

  @override
  State<CheckinPhotosGallery> createState() => _CheckinPhotosGalleryState();
}

class _CheckinPhotosGalleryState extends State<CheckinPhotosGallery> {
  final EvidenceService _evidenceService = EvidenceService();

  bool _loading = true;
  List<dynamic> _photos = [];
  Map<String, dynamic>? _status;

  @override
  void initState() {
    super.initState();
    if (widget.hasCheckIn) _load();
  }

  @override
  void didUpdateWidget(CheckinPhotosGallery old) {
    super.didUpdateWidget(old);
    if (widget.hasCheckIn && !old.hasCheckIn) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final result = await _evidenceService.getCheckinPhotos(widget.bookingId);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        _photos = data?['data'] ?? [];
        _status = data?['checklist_status'];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasCheckIn) return const SizedBox.shrink();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final cardBorder = isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);
    final primaryText = isDarkMode ? Colors.white : Colors.black87;
    final secondaryText = isDarkMode ? Colors.white70 : Colors.black54;

    final isComplete = _status?['complete'] == true;
    final total = _status?['total'] ?? _photos.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_camera, color: Color(0xFF3B82F6), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fotos de Check-in',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: primaryText),
                ),
              ),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? const Color(0xFF00C977).withOpacity(0.14)
                        : Colors.orange.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isComplete ? Icons.check_circle : Icons.warning_amber,
                        color: isComplete ? const Color(0xFF00C977) : Colors.orange,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isComplete ? 'Completo' : 'Pendente',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isComplete ? const Color(0xFF00C977) : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_photos.isEmpty)
            GestureDetector(
              onTap: widget.onAddPhotos,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.photo_camera, color: secondaryText, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma foto de check-in',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryText),
                    ),
                    if (widget.onAddPhotos != null) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Toque para adicionar',
                        style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length + (widget.onAddPhotos != null && _photos.length < 20 ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == _photos.length) {
                        return GestureDetector(
                          onTap: widget.onAddPhotos,
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withOpacity(0.30),
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, color: Color(0xFF3B82F6), size: 22),
                                SizedBox(height: 4),
                                Text(
                                  'Adicionar',
                                  style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final photo = _photos[index];
                      final url = photo['url']?.toString();
                      final type = photo['type']?.toString() ?? 'generic';
                      final caption = photo['caption']?.toString() ?? '';
                      final isPainel = type == 'painel';

                      return GestureDetector(
                        onTap: () => url != null ? _showPreview(url, caption, isPainel) : null,
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorder),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (url != null)
                                  Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: cardColor,
                                      child: Icon(Icons.broken_image, color: secondaryText, size: 20),
                                    ),
                                  )
                                else
                                  Container(color: cardColor),
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPainel
                                          ? const Color(0xFF3B82F6).withOpacity(0.85)
                                          : Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: isPainel
                                        ? const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.speed, color: Colors.white, size: 9),
                                              SizedBox(width: 2),
                                              Text('Painel', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                            ],
                                          )
                                        : Text(
                                            '${index + 1}',
                                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$total foto${total != 1 ? 's' : ''} de check-in',
                    style: TextStyle(fontSize: 11, color: secondaryText),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _showPreview(String url, String caption, bool isPainel) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, color: Colors.white, size: 48),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                  if (isPainel)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speed, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Painel', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              if (caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    caption,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }
}
