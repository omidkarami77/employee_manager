import 'package:flutter/material.dart';

void main() => runApp(const EmployeeManagerApp());

class AppText {
  const AppText._();
  static const appName = '\u0645\u062f\u06cc\u0631\u06cc\u062a \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646';
  static const dashboard = '\u062f\u0627\u0634\u0628\u0648\u0631\u062f';
  static const employees = '\u06a9\u0627\u0631\u06a9\u0646\u0627\u0646';
  static const reports = '\u06af\u0632\u0627\u0631\u0634\u200c\u0647\u0627';
  static const settings = '\u062a\u0646\u0638\u06cc\u0645\u0627\u062a';
  static const allEmployees = '\u06a9\u0644 \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646';
  static const overTenYears = '\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc \u06f1\u06f0 \u0633\u0627\u0644';
  static const overFifteenYears = '\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc \u06f1\u06f5 \u0633\u0627\u0644';
  static const overTwentyYears = '\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc \u06f2\u06f0 \u0633\u0627\u0644';
}

class EmployeeManagerApp extends StatelessWidget {
  const EmployeeManagerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: AppText.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315C9B)),
          scaffoldBackgroundColor: const Color(0xFFF6F8FC),
          fontFamily: 'Segoe UI',
        ),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: EmployeeManagerHome(),
        ),
      );
}

class EmployeeManagerHome extends StatefulWidget {
  const EmployeeManagerHome({super.key});
  @override
  State<EmployeeManagerHome> createState() => _EmployeeManagerHomeState();
}

class _EmployeeManagerHomeState extends State<EmployeeManagerHome> {
  int _selectedIndex = 0;
  static const _menuItems = [
    _NavigationItem(AppText.dashboard, Icons.grid_view_rounded),
    _NavigationItem(AppText.employees, Icons.people_outline_rounded),
    _NavigationItem(AppText.reports, Icons.assessment_outlined),
    _NavigationItem(AppText.settings, Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: _PageContent(index: _selectedIndex, compact: compact)),
              _Sidebar(
                compact: compact,
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
            ]);
          }),
        ),
      );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.compact, required this.selectedIndex, required this.onSelected});
  final bool compact;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        width: compact ? 76 : 252,
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
        decoration: const BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Color(0xFFE7EBF2)))),
        child: Column(children: [
          if (compact)
            const _Logo(compact: true)
          else
            const _Logo(),
          const SizedBox(height: 36),
          ..._EmployeeManagerHomeState._menuItems.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SidebarItem(
                  item: entry.value,
                  selected: selectedIndex == entry.key,
                  compact: compact,
                  onTap: () => onSelected(entry.key),
                ),
              )),
          const Spacer(),
          if (!compact)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: Color(0xFFE8F1EC), child: Text('\u0645')),
              title: Text('\u0645\u062f\u06cc\u0631 \u0633\u06cc\u0633\u062a\u0645', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text('\u062e\u0648\u0634 \u0622\u0645\u062f\u06cc\u062f', style: TextStyle(fontSize: 12)),
            )
          else
            const CircleAvatar(backgroundColor: Color(0xFFE8F1EC), child: Text('\u0645')),
        ]),
      );
}

class _Logo extends StatelessWidget {
  const _Logo({this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
        const CircleAvatar(radius: 23, backgroundColor: Color(0xFFE7EFFC), child: Icon(Icons.business_center_rounded, color: Color(0xFF315C9B))),
        if (!compact) ...[const SizedBox(width: 10), const Expanded(child: Text(AppText.appName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))],
      ]);
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.item, required this.selected, required this.compact, required this.onTap});
  final _NavigationItem item;
  final bool selected, compact;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF315C9B) : const Color(0xFF667085);
    return Material(
      color: selected ? const Color(0xFFE9F0FD) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 16, vertical: 13),
          child: Row(mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
            Icon(item.icon, color: color, size: 22),
            if (!compact) ...[const SizedBox(width: 12), Text(item.title, style: TextStyle(color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500))],
          ]),
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.index, required this.compact});
  final int index;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final page = switch (index) {
      0 => const _DashboardPage(),
      1 => const _EmployeesPage(),
      2 => const _ReportsPage(),
      _ => const _SettingsPage(),
    };
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: compact ? 24 : 48, vertical: 32),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1280), child: page),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.description, this.action});
  final String title, description;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1D2939))),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(color: Color(0xFF667085))),
        ])),
        ?action,
      ]);
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();
  @override
  Widget build(BuildContext context) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PageHeader(title: AppText.dashboard, description: '\u0646\u0645\u0627\u06cc\u06cc \u06a9\u0644\u06cc \u0627\u0632 \u0648\u0636\u0639\u06cc\u062a \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646 \u0645\u062c\u0645\u0648\u0639\u0647'),
        SizedBox(height: 36),
        _StatsGrid(),
        SizedBox(height: 28),
        _InfoCard(title: '\u062e\u0644\u0627\u0635\u0647 \u0648\u0636\u0639\u06cc\u062a \u0633\u0627\u0632\u0645\u0627\u0646', text: '\u0627\u0637\u0644\u0627\u0639\u0627\u062a \u0648 \u06af\u0632\u0627\u0631\u0634\u200c\u0647\u0627\u06cc \u062a\u06a9\u0645\u06cc\u0644\u06cc \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646 \u062f\u0631 \u0627\u06cc\u0646 \u0628\u062e\u0634 \u0646\u0645\u0627\u06cc\u0634 \u062f\u0627\u062f\u0647 \u062e\u0648\u0627\u0647\u0646\u062f \u0634\u062f.'),
      ]);
}

class _EmployeesPage extends StatelessWidget {
  const _EmployeesPage();
  static const displayEmployees = [
    ('\u0639\u0644\u06cc \u0627\u062d\u0645\u062f\u06cc', '\u0645\u0627\u0644\u06cc', '\u06f1\u06f2 \u0633\u0627\u0644'),
    ('\u0645\u0631\u06cc\u0645 \u0631\u0636\u0627\u06cc\u06cc', '\u0645\u0646\u0627\u0628\u0639 \u0627\u0646\u0633\u0627\u0646\u06cc', '\u06f8 \u0633\u0627\u0644'),
    ('\u0633\u0627\u0631\u0627 \u0645\u0648\u0633\u0648\u06cc', '\u0641\u0646\u0627\u0648\u0631\u06cc \u0627\u0637\u0644\u0627\u0639\u0627\u062a', '\u06f1\u06f6 \u0633\u0627\u0644'),
  ];
  static const legacyEmployees = [
    ('\u0639\u0644\u06cc \u0627\u062d\u0645\u062f\u06cc', '\u0645\u0627\u0644\u06cc', '۱۲ \u0633\u0627\u0644'),
    ('\u0645\u0631\u06cc\u0645 \u0631\u0636\u0627\u06cc\u06cc', '\u0645\u0646\u0627\u0628\u0639 \u0627\u0646\u0633\u0627\u0646\u06cc', '۸ \u0633\u0627\u0644'),
    ('\u0633\u0627\u0631\u0627 \u0645\u0648\u0633\u0648\u06cc', '\u0641\u0646\u0627\u0648\u0631\u06cc \u0627\u0637\u0644\u0627\u0639\u0627\u062a', '۱۶ \u0633\u0627\u0644'),
  ];
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PageHeader(
          title: AppText.employees,
          description: '\u0641\u0647\u0631\u0633\u062a \u0648 \u0645\u062f\u06cc\u0631\u06cc\u062a \u0627\u0637\u0644\u0627\u0639\u0627\u062a \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646',
          action: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('\u0627\u0641\u0632\u0648\u062f\u0646 \u06a9\u0627\u0631\u06a9\u0646')),
        ),
        const SizedBox(height: 28),
        _Panel(child: Column(children: [
          TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: '\u062c\u0633\u062a\u062c\u0648\u06cc \u06a9\u0627\u0631\u06a9\u0646...')),
          const SizedBox(height: 20),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
            headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475467)),
            columns: const [DataColumn(label: Text('\u0646\u0627\u0645 \u0648 \u0646\u0627\u0645 \u062e\u0627\u0646\u0648\u0627\u062f\u06af\u06cc')), DataColumn(label: Text('\u0648\u0627\u062d\u062f \u0633\u0627\u0632\u0645\u0627\u0646\u06cc')), DataColumn(label: Text('\u0633\u0627\u0628\u0642\u0647')), DataColumn(label: Text(''))],
            rows: displayEmployees.map((employee) => DataRow(cells: [DataCell(Text(employee.$1)), DataCell(Text(employee.$2)), DataCell(Text(employee.$3)), const DataCell(Icon(Icons.more_horiz_rounded))])).toList(),
          )),
        ])),
      ]);
}

class _ReportsPage extends StatelessWidget {
  const _ReportsPage();
  @override
  Widget build(BuildContext context) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PageHeader(title: AppText.reports, description: '\u06af\u0632\u0627\u0631\u0634\u200c\u0647\u0627\u06cc \u0645\u062f\u06cc\u0631\u06cc\u062a\u06cc \u0648 \u0622\u0645\u0627\u0631\u06cc \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646'),
        SizedBox(height: 28),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(width: 300, child: _ReportCard(icon: Icons.pie_chart_outline_rounded, title: '\u062a\u0631\u06a9\u06cc\u0628 \u0648\u0627\u062d\u062f\u0647\u0627', subtitle: '\u062a\u0648\u0632\u06cc\u0639 \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646 \u0628\u0631 \u0627\u0633\u0627\u0633 \u0648\u0627\u062d\u062f \u0633\u0627\u0632\u0645\u0627\u0646\u06cc')),
          SizedBox(width: 300, child: _ReportCard(icon: Icons.timeline_rounded, title: '\u0633\u0627\u0628\u0642\u0647 \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646', subtitle: '\u062a\u062d\u0644\u06cc\u0644 \u0633\u0627\u0628\u0642\u0647 \u06a9\u0627\u0631\u06cc \u062f\u0631 \u0633\u0627\u0632\u0645\u0627\u0646')),
          SizedBox(width: 300, child: _ReportCard(icon: Icons.file_download_outlined, title: '\u062e\u0631\u0648\u062c\u06cc \u06af\u0632\u0627\u0631\u0634', subtitle: '\u062f\u0631\u06cc\u0627\u0641\u062a \u0646\u0633\u062e\u0647 \u0642\u0627\u0628\u0644 \u0686\u0627\u067e \u06af\u0632\u0627\u0631\u0634\u200c\u0647\u0627')),
        ]),
      ]);
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();
  @override
  Widget build(BuildContext context) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PageHeader(title: AppText.settings, description: '\u062a\u0646\u0638\u06cc\u0645\u0627\u062a \u0639\u0645\u0648\u0645\u06cc \u0646\u0631\u0645\u200c\u0627\u0641\u0632\u0627\u0631'),
        SizedBox(height: 28),
        _Panel(child: Column(children: [
          _SettingRow(icon: Icons.business_outlined, title: '\u0627\u0637\u0644\u0627\u0639\u0627\u062a \u0633\u0627\u0632\u0645\u0627\u0646', subtitle: '\u0646\u0627\u0645 \u0648 \u0645\u0634\u062e\u0635\u0627\u062a \u0645\u062c\u0645\u0648\u0639\u0647'),
          Divider(),
          _SettingRow(icon: Icons.notifications_outlined, title: '\u0627\u0639\u0644\u0627\u0646\u200c\u0647\u0627', subtitle: '\u0645\u062f\u06cc\u0631\u06cc\u062a \u067e\u06cc\u0627\u0645\u200c\u0647\u0627 \u0648 \u06cc\u0627\u062f\u0622\u0648\u0631\u0647\u0627'),
          Divider(),
          _SettingRow(icon: Icons.security_outlined, title: '\u062f\u0633\u062a\u0631\u0633\u06cc\u200c\u0647\u0627', subtitle: '\u0646\u0642\u0634\u200c\u0647\u0627 \u0648 \u0633\u0637\u0648\u062d \u062f\u0633\u062a\u0631\u0633\u06cc \u06a9\u0627\u0631\u0628\u0631\u0627\u0646'),
        ])),
      ]);
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();
  static const stats = [
    _Stat(AppText.allEmployees, '\u06f1\u06f2\u06f8', Icons.groups_rounded, Color(0xFF315C9B), Color(0xFFE8F0FE)),
    _Stat(AppText.overTenYears, '\u06f4\u06f2', Icons.workspace_premium_outlined, Color(0xFF8B5C18), Color(0xFFFFF3DD)),
    _Stat(AppText.overFifteenYears, '\u06f2\u06f7', Icons.military_tech_outlined, Color(0xFF7D4C9E), Color(0xFFF4E9FC)),
    _Stat(AppText.overTwentyYears, '\u06f1\u06f4', Icons.emoji_events_outlined, Color(0xFF217A67), Color(0xFFE2F5F0)),
  ];
  static const legacyStats = [
    _Stat('\u06a9\u0644 \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646', '۱۲۸', Icons.groups_rounded, Color(0xFF315C9B), Color(0xFFE8F0FE)),
    _Stat('\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc ۱۰ \u0633\u0627\u0644', '۴۲', Icons.workspace_premium_outlined, Color(0xFF8B5C18), Color(0xFFFFF3DD)),
    _Stat('\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc ۱۵ \u0633\u0627\u0644', '۲۷', Icons.military_tech_outlined, Color(0xFF7D4C9E), Color(0xFFF4E9FC)),
    _Stat('\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc ۲۰ \u0633\u0627\u0644', '۱۴', Icons.emoji_events_outlined, Color(0xFF217A67), Color(0xFFE2F5F0)),
  ];
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        assert(legacyStats.isNotEmpty);
        final columns = constraints.maxWidth > 940 ? 4 : constraints.maxWidth > 590 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(spacing: 16, runSpacing: 16, children: stats.map((stat) => SizedBox(width: width, child: _StatCard(stat: stat))).toList());
      });
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final _Stat stat;
  @override
  Widget build(BuildContext context) => _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: stat.background, child: Icon(stat.icon, color: stat.color)),
        const SizedBox(height: 22),
        Text(stat.title, style: const TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('${stat.value} \u0646\u0641\u0631', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1D2939))),
      ]));
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: const Color(0xFFE8F0FE), child: Icon(icon, color: const Color(0xFF315C9B))),
        const SizedBox(height: 18), Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Color(0xFF667085))), const SizedBox(height: 16),
        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.arrow_back_rounded), label: const Text('\u0645\u0634\u0627\u0647\u062f\u0647 \u06af\u0632\u0627\u0631\u0634')),
      ]));
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: CircleAvatar(backgroundColor: const Color(0xFFF0F4FA), child: Icon(icon, color: const Color(0xFF315C9B))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left_rounded),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.text});
  final String title, text;
  @override
  Widget build(BuildContext context) => _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 10), Text(text, style: const TextStyle(color: Color(0xFF667085))),
      ]));
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
        elevation: 0, color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE7EBF2))),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      );
}

class _NavigationItem { const _NavigationItem(this.title, this.icon); final String title; final IconData icon; }
class _Stat { const _Stat(this.title, this.value, this.icon, this.color, this.background); final String title, value; final IconData icon; final Color color, background; }
