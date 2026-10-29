import '../../core/data/live_care_repository.dart';

import 'package:flutter/material.dart';

import '../care_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../core/errors/app_exception.dart';
import 'app_button.dart';
import 'app_text_field.dart';
import 'empty_view.dart';
import 'loading_view.dart';

void openPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

void toast(BuildContext context, String text) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

Future<bool> runCareTask(
  BuildContext context,
  Future<void> Function() work, {
  String? success,
}) async {
  try {
    await work();
    if (context.mounted && success != null) toast(context, success);
    return true;
  } on AppException catch (e) {
    if (context.mounted) toast(context, e.message);
    return false;
  } catch (_) {
    if (context.mounted) toast(context, '처리하지 못했어요. 잠시 후 다시 시도해 주세요.');
    return false;
  }
}

Future<bool> confirmCare(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('돌아가기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    ) ??
    false;
Future<String?> askText(
  BuildContext context,
  String title, {
  String label = '내용',
  String initial = '',
}) async {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(title: title, label: label, initial: initial),
  );
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    required this.initial,
  });
  final String title, label, initial;
  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final input = TextEditingController(text: widget.initial);
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: AppTextField(
          label: widget.label,
          controller: input,
          maxLines: 4,
          validator: (v) => (v?.trim().isEmpty ?? true) ? '내용을 입력해 주세요.' : null,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      TextButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, input.text.trim());
          }
        },
        child: const Text('확인'),
      ),
    ],
  );
}

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: const Color(0xFFF0F7F3),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Text(
      CareScope.of(context).repository is LiveCareRepository
          ? '합성 전용 · 실제 서버 연결 · 재시작 시 자료 초기화'
          : '체험 데이터 · 실제 서버에 전송되지 않습니다',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(fontSize: 10, color: AppColors.textSecondary),
    ),
  );
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.protected = true,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.footer,
    this.titleWidget,
  });
  final String title;
  final Widget? titleWidget;
  final Widget child;
  final bool protected;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar, floatingActionButton, footer;
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    Widget body = child;
    if (protected) {
      if (app.user == null || app.restricted || app.needsTarget) {
        body = const EmptyView(
          title: '이 화면에 접근할 수 없어요',
          message: '계정과 연결 상태를 확인해 주세요.',
        );
      } else if (app.error != null) {
        body = EmptyView(
          title: '정보를 확인해 주세요',
          message: app.error!.message,
          actionLabel: '다시 시도',
          onAction: app.refresh,
        );
      }
    }
    return Scaffold(
      appBar: AppBar(title: titleWidget ?? Text(title), actions: actions),
      body: SafeArea(
        child: Column(
          children: [
            const DemoBanner(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: body),
                  if (protected && app.loading)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: AppColors.background,
                        child: LoadingView(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: footer == null
          ? bottomNavigationBar
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: footer!,
              ),
            ),
      floatingActionButton: protected && app.data == null
          ? null
          : floatingActionButton,
    );
  }
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.onRefresh});
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.pagePadding,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
    return onRefresh == null
        ? content
        : RefreshIndicator(onRefresh: onRefresh!, child: content);
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class IconBubble extends StatelessWidget {
  const IconBubble(
    this.icon, {
    super.key,
    this.color = AppColors.primary,
    this.size = 48,
  });
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(icon, color: color, size: size * .5),
  );
}

class QuickTile extends StatelessWidget {
  const QuickTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.color = AppColors.primary,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: .06),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: color.withValues(alpha: .1)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class QuickGrid extends StatelessWidget {
  const QuickGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final columns =
          constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(16) > 27
          ? 1
          : 2;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: children
            .map((w) => SizedBox(width: width, child: w))
            .toList(),
      );
    },
  );
}

class InfoPanel extends StatelessWidget {
  const InfoPanel(
    this.text, {
    super.key,
    this.color = AppColors.primary,
    this.icon = Icons.info_outline,
  });
  final String text;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class DetailRow extends StatelessWidget {
  const DetailRow(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    ),
  );
}

class AsyncActionButton extends StatefulWidget {
  const AsyncActionButton({
    super.key,
    required this.label,
    required this.action,
    this.success,
    this.secondary = false,
  });
  final String label;
  final Future<void> Function() action;
  final String? success;
  final bool secondary;
  @override
  State<AsyncActionButton> createState() => _AsyncActionButtonState();
}

class _AsyncActionButtonState extends State<AsyncActionButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => AppButton(
    label: widget.label,
    isLoading: busy,
    variant: widget.secondary
        ? AppButtonVariant.secondary
        : AppButtonVariant.primary,
    onPressed: () async {
      if (busy) return;
      setState(() => busy = true);
      await runCareTask(context, widget.action, success: widget.success);
      if (mounted) setState(() => busy = false);
    },
  );
}
