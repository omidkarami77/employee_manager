import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const EmployeeManagerApp());

class AppText {
  const AppText._();
  static const appName =
      '\u0645\u062f\u06cc\u0631\u06cc\u062a \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646';
  static const dashboard = '\u062f\u0627\u0634\u0628\u0648\u0631\u062f';
  static const employees = '\u06a9\u0627\u0631\u06a9\u0646\u0627\u0646';
  static const reports = '\u06af\u0632\u0627\u0631\u0634\u200c\u0647\u0627';
  static const settings = '\u062a\u0646\u0638\u06cc\u0645\u0627\u062a';
  static const allEmployees =
      '\u06a9\u0644 \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646';
  static const overTenYears =
      '\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc \u06f1\u06f0 \u0633\u0627\u0644';
  static const overFifteenYears =
      '\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc \u06f1\u06f5 \u0633\u0627\u0644';
  static const overTwentyYears =
      '\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc \u06f2\u06f0 \u0633\u0627\u0644';
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PageContent(index: _selectedIndex, compact: compact),
              ),
              _Sidebar(
                compact: compact,
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.compact,
    required this.selectedIndex,
    required this.onSelected,
  });
  final bool compact;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? 76 : 252,
    padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(left: BorderSide(color: Color(0xFFE7EBF2))),
    ),
    child: Column(
      children: [
        if (compact) const _Logo(compact: true) else const _Logo(),
        const SizedBox(height: 36),
        ..._EmployeeManagerHomeState._menuItems.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SidebarItem(
              item: entry.value,
              selected: selectedIndex == entry.key,
              compact: compact,
              onTap: () => onSelected(entry.key),
            ),
          ),
        ),
        const Spacer(),
        if (!compact)
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Color(0xFFE8F1EC),
              child: Text('\u0645'),
            ),
            title: Text(
              '\u0645\u062f\u06cc\u0631 \u0633\u06cc\u0633\u062a\u0645',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '\u062e\u0648\u0634 \u0622\u0645\u062f\u06cc\u062f',
              style: TextStyle(fontSize: 12),
            ),
          )
        else
          const CircleAvatar(
            backgroundColor: Color(0xFFE8F1EC),
            child: Text('\u0645'),
          ),
      ],
    ),
  );
}

class _Logo extends StatelessWidget {
  const _Logo({this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: compact
        ? MainAxisAlignment.center
        : MainAxisAlignment.start,
    children: [
      const CircleAvatar(
        radius: 23,
        backgroundColor: Color(0xFFE7EFFC),
        child: Icon(Icons.business_center_rounded, color: Color(0xFF315C9B)),
      ),
      if (!compact) ...[
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            AppText.appName,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ],
  );
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });
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
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: 13,
          ),
          child: Row(
            mainAxisAlignment: compact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(item.icon, color: color, size: 22),
              if (!compact) ...[
                const SizedBox(width: 12),
                Text(
                  item.title,
                  style: TextStyle(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
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
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 48,
        vertical: 32,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: page,
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.description,
    this.action,
  });
  final String title, description;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D2939),
              ),
            ),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: Color(0xFF667085))),
          ],
        ),
      ),
      ?action,
    ],
  );
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PageHeader(
        title: AppText.dashboard,
        description: '\u0646\u0645\u0627\u06cc\u06cc \u06a9\u0644\u06cc \u0627\u0632 \u0648\u0636\u0639\u06cc\u062a \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646 \u0645\u062c\u0645\u0648\u0639\u0647',
      ),
      SizedBox(height: 36),
      _StatsGrid(),
      SizedBox(height: 28),
      _InfoCard(
        title: '\u062e\u0644\u0627\u0635\u0647 \u0648\u0636\u0639\u06cc\u062a \u0633\u0627\u0632\u0645\u0627\u0646',
        text: '\u0627\u0637\u0644\u0627\u0639\u0627\u062a \u0648 \u06af\u0632\u0627\u0631\u0634\u200c\u0647\u0627\u06cc \u062a\u06a9\u0645\u06cc\u0644\u06cc \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646 \u062f\u0631 \u0627\u06cc\u0646 \u0628\u062e\u0634 \u0646\u0645\u0627\u06cc\u0634 \u062f\u0627\u062f\u0647 \u062e\u0648\u0627\u0647\u0646\u062f \u0634\u062f.',
      ),
    ],
  );
}

class _EmployeesPage extends StatefulWidget {
  const _EmployeesPage();
  @override
  State<_EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<_EmployeesPage> {
  final _search = TextEditingController();
  final _employees = <_Employee>[
    _Employee(
      'علی',
      'احمدی',
      '1001',
      '09121234567',
      DateTime(2012, 6, 4),
      true,
    ),
    _Employee(
      'مریم',
      'رضایی',
      '1002',
      '09122345678',
      DateTime(2017, 11, 13),
      true,
    ),
    _Employee(
      'سارا',
      'موسوی',
      '1003',
      '09351234567',
      DateTime(2009, 2, 22),
      true,
    ),
    _Employee(
      'رضا',
      'کریمی',
      '1004',
      '09124567890',
      DateTime(2020, 8, 17),
      false,
    ),
    _Employee(
      'نگار',
      'حسینی',
      '1005',
      '09361234567',
      DateTime(2015, 3, 9),
      true,
    ),
    _Employee(
      'امیر',
      'محمدی',
      '1006',
      '09127890123',
      DateTime(2022, 1, 28),
      true,
    ),
    _Employee(
      'زهرا',
      'صادقی',
      '1007',
      '09371234567',
      DateTime(2018, 9, 5),
      false,
    ),
    _Employee(
      'حسن',
      'اکبری',
      '1008',
      '09128901234',
      DateTime(2011, 12, 19),
      true,
    ),
  ];
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_Employee> get _shown {
    final q = _search.text.trim().toLowerCase();
    return q.isEmpty
        ? _employees
        : _employees
              .where(
                (e) =>
                    e.first.toLowerCase().contains(q) ||
                    e.last.toLowerCase().contains(q) ||
                    e.code.contains(q),
              )
              .toList();
  }

  Future<void> _delete(_Employee employee) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف کارمند'),
        content: Text('آیا از حذف «${employee.name}» مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (remove == true && mounted) setState(() => _employees.remove(employee));
  }

  void _notice(String action, _Employee employee) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action ${employee.name} در نسخه بعدی فعال می‌شود.'),
        ),
      );
  @override
  Widget build(BuildContext context) {
    final employees = _shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: AppText.employees,
          description: 'فهرست و مدیریت اطلاعات کارکنان',
          action: FilledButton.icon(
            onPressed: _addEmployee,
            icon: const Icon(Icons.add_rounded),
            label: const Text('افزودن کارمند'),
          ),
        ),
        const SizedBox(height: 28),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 420,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'جستجو بر اساس نام، نام خانوادگی یا کد پرسنلی',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${employees.length} کارمند',
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 30,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475467),
                  ),
                  columns: const [
                    DataColumn(label: Text('ردیف')),
                    DataColumn(label: Text('نام و نام خانوادگی')),
                    DataColumn(label: Text('کد پرسنلی')),
                    DataColumn(label: Text('شماره موبایل')),
                    DataColumn(label: Text('تاریخ استخدام')),
                    DataColumn(label: Text('سابقه')),
                    DataColumn(label: Text('وضعیت')),
                    DataColumn(label: Text('عملیات')),
                  ],
                  rows: employees.asMap().entries.map((entry) {
                    final employee = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text(_fa('${entry.key + 1}'))),
                        DataCell(
                          Text(
                            employee.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(Text(_fa(employee.code))),
                        DataCell(Text(_fa(employee.mobile))),
                        DataCell(Text(_jalali(employee.hired))),
                        DataCell(Text(_experience(employee.hired))),
                        DataCell(_StatusBadge(active: employee.active)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'مشاهده',
                                onPressed: () =>
                                    _notice('مشاهده اطلاعات', employee),
                                icon: const Icon(Icons.visibility_outlined),
                              ),
                              IconButton(
                                tooltip: 'ویرایش',
                                onPressed: () =>
                                    _notice('ویرایش اطلاعات', employee),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'حذف',
                                onPressed: () => _delete(employee),
                                color: Theme.of(context).colorScheme.error,
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addEmployee() async {
    final employee = await showDialog<_Employee>(
      context: context,
      builder: (_) => const _AddEmployeeDialog(),
    );
    if (employee != null && mounted) {
      setState(() => _employees.add(employee));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('کارمند با موفقیت ثبت شد.')));
    }
  }
}

class _AddEmployeeDialog extends StatefulWidget {
  const _AddEmployeeDialog();
  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController(),
      _last = TextEditingController(),
      _nationalId = TextEditingController(),
      _mobile = TextEditingController(),
      _code = TextEditingController(),
      _title = TextEditingController(),
      _department = TextEditingController();
  DateTime? _hireDate;
  DateTime? _endDate;
  bool _active = true;
  @override
  void dispose() {
    for (final c in [
      _first,
      _last,
      _nationalId,
      _mobile,
      _code,
      _title,
      _department,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool endDate}) async {
    final date = await showDialog<DateTime>(
      context: context,
      builder: (_) => _JalaliDatePicker(
        initialDate: endDate ? _endDate : _hireDate,
        title: endDate ? 'انتخاب تاریخ پایان همکاری' : 'انتخاب تاریخ استخدام',
      ),
    );
    if (date != null) {
      setState(() {
        if (endDate) {
          _endDate = date;
        } else {
          _hireDate = date;
        }
      });
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'این فیلد الزامی است.' : null;
  InputDecoration _dec(String text) =>
      InputDecoration(labelText: text, border: const OutlineInputBorder());
  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (_hireDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تاریخ استخدام را انتخاب کنید.')),
      );
      return;
    }
    if (!_active && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تاریخ پایان همکاری را انتخاب کنید.')),
      );
      return;
    }
    if (_endDate != null && _endDate!.isBefore(_hireDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تاریخ پایان همکاری نمی‌تواند قبل از استخدام باشد.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _Employee(
        _first.text.trim(),
        _last.text.trim(),
        _code.text.trim(),
        _mobile.text.trim(),
        _hireDate!,
        _active,
        nationalId: _nationalId.text.trim(),
        title: _title.text.trim(),
        department: _department.text.trim(),
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: AlertDialog(
      title: const Text('افزودن کارمند'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FormSectionTitle('اطلاعات شخصی'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FormField(
                      child: TextFormField(
                        controller: _first,
                        validator: _required,
                        decoration: _dec('نام'),
                      ),
                    ),
                    _FormField(
                      child: TextFormField(
                        controller: _last,
                        validator: _required,
                        decoration: _dec('نام خانوادگی'),
                      ),
                    ),
                    _FormField(
                      child: TextFormField(
                        controller: _nationalId,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 10,
                        validator: (v) => RegExp(r'^\d{10}$').hasMatch(v ?? '')
                            ? null
                            : 'کد ملی باید ۱۰ رقم باشد.',
                        decoration: _dec('کد ملی'),
                      ),
                    ),
                    _FormField(
                      child: TextFormField(
                        controller: _mobile,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 11,
                        validator: (v) => RegExp(r'^09\d{9}$').hasMatch(v ?? '')
                            ? null
                            : 'شماره موبایل معتبر نیست.',
                        decoration: _dec('شماره موبایل'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _FormSectionTitle('اطلاعات پرسنلی'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FormField(
                      child: TextFormField(
                        controller: _code,
                        validator: _required,
                        decoration: _dec('کد پرسنلی'),
                      ),
                    ),
                    _FormField(
                      child: TextFormField(
                        controller: _title,
                        validator: _required,
                        decoration: _dec('سمت'),
                      ),
                    ),
                    _FormField(
                      child: TextFormField(
                        controller: _department,
                        validator: _required,
                        decoration: _dec('واحد سازمانی'),
                      ),
                    ),
                    _FormField(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(endDate: false),
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          _hireDate == null
                              ? 'انتخاب تاریخ استخدام'
                              : _jalali(_hireDate!),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          alignment: Alignment.centerRight,
                        ),
                      ),
                    ),
                    _FormField(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'وضعیت استخدام',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: true,
                                label: Text('فعال'),
                                icon: Icon(Icons.check_circle_outline),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text('غیرفعال'),
                                icon: Icon(Icons.cancel_outlined),
                              ),
                            ],
                            selected: {_active},
                            onSelectionChanged: (value) => setState(() {
                              _active = value.first;
                              if (_active) _endDate = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                    if (!_active)
                      _FormField(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(endDate: true),
                          icon: const Icon(Icons.event_busy_outlined),
                          label: Text(
                            _endDate == null
                                ? 'انتخاب تاریخ پایان همکاری'
                                : _jalali(_endDate!),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            alignment: Alignment.centerRight,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded),
          label: const Text('ثبت کارمند'),
        ),
      ],
    ),
  );
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: Color(0xFF1D2939),
    ),
  );
}

class _FormField extends StatelessWidget {
  const _FormField({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(width: 320, child: child);
}

class _JalaliDatePicker extends StatefulWidget {
  const _JalaliDatePicker({this.initialDate, required this.title});
  final DateTime? initialDate;
  final String title;
  @override
  State<_JalaliDatePicker> createState() => _JalaliDatePickerState();
}

class _JalaliDatePickerState extends State<_JalaliDatePicker> {
  late int _year, _month, _day;
  @override
  void initState() {
    super.initState();
    final date = widget.initialDate ?? DateTime.now();
    final j = _toJalali(date.year, date.month, date.day);
    _year = j.$1;
    _month = j.$2;
    _day = j.$3;
  }

  int get _dayCount => _month <= 6
      ? 31
      : _month <= 11
      ? 30
      : _isJalaliLeap(_year)
      ? 30
      : 29;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: AlertDialog(
      title: Text(widget.title),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: _year,
            items: List.generate(
              51,
              (i) => DropdownMenuItem(
                value: 1375 + i,
                child: Text(_fa((1375 + i).toString())),
              ),
            ).reversed.toList(),
            onChanged: (v) => setState(() {
              _year = v!;
              if (_day > _dayCount) _day = _dayCount;
            }),
          ),
          const SizedBox(width: 16),
          DropdownButton<int>(
            value: _month,
            items: List.generate(
              12,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(_fa((i + 1).toString())),
              ),
            ),
            onChanged: (v) => setState(() {
              _month = v!;
              if (_day > _dayCount) _day = _dayCount;
            }),
          ),
          const SizedBox(width: 16),
          DropdownButton<int>(
            value: _day,
            items: List.generate(
              _dayCount,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(_fa((i + 1).toString())),
              ),
            ),
            onChanged: (v) => setState(() => _day = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _jalaliToGregorian(_year, _month, _day)),
          child: const Text('تأیید'),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFE2F5F0) : const Color(0xFFFDECEC),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      active ? 'فعال' : 'غیرفعال',
      style: TextStyle(
        color: active ? const Color(0xFF217A67) : const Color(0xFFB42318),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Employee {
  const _Employee(
    this.first,
    this.last,
    this.code,
    this.mobile,
    this.hired,
    this.active, {
    this.nationalId = '',
    this.title = '',
    this.department = '',
    this.endDate,
  });
  final String first, last, code, mobile;
  final DateTime hired;
  final bool active;
  final String nationalId, title, department;
  final DateTime? endDate;
  String get name => '$first $last'.trim();
}

String _experience(DateTime hired) {
  final now = DateTime.now();
  var months = (now.year - hired.year) * 12 + now.month - hired.month;
  if (now.day < hired.day) months--;
  return '${_fa('${months ~/ 12}')} سال و ${_fa('${months % 12}')} ماه';
}

String _jalali(DateTime date) {
  final j = _toJalali(date.year, date.month, date.day);
  return _fa(
    '${j.$1}/${j.$2.toString().padLeft(2, '0')}/${j.$3.toString().padLeft(2, '0')}',
  );
}

(int, int, int) _toJalali(int gy, int gm, int gd) {
  final gdims = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
      jdims = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];
  gy -= 1600;
  gm--;
  gd--;
  var days =
      365 * gy + ((gy + 3) ~/ 4) - ((gy + 99) ~/ 100) + ((gy + 399) ~/ 400);
  for (var i = 0; i < gm; i++) {
    days += gdims[i];
  }
  if (gm > 1 && ((gy % 4 == 0 && gy % 100 != 0) || gy % 400 == 0)) days++;
  days += gd - 79;
  final cycles = days ~/ 12053;
  days %= 12053;
  var jy = 979 + 33 * cycles + 4 * (days ~/ 1461);
  days %= 1461;
  if (days >= 366) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  var month = 0;
  while (month < 11 && days >= jdims[month]) {
    days -= jdims[month++];
  }
  return (jy, month + 1, days + 1);
}

bool _isJalaliLeap(int year) {
  final base = year - (year >= 474 ? 474 : 473);
  return (((base % 2820) + 474 + 38) * 682) % 2816 < 682;
}

DateTime _jalaliToGregorian(int jy, int jm, int jd) {
  final jDaysInMonth = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];
  var jYear = jy - 979;
  var dayNumber = 365 * jYear + (jYear ~/ 33) * 8 + ((jYear % 33 + 3) ~/ 4);
  for (var index = 0; index < jm - 1; index++) {
    dayNumber += jDaysInMonth[index];
  }
  dayNumber += jd - 1;
  var gYear = 1600 + 400 * (dayNumber ~/ 146097);
  dayNumber %= 146097;
  var leap = true;
  if (dayNumber >= 36525) {
    dayNumber--;
    gYear += 100 * (dayNumber ~/ 36524);
    dayNumber %= 36524;
    if (dayNumber >= 365) {
      dayNumber++;
    } else {
      leap = false;
    }
  }
  gYear += 4 * (dayNumber ~/ 1461);
  dayNumber %= 1461;
  if (dayNumber >= 366) {
    leap = false;
    dayNumber--;
    gYear += dayNumber ~/ 365;
    dayNumber %= 365;
  }
  final gDaysInMonth = [
    31,
    leap ? 29 : 28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ];
  var month = 0;
  while (dayNumber >= gDaysInMonth[month]) {
    dayNumber -= gDaysInMonth[month++];
  }
  return DateTime(gYear, month + 1, dayNumber + 1);
}

String _fa(String text) => text.replaceAllMapped(
  RegExp(r'\d'),
  (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m.group(0)!)],
);

class _ReportsPage extends StatelessWidget {
  const _ReportsPage();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PageHeader(
        title: AppText.reports,
        description: '\u06af\u0632\u0627\u0631\u0634\u200c\u0647\u0627\u06cc \u0645\u062f\u06cc\u0631\u06cc\u062a\u06cc \u0648 \u0622\u0645\u0627\u0631\u06cc \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646',
      ),
      SizedBox(height: 28),
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: 300,
            child: _ReportCard(
              icon: Icons.pie_chart_outline_rounded,
              title: '\u062a\u0631\u06a9\u06cc\u0628 \u0648\u0627\u062d\u062f\u0647\u0627',
              subtitle: '\u062a\u0648\u0632\u06cc\u0639 \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646 \u0628\u0631 \u0627\u0633\u0627\u0633 \u0648\u0627\u062d\u062f \u0633\u0627\u0632\u0645\u0627\u0646\u06cc',
            ),
          ),
          SizedBox(
            width: 300,
            child: _ReportCard(
              icon: Icons.timeline_rounded,
              title: '\u0633\u0627\u0628\u0642\u0647 \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646',
              subtitle: '\u062a\u062d\u0644\u06cc\u0644 \u0633\u0627\u0628\u0642\u0647 \u06a9\u0627\u0631\u06cc \u062f\u0631 \u0633\u0627\u0632\u0645\u0627\u0646',
            ),
          ),
          SizedBox(
            width: 300,
            child: _ReportCard(
              icon: Icons.file_download_outlined,
              title: '\u062e\u0631\u0648\u062c\u06cc \u06af\u0632\u0627\u0631\u0634',
              subtitle: '\u062f\u0631\u06cc\u0627\u0641\u062a \u0646\u0633\u062e\u0647 \u0642\u0627\u0628\u0644 \u0686\u0627\u067e \u06af\u0632\u0627\u0631\u0634\u200c\u0647\u0627',
            ),
          ),
        ],
      ),
    ],
  );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PageHeader(
        title: AppText.settings,
        description: '\u062a\u0646\u0638\u06cc\u0645\u0627\u062a \u0639\u0645\u0648\u0645\u06cc \u0646\u0631\u0645\u200c\u0627\u0641\u0632\u0627\u0631',
      ),
      SizedBox(height: 28),
      _Panel(
        child: Column(
          children: [
            _SettingRow(
              icon: Icons.business_outlined,
              title: '\u0627\u0637\u0644\u0627\u0639\u0627\u062a \u0633\u0627\u0632\u0645\u0627\u0646',
              subtitle: '\u0646\u0627\u0645 \u0648 \u0645\u0634\u062e\u0635\u0627\u062a \u0645\u062c\u0645\u0648\u0639\u0647',
            ),
            Divider(),
            _SettingRow(
              icon: Icons.notifications_outlined,
              title: '\u0627\u0639\u0644\u0627\u0646\u200c\u0647\u0627',
              subtitle: '\u0645\u062f\u06cc\u0631\u06cc\u062a \u067e\u06cc\u0627\u0645\u200c\u0647\u0627 \u0648 \u06cc\u0627\u062f\u0622\u0648\u0631\u0647\u0627',
            ),
            Divider(),
            _SettingRow(
              icon: Icons.security_outlined,
              title: '\u062f\u0633\u062a\u0631\u0633\u06cc\u200c\u0647\u0627',
              subtitle: '\u0646\u0642\u0634\u200c\u0647\u0627 \u0648 \u0633\u0637\u0648\u062d \u062f\u0633\u062a\u0631\u0633\u06cc \u06a9\u0627\u0631\u0628\u0631\u0627\u0646',
            ),
          ],
        ),
      ),
    ],
  );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();
  static const stats = [
    _Stat(
      AppText.allEmployees,
      '\u06f1\u06f2\u06f8',
      Icons.groups_rounded,
      Color(0xFF315C9B),
      Color(0xFFE8F0FE),
    ),
    _Stat(
      AppText.overTenYears,
      '\u06f4\u06f2',
      Icons.workspace_premium_outlined,
      Color(0xFF8B5C18),
      Color(0xFFFFF3DD),
    ),
    _Stat(
      AppText.overFifteenYears,
      '\u06f2\u06f7',
      Icons.military_tech_outlined,
      Color(0xFF7D4C9E),
      Color(0xFFF4E9FC),
    ),
    _Stat(
      AppText.overTwentyYears,
      '\u06f1\u06f4',
      Icons.emoji_events_outlined,
      Color(0xFF217A67),
      Color(0xFFE2F5F0),
    ),
  ];
  static const legacyStats = [
    _Stat(
      '\u06a9\u0644 \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646',
      '۱۲۸',
      Icons.groups_rounded,
      Color(0xFF315C9B),
      Color(0xFFE8F0FE),
    ),
    _Stat(
      '\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc ۱۰ \u0633\u0627\u0644',
      '۴۲',
      Icons.workspace_premium_outlined,
      Color(0xFF8B5C18),
      Color(0xFFFFF3DD),
    ),
    _Stat(
      '\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc ۱۵ \u0633\u0627\u0644',
      '۲۷',
      Icons.military_tech_outlined,
      Color(0xFF7D4C9E),
      Color(0xFFF4E9FC),
    ),
    _Stat(
      '\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc ۲۰ \u0633\u0627\u0644',
      '۱۴',
      Icons.emoji_events_outlined,
      Color(0xFF217A67),
      Color(0xFFE2F5F0),
    ),
  ];
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      assert(legacyStats.isNotEmpty);
      final columns = constraints.maxWidth > 940
          ? 4
          : constraints.maxWidth > 590
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: stats
            .map(
              (stat) => SizedBox(
                width: width,
                child: _StatCard(stat: stat),
              ),
            )
            .toList(),
      );
    },
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final _Stat stat;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: stat.background,
          child: Icon(stat.icon, color: stat.color),
        ),
        const SizedBox(height: 22),
        Text(
          stat.title,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${stat.value} \u0646\u0641\u0631',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1D2939),
          ),
        ),
      ],
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFE8F0FE),
          child: Icon(icon, color: const Color(0xFF315C9B)),
        ),
        const SizedBox(height: 18),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Color(0xFF667085))),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text(
            '\u0645\u0634\u0627\u0647\u062f\u0647 \u06af\u0632\u0627\u0631\u0634',
          ),
        ),
      ],
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    leading: CircleAvatar(
      backgroundColor: const Color(0xFFF0F4FA),
      child: Icon(icon, color: const Color(0xFF315C9B)),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_left_rounded),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.text});
  final String title, text;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(text, style: const TextStyle(color: Color(0xFF667085))),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE7EBF2)),
    ),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class _NavigationItem {
  const _NavigationItem(this.title, this.icon);
  final String title;
  final IconData icon;
}

class _Stat {
  const _Stat(this.title, this.value, this.icon, this.color, this.background);
  final String title, value;
  final IconData icon;
  final Color color, background;
}
//test for ok 