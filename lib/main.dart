import 'config/pocketbase_client.dart';
import 'data/employee_repository.dart';
import 'data/auth_repository.dart';
import 'models/app_user.dart';
import 'state/auth_cubit.dart';
import 'login_page.dart';
import 'models/employee.dart';
import 'state/employees_controller.dart';
import 'utils/experience.dart';
import 'utils/employee_report.dart';
import 'utils/localized_digits_formatter.dart';
import 'employee_details_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:math' as math;

part 'reports_page.dart';

void main() => runApp(const EmployeeManagerApp());

class AppText {
  const AppText._();
  static const appName =
      '\u0645\u062f\u06cc\u0631\u06cc\u062a \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646';
  static const dashboard = '\u062f\u0627\u0634\u0628\u0648\u0631\u062f';
  static const employees = '\u06a9\u0627\u0631\u06a9\u0646\u0627\u0646';
  static const reports = '\u06af\u0632\u0627\u0631\u0634\u200c\u0647\u0627';
  static const settings = '\u062a\u0646\u0638\u06cc\u0645\u0627\u062a';
  // Kept for existing widgets and tests that refer to the total label.
  static const allEmployees =
      '\u06a9\u0644 \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646';
  static const upToTenYears = 'تا ۱۰ سال سابقه';
  static const elevenToFifteenYears = '۱۱ تا ۱۵ سال سابقه';
  static const sixteenToTwentyYears = '۱۶ تا ۲۰ سال سابقه';
  static const twentyOneToThirtyYears = '۲۱ تا ۳۰ سال سابقه';
}

class EmployeeManagerApp extends StatefulWidget {
  const EmployeeManagerApp({super.key, this.repository, this.authRepository});
  final EmployeeRepository? repository;
  final AuthRepository? authRepository;

  @override
  State<EmployeeManagerApp> createState() => _EmployeeManagerAppState();
}

class _EmployeeManagerAppState extends State<EmployeeManagerApp>
    with WidgetsBindingObserver {
  late final AuthCubit _auth;
  late final EmployeeRepository _repository;
  bool _restoringSession = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final client = widget.authRepository?.client ?? createPocketBaseClient();
    _auth = AuthCubit(widget.authRepository ?? AuthRepository(client));
    _repository = widget.repository ?? EmployeeRepository(client);
    _auth.restore().whenComplete(() {
      if (mounted) setState(() => _restoringSession = false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _auth.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.close();
    super.dispose();
  }

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
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: BlocBuilder<AuthCubit, AuthState>(
        bloc: _auth,
        builder: (context, state) {
          if (_restoringSession || state.status == AuthStatus.initial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.status != AuthStatus.authenticated || state.user == null) {
            return LoginPage(auth: _auth);
          }
          // Disposing this navigator removes employee dialogs on logout/role change.
          return Navigator(
            key: ValueKey('${state.user!.id}:${state.user!.role.name}'),
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) =>
                  EmployeeManagerHome(repository: _repository, auth: _auth),
            ),
          );
        },
      ),
    ),
  );
}

class EmployeeManagerHome extends StatefulWidget {
  const EmployeeManagerHome({
    super.key,
    required this.repository,
    required this.auth,
  });
  final EmployeeRepository repository;
  final AuthCubit auth;
  @override
  State<EmployeeManagerHome> createState() => _EmployeeManagerHomeState();
}

class _EmployeeManagerHomeState extends State<EmployeeManagerHome> {
  int _selectedIndex = 0;
  late final EmployeesController _employees;

  @override
  void initState() {
    super.initState();
    _employees = EmployeesController(
      widget.repository,
      canManage: () => widget.auth.canManageEmployees,
    );
    _employees.loadEmployees();
  }

  @override
  void dispose() {
    _employees.dispose();
    super.dispose();
  }

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
                child: ListenableBuilder(
                  listenable: _employees,
                  builder: (context, _) => _PageContent(
                    index:
                        _selectedIndex == 3 && !widget.auth.canManageEmployees
                        ? 0
                        : _selectedIndex,
                    compact: compact,
                    controller: _employees,
                  ),
                ),
              ),
              _Sidebar(
                compact: compact,
                selectedIndex: _selectedIndex,
                user: widget.auth.state.user!,
                onLogout: widget.auth.logout,
                onSelected: (index) {
                  if (index == 3 && !widget.auth.canManageEmployees) return;
                  setState(() => _selectedIndex = index);
                },
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
    required this.user,
    required this.onLogout,
  });
  final bool compact;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final AppUser user;
  final VoidCallback onLogout;

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
        ..._EmployeeManagerHomeState._menuItems
            .asMap()
            .entries
            .where((entry) => entry.key != 3 || user.isAdmin)
            .map(
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F1EC),
              child: Text('\u0645'),
            ),
            title: Text(
              user.displayName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              user.roleLabel,
              style: const TextStyle(fontSize: 12),
            ),
          )
        else
          const CircleAvatar(
            backgroundColor: Color(0xFFE8F1EC),
            child: Text('\u0645'),
          ),
        const SizedBox(height: 8),
        if (compact)
          IconButton(
            onPressed: onLogout,
            tooltip: 'خروج از حساب',
            icon: const Icon(Icons.logout_rounded),
          )
        else
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('خروج از حساب'),
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
  const _PageContent({
    required this.index,
    required this.compact,
    required this.controller,
  });
  final EmployeesController controller;
  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Widget page;
    if (index < 3 &&
        (controller.status == EmployeesStatus.loading ||
            controller.status == EmployeesStatus.error)) {
      page = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            title: [
              AppText.dashboard,
              AppText.employees,
              AppText.reports,
            ][index],
            description: 'اطلاعات کارکنان',
          ),
          const SizedBox(height: 28),
          _Panel(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: controller.status == EmployeesStatus.loading
                    ? const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('در حال دریافت اطلاعات کارکنان…'),
                        ],
                      )
                    : Column(
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 36,
                            color: Color(0xFF667085),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.errorMessage ??
                                'ارتباط با پایگاه داده برقرار نشد',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: controller.loadEmployees,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('تلاش دوباره'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      );
    } else {
      page = switch (index) {
        0 => _DashboardPage(controller: controller),
        1 => _EmployeesPage(controller: controller),
        2 => _ReportsPage(controller: controller),
        _ => const _SettingsPage(),
      };
    }
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
  const _DashboardPage({required this.controller});
  final EmployeesController controller;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PageHeader(
        title: AppText.dashboard,
        action: IconButton(
          tooltip: 'به‌روزرسانی',
          onPressed: controller.isMutating ? null : controller.loadEmployees,
          icon: const Icon(Icons.refresh_rounded),
        ),
        description: '\u0646\u0645\u0627\u06cc\u06cc \u06a9\u0644\u06cc \u0627\u0632 \u0648\u0636\u0639\u06cc\u062a \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646 \u0645\u062c\u0645\u0648\u0639\u0647',
      ),
      SizedBox(height: 36),
      _StatsGrid(employees: controller.employees),
      SizedBox(height: 28),
      if (controller.status == EmployeesStatus.empty) ...[
        const _InfoCard(
          title: 'هنوز کارمندی ثبت نشده است.',
          text: 'از صفحه کارکنان، اولین کارمند را ثبت کنید.',
        ),
        const SizedBox(height: 20),
      ],
      _DashboardChartsGrid(employees: controller.employees),
    ],
  );
}

class _EmployeesPage extends StatefulWidget {
  const _EmployeesPage({required this.controller});
  final EmployeesController controller;
  @override
  State<_EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<_EmployeesPage> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Employee> get _shown {
    final q = _search.text.trim().toLowerCase();
    return q.isEmpty
        ? widget.controller.employees
        : widget.controller.employees
              .where(
                (e) =>
                    e.firstName.toLowerCase().contains(q) ||
                    e.lastName.toLowerCase().contains(q) ||
                    e.personnelCode.contains(q),
              )
              .toList();
  }

  Future<void> _delete(Employee employee) async {
    if (!widget.controller.canManageEmployees || widget.controller.isMutating) {
      return;
    }
    final remove = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف کارمند'),
          content: Text('آیا از حذف «${employee.fullName}» مطمئن هستید؟'),
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
      ),
    );
    if (remove != true || !mounted) return;
    try {
      await widget.controller.deleteEmployee(employee);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('کارمند با موفقیت حذف شد.')));
    } on EmployeeRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _view(Employee e) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EmployeeDetailsPage(
          employee: e,
          controller: widget.controller,
          repository: widget.controller.repository,
          onEdit: _addEmployee,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employees = _shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: AppText.employees,
          description: 'فهرست و مدیریت اطلاعات کارکنان',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'به‌روزرسانی',
                onPressed: widget.controller.isMutating
                    ? null
                    : widget.controller.loadEmployees,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 8),
              if (widget.controller.canManageEmployees)
                FilledButton.icon(
                  onPressed: widget.controller.isMutating ? null : _addEmployee,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('افزودن کارمند'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (widget.controller.isMutating) const LinearProgressIndicator(),
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
                    hintText: 'جستجو بر اساس نام، نام خانوادگی یا کد کارگزینی',
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
              if (employees.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    widget.controller.employees.isEmpty
                        ? 'هنوز کارمندی ثبت نشده است.'
                        : 'کارمندی با این مشخصات پیدا نشد.',
                  ),
                ),
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
                    DataColumn(label: Text('کد کارگزینی')),
                    DataColumn(label: Text('شماره تلفن همراه')),
                    DataColumn(label: Text('تاریخ شروع همکاری')),
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
                            employee.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(Text(_fa(employee.personnelCode))),
                        DataCell(Text(_fa(employee.mobile))),
                        DataCell(Text(_jalali(employee.hireDate))),
                        DataCell(
                          Text(_fa(employeeExperience(employee).toString())),
                        ),
                        DataCell(_StatusBadge(active: employee.isActive)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'مشاهده',
                                onPressed: () => _view(employee),
                                icon: const Icon(Icons.visibility_outlined),
                              ),
                              if (widget.controller.canManageEmployees)
                                IconButton(
                                  tooltip: 'ویرایش',
                                  onPressed: widget.controller.isMutating
                                      ? null
                                      : () => _addEmployee(employee),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                              if (widget.controller.canManageEmployees)
                                IconButton(
                                  tooltip: 'حذف',
                                  onPressed: widget.controller.isMutating
                                      ? null
                                      : () => _delete(employee),
                                  color: Theme.of(context).colorScheme.error,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
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

  Future<Employee?> _addEmployee([Employee? original]) async {
    if (!widget.controller.canManageEmployees || widget.controller.isMutating) {
      return null;
    }
    final employee = await showDialog<Employee>(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddEmployeeDialog(
        employee: original,
        employees: widget.controller.employees,
        onSave: widget.controller.saveEmployee,
      ),
    );
    if (employee != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            original == null
                ? 'کارمند با موفقیت ثبت شد.'
                : 'تغییرات با موفقیت ذخیره شد.',
          ),
        ),
      );
    }
    return employee;
  }
}

class _AddEmployeeDialog extends StatefulWidget {
  const _AddEmployeeDialog({
    this.employee,
    required this.employees,
    required this.onSave,
  });
  final Future<Employee> Function(Employee) onSave;
  final Employee? employee;
  final List<Employee> employees;
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
      _organizationalMembership = TextEditingController(),
      _lastServiceUnit = TextEditingController(),
      _specialization = TextEditingController(),
      _address = TextEditingController(),
      _battleOperations = TextEditingController(),
      _battlefrontDurationMonths = TextEditingController(),
      _wisdomCardNumber = TextEditingController(),
      _sepahBankAccountNumber = TextEditingController(),
      _veteranDisabilityPercentage = TextEditingController(),
      _dependentsCount = TextEditingController();
  String? _province;
  String? _sacrificeStatus;
  String? _collaborationType;
  String? _accommodationStatus;
  String? _educationalDegree;
  String? _maritalStatus;
  DateTime? _hireDate;
  DateTime? _employmentDate;
  DateTime? _retirementDate;
  DateTime? _endDate;
  DateTime? _dispatchDate;
  bool _active = true;
  bool _hasBattlefrontService = false;
  bool _saving = false;
  String? _saveError;
  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    if (e == null) return;
    _first.text = e.firstName;
    _last.text = e.lastName;
    _nationalId.text = e.nationalCode;
    _mobile.text = e.mobile;
    _code.text = e.personnelCode;
    _title.text = e.jobTitle;
    _organizationalMembership.text = e.organizationalMembership;
    _lastServiceUnit.text = e.lastServiceUnit;
    _specialization.text = e.specialization;
    _province = e.province.isEmpty ? null : e.province;
    _sacrificeStatus = e.sacrificeStatus.isEmpty ? null : e.sacrificeStatus;
    _maritalStatus = e.maritalStatus.isEmpty ? null : e.maritalStatus;
    _collaborationType = e.collaborationType.isEmpty
        ? null
        : e.collaborationType;
    _accommodationStatus = e.accommodationStatus.isEmpty
        ? null
        : e.accommodationStatus;
    _educationalDegree = e.educationalDegree.isEmpty
        ? null
        : e.educationalDegree;
    _address.text = e.address;
    _hasBattlefrontService = e.hasBattlefrontService;
    _battlefrontDurationMonths.text = e.battlefrontDurationMonths == 0
        ? ''
        : e.battlefrontDurationMonths.toString();
    _dispatchDate = e.dispatchDate;
    _battleOperations.text = e.battleOperations;
    _wisdomCardNumber.text = e.wisdomCardNumber;
    _sepahBankAccountNumber.text = e.sepahBankAccountNumber;
    _veteranDisabilityPercentage.text = e.veteranDisabilityPercentage;
    _dependentsCount.text = e.dependentsCount;
    _hireDate = e.hireDate;
    _employmentDate = e.employmentDate;
    _retirementDate = e.retirementDate;
    _endDate = e.endDate;
    _active = e.isActive;
  }

  String? _unique(String? v, {bool national = false}) {
    if (_required(v) != null) return _required(v);
    if (national && !RegExp(r'^\d{10}$').hasMatch(v!)) {
      return 'کد ملی باید ۱۰ رقم باشد.';
    }
    return widget.employees.any(
          (e) =>
              e.id != widget.employee?.id &&
              (national ? e.nationalCode : e.personnelCode) == v!.trim(),
        )
        ? (national ? 'کد ملی تکراری است.' : 'کد کارگزینی تکراری است.')
        : null;
  }

  @override
  void dispose() {
    for (final c in [
      _first,
      _last,
      _nationalId,
      _mobile,
      _code,
      _title,
      _organizationalMembership,
      _lastServiceUnit,
      _specialization,
      _address,
      _battleOperations,
      _battlefrontDurationMonths,
      _wisdomCardNumber,
      _sepahBankAccountNumber,
      _veteranDisabilityPercentage,
      _dependentsCount,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool endDate}) async {
    final selectedDate = endDate ? _endDate : _hireDate;
    final date = await showDialog<DateTime>(
      useRootNavigator: false,
      context: context,
      builder: (_) => _JalaliDatePicker(
        initialDate: selectedDate,
        title: endDate
            ? 'انتخاب تاریخ پایان همکاری'
            : 'انتخاب تاریخ شروع همکاری',
      ),
    );
    if (date != null && mounted) {
      setState(() {
        if (endDate) {
          _endDate = date;
        } else {
          _hireDate = date;
        }
      });
    }
  }

  Future<void> _pickEmploymentDate({required bool retirement}) async {
    final date = await showDialog<DateTime>(
      context: context,
      builder: (_) => _JalaliDatePicker(
        initialDate: retirement ? _retirementDate : _employmentDate,
        title: retirement ? 'انتخاب تاریخ بازنشستگی' : 'انتخاب تاریخ استخدام',
      ),
    );
    if (date != null && mounted) {
      setState(() {
        if (retirement) {
          _retirementDate = date;
        } else {
          _employmentDate = date;
        }
      });
    }
  }

  Widget _optionalEmploymentDateField({required bool retirement}) {
    final date = retirement ? _retirementDate : _employmentDate;
    final label = retirement ? 'تاریخ بازنشستگی' : 'تاریخ استخدام';
    return _FormField(
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () => _pickEmploymentDate(retirement: retirement),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              date == null ? '$label (اختیاری)' : '$label: ${_jalali(date)}',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              alignment: Alignment.centerRight,
            ),
          ),
          if (date != null)
            TextButton(
              onPressed: () => setState(() {
                if (retirement) {
                  _retirementDate = null;
                } else {
                  _employmentDate = null;
                }
              }),
              child: Text('پاک کردن $label'),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDispatchDate() async {
    final date = await showDialog<DateTime>(
      useRootNavigator: false,
      context: context,
      builder: (_) => _JalaliDatePicker(
        initialDate: _dispatchDate,
        title: 'انتخاب تاریخ اعزام',
      ),
    );
    if (date != null && mounted) {
      setState(() => _dispatchDate = date);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'این فیلد الزامی است.' : null;

  String _normalizeMobile(String value) {
    var mobile = value
        .replaceAllMapped(
          RegExp(r'[۰-۹]'),
          (match) =>
              String.fromCharCode(48 + match.group(0)!.codeUnitAt(0) - 0x06f0),
        )
        .replaceAllMapped(
          RegExp(r'[٠-٩]'),
          (match) =>
              String.fromCharCode(48 + match.group(0)!.codeUnitAt(0) - 0x0660),
        )
        .replaceAll(RegExp(r'[\s\-()]'), '');
    if (mobile.startsWith('+98')) mobile = '0${mobile.substring(3)}';
    if (mobile.startsWith('98') && mobile.length == 12) {
      mobile = '0${mobile.substring(2)}';
    }
    return mobile;
  }

  String? _mobileValidator(String? value) {
    final mobile = _normalizeMobile(value ?? '');
    return RegExp(r'^09\d{9}$').hasMatch(mobile)
        ? null
        : 'شماره تلفن همراه معتبر نیست.';
  }

  InputDecoration _dec(String text) =>
      InputDecoration(labelText: text, border: const OutlineInputBorder());
  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saveError = null);
    if (!_form.currentState!.validate()) return;
    if (_hireDate == null) {
      setState(() => _saveError = 'تاریخ شروع همکاری را انتخاب کنید.');
      return;
    }
    if (!_active && _endDate == null) {
      setState(() => _saveError = 'تاریخ پایان همکاری را انتخاب کنید.');
      return;
    }
    if (_endDate != null && _endDate!.isBefore(_hireDate!)) {
      setState(
        () => _saveError = 'تاریخ پایان همکاری نمی‌تواند قبل از استخدام باشد.',
      );
      return;
    }
    final battlefrontDuration = int.tryParse(_battlefrontDurationMonths.text);
    if (_hasBattlefrontService &&
        (battlefrontDuration == null || battlefrontDuration <= 0)) {
      setState(() => _saveError = 'مدت حضور در جبهه را برحسب ماه وارد کنید.');
      return;
    }
    if (_collaborationType == 'سرباز وظیفه' && _dispatchDate == null) {
      setState(() => _saveError = 'تاریخ اعزام را انتخاب کنید.');
      return;
    }
    if (_collaborationType == 'سرباز وظیفه' && _accommodationStatus == null) {
      setState(() => _saveError = 'وضعیت اسکان را انتخاب کنید.');
      return;
    }
    final employee = Employee(
      id: widget.employee?.id ?? '',
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      personnelCode: _code.text.trim(),
      mobile: _normalizeMobile(_mobile.text),
      hireDate: _hireDate!,
      employmentDate: _employmentDate,
      retirementDate: _retirementDate,
      isActive: _active,
      nationalCode: _nationalId.text.trim(),
      jobTitle: _title.text.trim(),
      organizationalMembership: _organizationalMembership.text.trim(),
      department: Employee.organizationalUnit,
      province: _province!,
      sacrificeStatus: _sacrificeStatus!,
      veteranDisabilityPercentage: _isVeteranStatus
          ? _veteranDisabilityPercentage.text.trim()
          : '',
      maritalStatus: _maritalStatus!,
      dependentsCount: _maritalStatus == 'متأهل'
          ? _dependentsCount.text.trim()
          : '',
      collaborationType: _collaborationType!,
      educationalDegree: _educationalDegree!,
      lastServiceUnit: _lastServiceUnit.text.trim(),
      specialization: _specialization.text.trim(),
      dispatchDate: _collaborationType == 'سرباز وظیفه' ? _dispatchDate : null,
      accommodationStatus: _collaborationType == 'سرباز وظیفه'
          ? _accommodationStatus!
          : '',
      address: _address.text.trim(),
      endDate: _active ? null : _endDate,
      hasBattlefrontService: _hasBattlefrontService,
      battlefrontDurationMonths: _hasBattlefrontService
          ? battlefrontDuration!
          : 0,
      battleOperations: _hasBattlefrontService
          ? _battleOperations.text.trim()
          : '',
      wisdomCardNumber: _wisdomCardNumber.text.trim(),
      sepahBankAccountNumber: _sepahBankAccountNumber.text.trim(),
    );
    setState(() => _saving = true);
    try {
      final saved = await widget.onSave(employee);
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, saved);
    } on EmployeeRepositoryException catch (error) {
      if (!mounted) return;
      setState(
        () => _saveError = error.fieldErrors.isEmpty
            ? error.message
            : error.fieldErrors.values.join('\n'),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveError = 'ذخیره اطلاعات انجام نشد. دوباره تلاش کنید.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _isVeteranStatus =>
      _sacrificeStatus == 'جانباز' || _sacrificeStatus == 'جانباز آزاده';

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          widget.employee == null ? 'افزودن کارمند' : 'ویرایش کارمند',
        ),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: AbsorbPointer(
              absorbing: _saving,
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_saveError != null) ...[
                      Text(
                        _saveError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                              const LocalizedDigitsFormatter(),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 10,
                            validator: (v) => _unique(v, national: true),
                            decoration: _dec('کد ملی'),
                          ),
                        ),
                        _FormField(
                          child: TextFormField(
                            controller: _mobile,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              const LocalizedDigitsFormatter(),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 11,
                            validator: _mobileValidator,
                            decoration: _dec('شماره تلفن همراه'),
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
                            validator: (v) => _unique(v),
                            decoration: _dec('کد کارگزینی'),
                          ),
                        ),
                        _FormField(
                          child: TextFormField(
                            controller: _title,
                            validator: _required,
                            decoration: _dec('درجه'),
                          ),
                        ),
                        _FormField(
                          child: TextFormField(
                            controller: _wisdomCardNumber,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              const LocalizedDigitsFormatter(),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _dec('شماره کارت حکمت'),
                          ),
                        ),
                        _FormField(
                          child: TextFormField(
                            controller: _sepahBankAccountNumber,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              const LocalizedDigitsFormatter(),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _dec('شماره حساب بانک سپه'),
                          ),
                        ),
                        _FormField(
                          child: TextFormField(
                            key: const ValueKey(
                              'employee-organizational-membership',
                            ),
                            controller: _organizationalMembership,
                            maxLength: 250,
                            decoration: _dec('عضویت سازمانی (اختیاری)'),
                          ),
                        ),
                        _FormField(
                          child: TextFormField(
                            key: const ValueKey('employee-department'),
                            initialValue: Employee.organizationalUnit,
                            readOnly: true,
                            decoration: _dec('واحد سازمانی'),
                          ),
                        ),
                        _FormField(
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('employee-sacrifice-status'),
                            isExpanded: true,
                            value: _sacrificeStatus,
                            validator: _required,
                            decoration: _dec('وضعیت ایثارگری'),
                            items: const [
                              DropdownMenuItem(
                                value: 'ندارد',
                                child: Text('ندارد'),
                              ),
                              DropdownMenuItem(
                                value: 'آزاده',
                                child: Text('آزاده'),
                              ),
                              DropdownMenuItem(
                                value: 'جانباز',
                                child: Text('جانباز'),
                              ),
                              DropdownMenuItem(
                                value: 'ایثارگر',
                                child: Text('ایثارگر'),
                              ),
                              DropdownMenuItem(
                                value: 'جانباز آزاده',
                                child: Text('جانباز آزاده'),
                              ),
                            ],
                            onChanged: (value) => setState(() {
                              _sacrificeStatus = value;
                              if (!_isVeteranStatus) {
                                _veteranDisabilityPercentage.clear();
                              }
                            }),
                          ),
                        ),
                        if (_isVeteranStatus)
                          _FormField(
                            child: TextFormField(
                              controller: _veteranDisabilityPercentage,
                              validator: _required,
                              decoration: _dec('درصد جانبازی'),
                            ),
                          ),
                        _FormField(
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('employee-marital-status'),
                            isExpanded: true,
                            value: _maritalStatus,
                            validator: _required,
                            decoration: _dec('وضعیت تأهل'),
                            items: const [
                              DropdownMenuItem(
                                value: 'مجرد',
                                child: Text('مجرد'),
                              ),
                              DropdownMenuItem(
                                value: 'متأهل',
                                child: Text('متأهل'),
                              ),
                            ],
                            onChanged: (value) => setState(() {
                              _maritalStatus = value;
                              if (value != 'متأهل') _dependentsCount.clear();
                            }),
                          ),
                        ),
                        if (_maritalStatus == 'متأهل')
                          _FormField(
                            child: TextFormField(
                              controller: _dependentsCount,
                              validator: _required,
                              decoration: _dec('تعداد عائله تحت تکفل'),
                            ),
                          ),
                        _FormField(
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('employee-collaboration-type'),
                            isExpanded: true,
                            value: _collaborationType,
                            validator: _required,
                            decoration: _dec('نوع همکاری'),
                            items: const [
                              DropdownMenuItem(
                                value: 'معارف جنگ و روساء گروه های استانی',
                                child: Text(
                                  'معارف جنگ و روساء گروه های استانی',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'نظامی شاغل',
                                child: Text('نظامی شاغل'),
                              ),
                              DropdownMenuItem(
                                value: 'سرباز وظیفه',
                                child: Text('سرباز وظیفه'),
                              ),
                              DropdownMenuItem(
                                value: 'پیشکوست شاغل ( هیئت مرکزی )',
                                child: Text('پیشکوست شاغل ( هیئت مرکزی )'),
                              ),
                              DropdownMenuItem(
                                value: 'پیشکوست شاغل ( گروه های استانی )',
                                child: Text('پیشکوست شاغل ( گروه های استانی )'),
                              ),
                              DropdownMenuItem(
                                value: 'اساتید',
                                child: Text('اساتید'),
                              ),
                              DropdownMenuItem(
                                value: 'اساتید پیشکسوت',
                                child: Text('اساتید پیشکسوت'),
                              ),
                            ],
                            onChanged: (value) => setState(() {
                              _collaborationType = value;
                              if (value != 'سرباز وظیفه') {
                                _dispatchDate = null;
                                _accommodationStatus = null;
                              }
                            }),
                          ),
                        ),
                        if (_collaborationType == 'سرباز وظیفه')
                          _FormField(
                            child: DropdownButtonFormField<String>(
                              key: const ValueKey(
                                'employee-accommodation-status',
                              ),
                              isExpanded: true,
                              value: _accommodationStatus,
                              validator: _required,
                              decoration: _dec('وضعیت اسکان'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'بومی',
                                  child: Text('بومی'),
                                ),
                                DropdownMenuItem(
                                  value: 'غیر بومی',
                                  child: Text('غیر بومی'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _accommodationStatus = value),
                            ),
                          ),
                        if (_collaborationType == 'سرباز وظیفه')
                          _FormField(
                            child: OutlinedButton.icon(
                              onPressed: _pickDispatchDate,
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: Text(
                                _dispatchDate == null
                                    ? 'انتخاب تاریخ اعزام'
                                    : _jalali(_dispatchDate!),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                                alignment: Alignment.centerRight,
                              ),
                            ),
                          ),
                        _FormField(
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('employee-educational-degree'),
                            isExpanded: true,
                            value: _educationalDegree,
                            validator: _required,
                            decoration: _dec('مدرک تحصیلی'),
                            items: const [
                              DropdownMenuItem(
                                value: 'بی سواد',
                                child: Text('بی سواد'),
                              ),
                              DropdownMenuItem(
                                value: 'سیکل',
                                child: Text('سیکل'),
                              ),
                              DropdownMenuItem(
                                value: 'دیپلم',
                                child: Text('دیپلم'),
                              ),
                              DropdownMenuItem(
                                value: 'فوق دیپلم',
                                child: Text('فوق دیپلم'),
                              ),
                              DropdownMenuItem(
                                value: 'لیسانس',
                                child: Text('لیسانس'),
                              ),
                              DropdownMenuItem(
                                value: 'فوق لیسانس',
                                child: Text('فوق لیسانس'),
                              ),
                              DropdownMenuItem(
                                value: 'دکترا',
                                child: Text('دکترا'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _educationalDegree = value),
                          ),
                        ),
                        _FormField(
                          child: TextFormField(
                            controller: _lastServiceUnit,
                            validator: _required,
                            decoration: _dec('آخرین یگان خدمتی'),
                          ),
                        ),
                        _FormField(
                          child: TextFormField(
                            controller: _specialization,
                            validator: _required,
                            decoration: _dec('تخصص'),
                          ),
                        ),
                        _FormField(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                key: const ValueKey('employee-province'),
                                isExpanded: true,
                                value: _province,
                                validator: _required,
                                decoration: _dec('استان محل خدمت'),
                                items: [
                                  // Preserve a legacy value during editing, even
                                  // if it was entered before provinces were fixed.
                                  if (_province != null &&
                                      !iranProvinces.contains(_province))
                                    DropdownMenuItem(
                                      value: _province,
                                      child: Text(_province!),
                                    ),
                                  ...iranProvinces.map(
                                    (province) => DropdownMenuItem(
                                      value: province,
                                      child: Text(province),
                                    ),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _province = value),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'معارف جنگ: کدام استان در حال خدمت می‌باشید؟',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _FormField(
                          child: TextFormField(
                            controller: _address,
                            minLines: 2,
                            maxLines: 3,
                            decoration: _dec('آدرس محل سکونت'),
                          ),
                        ),
                        _FormField(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('سابقه حضور در جبهه'),
                            subtitle: Text(
                              _hasBattlefrontService
                                  ? 'داشته است'
                                  : 'نداشته است',
                            ),
                            value: _hasBattlefrontService,
                            onChanged: (value) => setState(() {
                              _hasBattlefrontService = value;
                              if (!value) {
                                _battlefrontDurationMonths.clear();
                                _battleOperations.clear();
                              }
                            }),
                          ),
                        ),
                        if (_hasBattlefrontService) ...[
                          _FormField(
                            child: TextFormField(
                              controller: _battlefrontDurationMonths,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                const LocalizedDigitsFormatter(),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _dec('مدت حضور در جبهه (ماه)'),
                            ),
                          ),
                          _FormField(
                            child: TextFormField(
                              controller: _battleOperations,
                              minLines: 2,
                              maxLines: 3,
                              decoration: _dec('عملیات‌های شرکت‌کرده'),
                            ),
                          ),
                        ],
                        _FormField(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(endDate: false),
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(
                              _hireDate == null
                                  ? 'انتخاب تاریخ شروع همکاری'
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
                        _optionalEmploymentDateField(retirement: false),
                        _optionalEmploymentDateField(retirement: true),
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
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    widget.employee == null
                        ? Icons.check_rounded
                        : Icons.update_rounded,
                  ),
            label: Text(
              widget.employee == null ? 'ثبت کارمند' : 'به‌روزرسانی کارمند',
            ),
          ),
        ],
      ),
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
  late int _firstYear, _lastYear;
  @override
  void initState() {
    super.initState();
    final date = widget.initialDate ?? DateTime.now();
    final j = _toJalali(date.year, date.month, date.day);
    _year = j.$1;
    _month = j.$2;
    _day = j.$3;
    final today = DateTime.now();
    final currentYear = _toJalali(today.year, today.month, today.day).$1;
    _firstYear = _year < currentYear - 100 ? _year : currentYear - 100;
    _lastYear = _year > currentYear + 10 ? _year : currentYear + 10;
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
              _lastYear - _firstYear + 1,
              (i) => DropdownMenuItem(
                value: _firstYear + i,
                child: Text(_fa((_firstYear + i).toString())),
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
  dayNumber += jd - 1 + 79;
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
  const _StatsGrid({required this.employees});
  final List<Employee> employees;
  List<_Stat> get stats {
    final now = DateTime.now();
    int count(int minimum, int maximum) => employees.where((e) {
      final years = employeeExperience(e, now: now).years;
      return years >= minimum && years <= maximum;
    }).length;
    return [
      _Stat(
        AppText.upToTenYears,
        _fa('${count(0, 10)}'),
        Icons.groups_rounded,
        const Color(0xFF315C9B),
        const Color(0xFFE8F0FE),
      ),
      _Stat(
        AppText.elevenToFifteenYears,
        _fa('${count(11, 15)}'),
        Icons.workspace_premium_outlined,
        const Color(0xFF8B5C18),
        const Color(0xFFFFF3DD),
      ),
      _Stat(
        AppText.sixteenToTwentyYears,
        _fa('${count(16, 20)}'),
        Icons.military_tech_outlined,
        const Color(0xFF7D4C9E),
        const Color(0xFFF4E9FC),
      ),
      _Stat(
        AppText.twentyOneToThirtyYears,
        _fa('${count(21, 30)}'),
        Icons.emoji_events_outlined,
        const Color(0xFF217A67),
        const Color(0xFFE2F5F0),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
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

class _DashboardChartsGrid extends StatelessWidget {
  const _DashboardChartsGrid({required this.employees});
  final List<Employee> employees;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 16.0;
      final columns = constraints.maxWidth >= 680 ? 2 : 1;
      final cardWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          SizedBox(width: cardWidth, child: _EmploymentStatusChart(employees)),
          SizedBox(width: cardWidth, child: _ExperienceChart(employees)),
          SizedBox(width: cardWidth, child: _EducationChart(employees)),
          SizedBox(width: cardWidth, child: _HiringTrendChart(employees)),
        ],
      );
    },
  );
}

class _EmploymentStatusChart extends StatelessWidget {
  const _EmploymentStatusChart(this.employees);
  final List<Employee> employees;

  @override
  Widget build(BuildContext context) {
    final active = employees.where((employee) => employee.isActive).length;
    final inactive = employees.length - active;
    return _ChartCard(
      title: '\u0648\u0636\u0639\u06cc\u062a \u0641\u0639\u0627\u0644\u06cc\u062a \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646',
      child: _StatusPieChart(
        active: active,
        inactive: inactive,
        total: employees.length,
        labels: const [
          '\u0641\u0639\u0627\u0644',
          '\u063a\u06cc\u0631\u0641\u0639\u0627\u0644',
        ],
        colors: const [Color(0xFF217A67), Color(0xFFF2994A)],
      ),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  const _StatusPieChart({
    required this.active,
    required this.inactive,
    required this.total,
    required this.labels,
    required this.colors,
  });
  final int active, inactive, total;
  final List<String> labels;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Row(
    textDirection: TextDirection.ltr,
    children: [
      Expanded(
        flex: 5,
        child: SizedBox(
          height: 170,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final index = _pieSliceAt(
                  details.localPosition,
                  constraints.biggest,
                  [active, inactive],
                );
                if (index == null) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        '${labels[index]}: ${_fa('${index == 0 ? active : inactive}')} \u0646\u0641\u0631',
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
              },
              child: CustomPaint(
                painter: _DonutChartPainter(active: active, total: total),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 24),
      Expanded(
        flex: 6,
        child: _ChartLegend(
          items: [
            _LegendItem(labels[0], active, colors[0]),
            _LegendItem(labels[1], inactive, colors[1]),
          ],
        ),
      ),
    ],
  );
}

class _ExperienceChart extends StatelessWidget {
  const _ExperienceChart(this.employees);
  final List<Employee> employees;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final values = [0, 0, 0, 0];
    for (final employee in employees) {
      final years = employeeExperience(employee, now: now).years;
      values[years <= 10
          ? 0
          : years <= 15
          ? 1
          : years <= 20
          ? 2
          : 3]++;
    }
    return _ChartCard(
      title: '\u062a\u0648\u0632\u06cc\u0639 \u0633\u0627\u0628\u0642\u0647 \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646',
      child: _PieChart(
        labels: const [
          '\u06f0\u2013\u06f1\u06f0',
          '\u06f1\u06f1\u2013\u06f1\u06f5',
          '\u06f1\u06f6\u2013\u06f2\u06f0',
          '\u06f2\u06f1+',
        ],
        values: values,
        colors: const [
          Color(0xFF2878B5),
          Color(0xFF2E9D67),
          Color(0xFFF0A12B),
          Color(0xFF8B5CC7),
        ],
        detailSuffix: '\u0633\u0627\u0644 \u0633\u0627\u0628\u0642\u0647',
      ),
    );
  }
}

class _EducationChart extends StatelessWidget {
  const _EducationChart(this.employees);
  final List<Employee> employees;
  @override
  Widget build(BuildContext context) {
    const labels = [
      '\u062f\u06cc\u067e\u0644\u0645',
      '\u06a9\u0627\u0631\u062f\u0627\u0646\u06cc',
      '\u06a9\u0627\u0631\u0634\u0646\u0627\u0633\u06cc',
      '\u062a\u06a9\u0645\u06cc\u0644\u06cc',
      '\u062b\u0628\u062a \u0646\u0634\u062f\u0647',
    ];
    final values = List<int>.filled(labels.length, 0);
    for (final employee in employees) {
      final degree = employee.educationalDegree.trim();
      final index = degree.isEmpty
          ? 4
          : degree.contains('\u062f\u06cc\u067e\u0644\u0645')
          ? 0
          : degree.contains('\u06a9\u0627\u0631\u062f\u0627\u0646\u06cc')
          ? 1
          : degree.contains('\u06a9\u0627\u0631\u0634\u0646\u0627\u0633\u06cc')
          ? 2
          : 3;
      values[index]++;
    }
    return _ChartCard(
      title: '\u0633\u0637\u062d \u062a\u062d\u0635\u06cc\u0644\u0627\u062a',
      child: _PieChart(
        labels: labels,
        values: values,
        colors: const [
          Color(0xFF2563EB),
          Color(0xFF16A085),
          Color(0xFFF39C12),
          Color(0xFF8E44AD),
          Color(0xFF98A2B3),
        ],
      ),
    );
  }
}

class _HiringTrendChart extends StatelessWidget {
  const _HiringTrendChart(this.employees);
  final List<Employee> employees;
  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final values = List<int>.generate(
      5,
      (i) => employees.where((e) => e.hireDate.year == year - 4 + i).length,
    );
    final labels = List<String>.generate(5, (i) => _fa('${year - 4 + i}'));
    return _ChartCard(
      title: '\u0631\u0648\u0646\u062f \u062c\u0630\u0628 \u067e\u0646\u062c \u0633\u0627\u0644 \u0627\u062e\u06cc\u0631',
      child: _PieChart(
        labels: labels,
        values: values,
        colors: const [
          Color(0xFF0F766E),
          Color(0xFF0284C7),
          Color(0xFF7C3AED),
          Color(0xFFDB2777),
          Color(0xFFEA580C),
        ],
      ),
    );
  }
}

/*
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final index = _pieSliceAt(
                      details.localPosition,
                      constraints.biggest,
                      [active, inactive],
                    );
                    if (index == null) return;
                    final label = index == 0 ? '\u0641\u0639\u0627\u0644' : '\u063a\u06cc\u0631\u0641\u0639\u0627\u0644';
                    final count = index == 0 ? active : inactive;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('$label: ${_fa('$count')} \u0646\u0641\u0631'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                  },
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      active: active,
                      total: employees.length,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          _ChartLegend(
            items: [
              _LegendItem('\u0641\u0639\u0627\u0644', active, const Color(0xFF217A67)),
              _LegendItem('\u063a\u06cc\u0631\u0641\u0639\u0627\u0644', inactive, const Color(0xFFE36A6A)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExperienceChartOld extends StatelessWidget {
  const _ExperienceChart(this.employees);
  final List<Employee> employees;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final values = [0, 0, 0, 0];
    for (final employee in employees) {
      final years = employeeExperience(employee, now: now).years;
      values[years <= 10 ? 0 : years <= 15 ? 1 : years <= 20 ? 2 : 3]++;
    }
    return _ChartCard(
      title: '\u062a\u0648\u0632\u06cc\u0639 \u0633\u0627\u0628\u0642\u0647 \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646',
      child: _PieChart(
        labels: const ['\u06f0\u2013\u06f1\u06f0', '\u06f1\u06f1\u2013\u06f1\u06f5', '\u06f1\u06f6\u2013\u06f2\u06f0', '\u06f2\u06f1+'],
        values: values,
        colors: const [
          Color(0xFF2878B5),
          Color(0xFF2E9D67),
          Color(0xFFF0A12B),
          Color(0xFF8B5CC7),
        ],
        detailSuffix: '\u0633\u0627\u0644 \u0633\u0627\u0628\u0642\u0647',
        legendOnLeft: true,
      ),
    );
  }
}

class _EducationChart extends StatelessWidget {
  const _EducationChart(this.employees);
  final List<Employee> employees;
  @override
  Widget build(BuildContext context) {
    const labels = [
      '\u062f\u06cc\u067e\u0644\u0645',
      '\u06a9\u0627\u0631\u062f\u0627\u0646\u06cc',
      '\u06a9\u0627\u0631\u0634\u0646\u0627\u0633\u06cc',
      '\u062a\u06a9\u0645\u06cc\u0644\u06cc',
      '\u062b\u0628\u062a \u0646\u0634\u062f\u0647',
    ];
    final values = List<int>.filled(labels.length, 0);
    for (final employee in employees) {
      final degree = employee.educationalDegree.trim();
      final index = degree.isEmpty
          ? 4
          : degree.contains('\u062f\u06cc\u067e\u0644\u0645')
          ? 0
          : degree.contains('\u06a9\u0627\u0631\u062f\u0627\u0646\u06cc')
          ? 1
          : degree.contains('\u06a9\u0627\u0631\u0634\u0646\u0627\u0633\u06cc')
          ? 2
          : 3;
      values[index]++;
    }
    return _ChartCard(
      title: '\u0633\u0637\u062d \u062a\u062d\u0635\u06cc\u0644\u0627\u062a',
      child: _PieChart(
        labels: labels,
        values: values,
        colors: const [
          Color(0xFF2563EB),
          Color(0xFF16A085),
          Color(0xFFF39C12),
          Color(0xFF8E44AD),
          Color(0xFF98A2B3),
        ],
      ),
    );
  }
}

class _HiringTrendChart extends StatelessWidget {
  const _HiringTrendChart(this.employees);
  final List<Employee> employees;
  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final values = List<int>.generate(
      5,
      (i) => employees.where((e) => e.hireDate.year == year - 4 + i).length,
    );
    final labels = List<String>.generate(
      5,
      (i) => _fa('${year - 4 + i}'),
    );
    return _ChartCard(
      title: '\u0631\u0648\u0646\u062f \u062c\u0630\u0628 \u067e\u0646\u062c \u0633\u0627\u0644 \u0627\u062e\u06cc\u0631',
      child: _PieChart(
        labels: labels,
        values: values,
      colors: const [
          Color(0xFF0F766E),
          Color(0xFF0284C7),
          Color(0xFF7C3AED),
          Color(0xFFDB2777),
          Color(0xFFEA580C),
        ],
        legendOnLeft: true,
      ),
    );
  }
}

*/
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF344054),
          ),
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}

class _PieChart extends StatelessWidget {
  const _PieChart({
    required this.labels,
    required this.values,
    required this.colors,
    this.detailSuffix,
    this.legendGap = 24,
    this.legendOnLeft = false,
  });
  final List<String> labels;
  final List<int> values;
  final List<Color> colors;
  final String? detailSuffix;
  final double legendGap;
  final bool legendOnLeft;
  @override
  Widget build(BuildContext context) {
    final chart = Expanded(
      flex: 5,
      child: SizedBox(
        height: 170,
        child: LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final index = _pieSliceAt(
                details.localPosition,
                constraints.biggest,
                values,
              );
              if (index == null) return;
              final suffix = detailSuffix == null ? '' : ' $detailSuffix';
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      '${labels[index]}$suffix: ${_fa('${values[index]}')} \u0646\u0641\u0631',
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
            },
            child: CustomPaint(
              painter: _MultiSliceDonutPainter(values: values, colors: colors),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
    final legend = Expanded(
      flex: 6,
      child: _ChartLegend(
        items: List.generate(
          labels.length,
          (i) => _LegendItem(labels[i], values[i], colors[i]),
        ),
      ),
    );
    return Row(
      textDirection: TextDirection.ltr,
      children: [
        chart,
        SizedBox(width: legendGap),
        legend,
      ],
    );
  }
}

int? _pieSliceAt(Offset position, Size size, List<int> values) {
  final center = Offset(size.width / 2, size.height / 2);
  final radius = size.shortestSide / 2 - 10;
  final distance = (position - center).distance;
  const strokeWidth = 24.0;
  if (distance < radius - strokeWidth / 2 - 8 ||
      distance > radius + strokeWidth / 2 + 8) {
    return null;
  }

  final total = values.fold<int>(0, (sum, value) => sum + value);
  if (total == 0) return null;
  var angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
  angle = (angle + math.pi / 2) % (2 * math.pi);
  if (angle < 0) angle += 2 * math.pi;
  var cumulative = 0.0;
  for (var i = 0; i < values.length; i++) {
    cumulative += 2 * math.pi * values[i] / total;
    if (angle <= cumulative) return values[i] == 0 ? null : i;
  }
  return null;
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.items});
  final List<_LegendItem> items;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisAlignment: MainAxisAlignment.center,
    children: items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(item.label),
                const SizedBox(width: 10),
                Text(
                  _fa('${item.value} نفر'),
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class _LegendItem {
  const _LegendItem(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.active, required this.total});
  final int active, total;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    paint.color = const Color(0xFFF2994A);
    canvas.drawCircle(center, radius, paint);
    if (total > 0 && active > 0) {
      paint.color = const Color(0xFF217A67);
      canvas.drawArc(rect, -1.5708, 6.28318 * active / total, false, paint);
    }
    final text = TextPainter(
      text: TextSpan(
        text: _fa('$total'),
        style: const TextStyle(
          color: Color(0xFF1D2939),
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) =>
      old.active != active || old.total != total;
}

class _MultiSliceDonutPainter extends CustomPainter {
  const _MultiSliceDonutPainter({required this.values, required this.colors});
  final List<int> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = values.fold<int>(0, (sum, value) => sum + value);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;
    if (total == 0) {
      paint.color = const Color(0xFFE8EDF3);
      canvas.drawCircle(center, radius, paint);
    } else {
      var startAngle = -1.5708;
      for (var i = 0; i < values.length; i++) {
        if (values[i] == 0) continue;
        final sweepAngle = 6.28318 * values[i] / total;
        paint.color = colors[i];
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
        startAngle += sweepAngle;
      }
    }
    final text = TextPainter(
      text: TextSpan(
        text: _fa('$total'),
        style: const TextStyle(
          color: Color(0xFF1D2939),
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MultiSliceDonutPainter old) =>
      old.values != values || old.colors != colors;
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
