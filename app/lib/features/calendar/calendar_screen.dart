import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/features/calendar/farm_events.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/ui/crop_art.dart';
import 'package:oman_agri/features/crops/ui/labels.dart';
import 'package:oman_agri/features/farm/farm_screen.dart' show todayProvider;
import 'package:oman_agri/features/farm/farm_store.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

DateTime _day(DateTime x) => DateTime(x.year, x.month, x.day);

/// Umm al-Qura date: day, month name (in [lang]) and year.
({int day, String month, int year}) hijriOf(DateTime date, String lang) {
  final h = HijriCalendar.fromDate(date);
  return (day: h.hDay, month: hijriMonthName(h.hMonth, lang), year: h.hYear);
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final today = _day(ref.read(todayProvider));
    _month = DateTime(today.year, today.month);
    _selected = today;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final today = _day(ref.watch(todayProvider));
    final crops = {
      for (final c in ref.watch(knowledgeProvider).asData?.value.crops ?? const <Crop>[]) c.id: c
    };
    final plantings = ref.watch(farmProvider);
    final events = farmEvents(plantings, crops);
    final byDay = <DateTime, List<FarmEvent>>{};
    for (final e in events) {
      byDay.putIfAbsent(e.date, () => []).add(e);
    }
    final next = upcoming(events, today).take(6).toList();
    final selectedEvents = byDay[_selected] ?? const <FarmEvent>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(l10n.calendarTitle,
              style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary)),
        ),
        _TodayCard(today: today, lang: lang),
        const SizedBox(height: 16),
        _MonthGrid(
          month: _month,
          today: today,
          selected: _selected,
          marked: byDay.keys.toSet(),
          lang: lang,
          onMonth: (m) => setState(() => _month = m),
          onSelect: (d) => setState(() => _selected = d),
        ),
        const SizedBox(height: 16),
        _Card(
          title: l10n.calendarDayEvents,
          subtitle: latinDigits(DateFormat.MMMMEEEEd(lang).format(_selected)),
          child: selectedEvents.isEmpty
              ? Text(l10n.calendarNoEventsDay,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline))
              : Column(children: [for (final e in selectedEvents) _EventRow(event: e, today: today)]),
        ),
        const SizedBox(height: 16),
        _Card(
          title: l10n.calendarUpcoming,
          child: plantings.isEmpty
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.calendarEmptyFarm, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  FilledButton.tonal(onPressed: () => context.go('/farm'), child: Text(l10n.calendarGoToFarm)),
                ])
              : next.isEmpty
                  ? Text(l10n.calendarNoEventsDay,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline))
                  : Column(children: [for (final e in next) _EventRow(event: e, today: today, showDate: true)]),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(l10n.calendarPlantNowLater,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.today, required this.lang});
  final DateTime today;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final h = hijriOf(today, lang);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(latinDigits(DateFormat.EEEE(lang).format(today)),
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
        Text(latinDigits(DateFormat.yMMMMd(lang).format(today)), style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('${h.day} ${h.month} ${h.year} ${l10n.calendarHijriSuffix}',
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 8),
        Text(l10n.calendarHijriNote,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.65))),
      ]),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.selected,
    required this.marked,
    required this.lang,
    required this.onMonth,
    required this.onSelect,
  });
  final DateTime month, today, selected;
  final Set<DateTime> marked;
  final String lang;
  final ValueChanged<DateTime> onMonth, onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ml = MaterialLocalizations.of(context);
    final first = ml.firstDayOfWeekIndex; // 0 = Sunday
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final lead = (DateTime(month.year, month.month).weekday % 7 - first + 7) % 7;
    final hStart = hijriOf(month, lang), hEnd = hijriOf(DateTime(month.year, month.month, days), lang);
    final hRange = hStart.month == hEnd.month
        ? '${hStart.month} ${hStart.year}'
        : '${hStart.month} – ${hEnd.month} ${hEnd.year}';
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow(context),
      ),
      child: Column(children: [
        Row(children: [
          IconButton(
            tooltip: l10n.previousMonth,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onMonth(DateTime(month.year, month.month - 1)),
          ),
          Expanded(
            child: Column(children: [
              Text(latinDigits(DateFormat.yMMMM(lang).format(month)), style: theme.textTheme.titleMedium),
              Text(hRange, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ]),
          ),
          IconButton(
            tooltip: l10n.nextMonth,
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onMonth(DateTime(month.year, month.month + 1)),
          ),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(ml.narrowWeekdays[(first + i) % 7],
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline)),
              ),
            ),
        ]),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.82,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var d = 1; d <= days; d++)
              _DayCell(
                date: DateTime(month.year, month.month, d),
                hijriDay: HijriCalendar.fromDate(DateTime(month.year, month.month, d)).hDay,
                isToday: DateUtils.isSameDay(DateTime(month.year, month.month, d), today),
                isSelected: DateUtils.isSameDay(DateTime(month.year, month.month, d), selected),
                marked: marked.contains(DateTime(month.year, month.month, d)),
                onTap: onSelect,
              ),
          ],
        ),
      ]),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.hijriDay,
    required this.isToday,
    required this.isSelected,
    required this.marked,
    required this.onTap,
  });
  final DateTime date;
  final int hijriDay;
  final bool isToday, isSelected, marked;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = isSelected ? scheme.onPrimary : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: isSelected ? scheme.primary : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isToday && !isSelected ? BorderSide(color: scheme.primary, width: 1.5) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onTap(date),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${date.day}', style: theme.textTheme.titleSmall?.copyWith(color: fg)),
            Text('$hijriDay', style: theme.textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.55))),
            const SizedBox(height: 2),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: marked ? (isSelected ? scheme.onPrimary : DataColors.of(context).heat) : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, this.subtitle, required this.child});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow(context),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: theme.textTheme.titleLarge),
        if (subtitle != null)
          Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.today, this.showDate = false});
  final FarmEvent event;
  final DateTime today;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final name = event.crop.localizedName(locale);
    final text = switch (event.kind) {
      FarmEventKind.planted => l10n.eventPlanted(name),
      FarmEventKind.stageStarts => l10n.eventStageStarts(name, stageLabel(l10n, event.stage!)),
      FarmEventKind.harvest => l10n.eventHarvest(name),
    };
    final tint = cropTint(event.crop, dark: theme.brightness == Brightness.dark);
    final days = event.date.difference(today).inDays;
    return InkWell(
      onTap: () => context.push('/crops/${event.crop.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: tint.soft, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: event.kind == FarmEventKind.harvest
                ? const Icon(Icons.agriculture_outlined)
                : CropArt(cropArtAsset(event.crop), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(text, style: theme.textTheme.titleSmall),
              if (showDate)
                Text('${latinDigits(DateFormat.MMMd(locale.languageCode).format(event.date))} · ${l10n.inDays(days)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: tint.deep)),
            ]),
          ),
        ]),
      ),
    );
  }
}
