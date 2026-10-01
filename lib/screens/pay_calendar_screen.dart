import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pay_period.dart';
import '../state/app_state_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Vista de mes con las fechas de pago marcadas, más una lista de los
/// próximos pagos. Se arma con las planillas que ya están en memoria
/// (appState.payPeriods), sin pedir nada nuevo a la API.
class PayCalendarScreen extends StatefulWidget {
  const PayCalendarScreen({super.key});

  @override
  State<PayCalendarScreen> createState() => _PayCalendarScreenState();
}

class _PayCalendarScreenState extends State<PayCalendarScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthLabel(DateTime month) {
    final formatted = DateFormat('MMMM yyyy', 'es').format(month);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  void _showDayDetail(List<PayPeriod> dayPeriods) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pago del ${AppFormatters.date(dayPeriods.first.payDate)}',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final p in dayPeriods)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${AppFormatters.shortDate(p.periodStart)} – '
                          '${AppFormatters.shortDate(p.periodEnd)} · ${p.paymentMethod}',
                        ),
                      ),
                      Text(
                        AppFormatters.currency(p.netPay),
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periods = AppStateScope.of(context).payPeriods;

    final periodsByDay = <int, List<PayPeriod>>{};
    for (final p in periods) {
      if (p.payDate.year == _visibleMonth.year && p.payDate.month == _visibleMonth.month) {
        periodsByDay.putIfAbsent(p.payDate.day, () => []).add(p);
      }
    }

    // weekday: lunes=1 ... domingo=7. Queremos la semana empezando en lunes.
    final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday;
    final leadingBlanks = firstWeekday - 1;
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;

    final today = DateTime.now();
    final upcoming = periods
        .where((p) => !p.payDate.isBefore(DateTime(today.year, today.month, today.day)))
        .toList()
      ..sort((a, b) => a.payDate.compareTo(b.payDate));

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Calendario de pago'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shiftMonth(-1),
                ),
                Text(_monthLabel(_visibleMonth), style: theme.textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shiftMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _WeekdayHeader(),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemCount: leadingBlanks + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();
                final day = index - leadingBlanks + 1;
                final dayPeriods = periodsByDay[day];
                final isToday = _isSameDay(
                  DateTime(_visibleMonth.year, _visibleMonth.month, day),
                  today,
                );
                return _DayCell(
                  day: day,
                  hasPay: dayPeriods != null,
                  isToday: isToday,
                  onTap: dayPeriods != null ? () => _showDayDetail(dayPeriods) : null,
                );
              },
            ),
            const SizedBox(height: 32),
            Text('Próximos pagos', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (upcoming.isEmpty)
              Text('No tienes pagos programados a futuro.', style: theme.textTheme.bodyMedium)
            else
              ...upcoming.take(6).map((p) => _UpcomingTile(period: p)),
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  static const _labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: _labels
          .map((l) => Expanded(child: Center(child: Text(l, style: theme.textTheme.bodySmall))))
          .toList(),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool hasPay;
  final bool isToday;
  final VoidCallback? onTap;
  const _DayCell({required this.day, required this.hasPay, required this.isToday, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hasPay ? AppColors.brass.withValues(alpha: 0.18) : null,
          shape: BoxShape.circle,
          border: isToday ? Border.all(color: AppColors.ink, width: 1.5) : null,
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontWeight: hasPay ? FontWeight.w700 : FontWeight.w400,
            color: hasPay ? AppColors.brass : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final PayPeriod period;
  const _UpcomingTile({required this.period});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final daysLeft = DateTime(period.payDate.year, period.payDate.month, period.payDate.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppFormatters.date(period.payDate),
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                daysLeft <= 0 ? 'Hoy' : 'En $daysLeft día${daysLeft == 1 ? '' : 's'}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          Text(AppFormatters.currency(period.netPay), style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}
