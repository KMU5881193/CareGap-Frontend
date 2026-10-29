import 'package:flutter/material.dart';

import '../../core/models/care_models.dart';
import '../../core/utils/date_formatter.dart';
import '../care_scope.dart';
import 'app_widgets.dart';
import '../../features/records/presentation/pages/record_detail_page.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.record});
  final CareRecord record;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => openPage(context, RecordDetailPage(recordId: record.id)),
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PersonAvatar(size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${CareScope.of(context).personName(record.targetId)}님 ${record.type == VisitType.visit ? '방문' : '전화'} 상담',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                CareDate.full(record.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                record.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, size: 20),
      ],
    ),
  );
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.name,
    required this.text,
    this.staff = false,
    this.mine = false,
    this.time,
  });
  final String name, text;
  final String? time;
  final bool staff, mine;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!mine) ...[
          PersonAvatar(size: 36, staff: staff),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                children: [
                  Text(name, style: Theme.of(context).textTheme.labelMedium),
                  if (time != null)
                    Text(time!, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: mine || !staff
                      ? const Color(0xFFEAF5EF)
                      : const Color(0xFFF0F0F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(text),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
