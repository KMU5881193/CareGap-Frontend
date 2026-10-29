import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../appointments/presentation/pages/appointment_request_page.dart';

class WelfareDetailPage extends StatelessWidget {
  const WelfareDetailPage({super.key, required this.serviceId});
  final String serviceId;
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    final w = app.data?.welfare.where((w) => w.id == serviceId).firstOrNull;
    if (w == null) {
      return const AppPage(
        title: '복지 서비스',
        child: EmptyView(title: '서비스 정보를 확인할 수 없어요'),
      );
    }
    return AppPage(
      title: '복지 서비스 상세',
      actions: [
        IconButton(
          tooltip: '즐겨찾기',
          onPressed: () => app.toggleFavorite(w.id),
          icon: Icon(
            app.favoriteServices.contains(w.id)
                ? Icons.star
                : Icons.star_outline,
          ),
        ),
      ],
      footer: AppButton(
        label: '담당자에게 상담 문의',
        onPressed: () => openPage(context, const AppointmentRequestPage()),
      ),
      child: PageBody(
        children: [
          Image.asset(
            'assets/images/${w.asset}',
            height: 185,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: 20),
          Text(w.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge('예시 · 자격 미확인'),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DetailRow('지원 내용', w.description),
                DetailRow('대상 조건', w.requirements),
                for (final label in [
                  '신청 방법',
                  '신청 기관',
                  '필요 서류',
                  '신청 기간',
                  '공식 출처',
                  '정보 확인일',
                ])
                  DetailRow(label, '미확인'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const InfoPanel('최종 지원 자격과 신청 가능 여부는 공식 기관 또는 담당자에게 확인해 주세요.'),
        ],
      ),
    );
  }
}
