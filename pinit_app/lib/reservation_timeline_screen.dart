import 'package:flutter/material.dart';

import 'reservation.dart';

// ---------------------------------------------------------------------------
// 🗓️ 내 예약 타임라인 - D-day와 진행 단계(문의 → 확정 → 방문)를 한눈에
// ---------------------------------------------------------------------------
class ReservationTimelineScreen extends StatelessWidget {
  final List<Reservation> reservations;
  final void Function(Reservation reservation, int step) onStepChanged;
  final ValueChanged<Reservation> onDelete;
  final VoidCallback onBrowse; // 비어 있을 때 핀잇 픽으로 이동

  const ReservationTimelineScreen({
    super.key,
    required this.reservations,
    required this.onStepChanged,
    required this.onDelete,
    required this.onBrowse,
  });

  String _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_note, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                '아직 예약이 없어요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '핀잇 픽에서 디자인을 골라 예약 문의를 해보세요.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onBrowse,
                child: const Text('디자인 둘러보기'),
              ),
            ],
          ),
        ),
      );
    }

    // 다가오는 예약: 오늘 이후 + 방문 전 / 지난 예약: 날짜가 지났거나 방문 완료
    final upcoming = reservations.where((r) => r.daysLeft() >= 0 && !r.isDone).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final past = reservations.where((r) => r.daysLeft() < 0 || r.isDone).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (upcoming.isNotEmpty) ...[
          _sectionHeader('다가오는 예약', upcoming.length),
          for (var i = 0; i < upcoming.length; i++)
            _buildTimelineItem(context, upcoming[i], isLast: i == upcoming.length - 1),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionHeader('지난 예약', past.length),
          for (var i = 0; i < past.length; i++)
            _buildTimelineItem(context, past[i], isLast: i == past.length - 1, faded: true),
        ],
        const SizedBox(height: 8),
        const Text(
          '단계를 눌러 진행 상황을 바꾸고, 왼쪽으로 밀면 삭제돼요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '$title $count',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    Reservation reservation, {
    required bool isLast,
    bool faded = false,
  }) {
    final days = reservation.daysLeft();
    // 3일 이내로 다가온 예약은 빨간 D-day로 강조
    final isSoon = !faded && days <= 3;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = faded ? Colors.grey : (isSoon ? const Color(0xFFE53935) : onSurface);

    return Dismissible(
      key: ValueKey(reservation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(reservation),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 왼쪽 타임라인 선 + 점
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 오른쪽 예약 카드
            Expanded(
              child: Opacity(
                opacity: faded ? 0.6 : 1,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              reservation.isDone ? '완료' : reservation.dDayLabel(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_formatDate(reservation.date)} ${reservation.time}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            reservation.channel,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        reservation.shop,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reservation.design,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      if (reservation.price != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          reservation.price!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildStepper(reservation, onSurface),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 진행 단계: 누르면 해당 단계로 변경
  Widget _buildStepper(Reservation reservation, Color activeColor) {
    return Row(
      children: [
        for (var i = 0; i < reservationSteps.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onStepChanged(reservation, i),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= reservation.step ? activeColor : Colors.grey.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reservationSteps[i],
                    style: TextStyle(
                      fontSize: 11,
                      color: i <= reservation.step ? null : Colors.grey,
                      fontWeight: i == reservation.step ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i < reservationSteps.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
