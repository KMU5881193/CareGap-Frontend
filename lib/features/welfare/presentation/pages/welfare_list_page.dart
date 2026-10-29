import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import 'welfare_detail_page.dart';

class WelfareListPage extends StatefulWidget {
  const WelfareListPage({super.key, this.standalone = false});
  final bool standalone;
  @override
  State<WelfareListPage> createState() => _WelfareListPageState();
}

class _WelfareListPageState extends State<WelfareListPage> {
  int tab = 0;
  String category = '전체', query = '';
  bool search = false;
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    final list = (app.data?.welfare ?? [])
        .where(
          (w) =>
              (category == '전체' || w.category == category) &&
              (tab != 2 || app.favoriteServices.contains(w.id)) &&
              '${w.name} ${w.description}'.contains(query),
        )
        .toList();
    final body = PageBody(
      children: [
        AppSegments<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('서비스 추천')),
            ButtonSegment(value: 1, label: Text('전체 서비스')),
            ButtonSegment(value: 2, label: Text('즐겨찾기')),
          ],
          selected: {tab},
          onSelectionChanged: (v) => setState(() => tab = v.first),
        ),
        const SizedBox(height: 18),
        const SoftBanner(
          title: '어르신에게 도움이 될 수 있는\n복지 서비스를 추천드려요.',
          message: '서비스 후보이며 자격과 출처 확인이 필요합니다.',
          asset: 'welfare_home_v1.png',
          height: 155,
        ),
        const SizedBox(height: 14),
        TextField(
          decoration: const InputDecoration(
            labelText: '복지 서비스 검색',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => query = v.trim()),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final v in ['전체', '건강', '돌봄', '식사', '주거'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(v),
                    selected: category == v,
                    onSelected: (_) => setState(() => category = v),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          EmptyView(title: tab == 2 ? '즐겨찾기한 서비스가 없어요' : '조건에 맞는 서비스가 없어요'),
        for (final w in list) ...[
          AppCard(
            padding: const EdgeInsets.all(12),
            onTap: () => openPage(context, WelfareDetailPage(serviceId: w.id)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/${w.asset}',
                    width: 76,
                    height: 76,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.name,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        w.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      const StatusBadge('자격 미확인', color: Color(0xFFBB6E6E)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: app.favoriteServices.contains(w.id)
                      ? '즐겨찾기 해제'
                      : '즐겨찾기',
                  onPressed: () => app.toggleFavorite(w.id),
                  icon: Icon(
                    app.favoriteServices.contains(w.id)
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFD4AD61),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const Text(
          '화면 확인을 위한 예시 목록입니다. 실제 자격 판정이나 신청 완료를 뜻하지 않습니다.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
    return widget.standalone ? AppPage(title: '복지 정보', child: body) : body;
  }
}
