import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/care_models.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../pages/appointment_detail_page.dart';

class AppointmentTile extends StatelessWidget {
  const AppointmentTile({
    super.key,
    required this.appointment,
    this.highlight = false,
  });
  final Appointment appointment;
  final bool highlight;
  @override
  Widget build(BuildContext context) => AppCard(
    color: highlight ? AppColors.primaryLight : null,
    onTap: () =>
        openPage(context, AppointmentDetailPage(appointmentId: appointment.id)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBubble(
          appointment.type == VisitType.visit
              ? Icons.location_on_outlined
              : Icons.phone_outlined,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CareDate.full(appointment.start),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${appointment.type.label} · ${CareScope.of(context).personName(appointment.targetId)}님',
              ),
              const SizedBox(height: 8),
              StatusBadge(appointment.status.label),
            ],
          ),
        ),
        if (highlight && appointment.type == VisitType.visit)
          Image.asset(
            'assets/images/welfare_home_v1.png',
            width: 64,
            height: 64,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          )
        else
          const Icon(Icons.chevron_right),
      ],
    ),
  );
}
