part of 'main.dart';

class _ReportsPage extends StatefulWidget {
  const _ReportsPage({required this.controller});
  final EmployeesController controller;

  @override
  State<_ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<_ReportsPage> {
  final _search = TextEditingController();
  final _horizontalScroll = ScrollController();
  int _minimumYears = 0;
  int _status = 0;
  bool _exporting = false;

  @override
  void dispose() {
    _search.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  Future<void> _export(List<Employee> employees, DateTime now) async {
    if (_exporting) return;
    // Capture precisely the visible results before opening the native dialog.
    final rows = employees.indexed.map((entry) {
      final (index, e) = entry;
      return [
        _fa('${index + 1}'),
        e.firstName,
        e.lastName,
        e.personnelCode,
        e.nationalCode,
        e.mobile,
        e.jobTitle,
        e.department,
        _jalali(e.hireDate),
        e.endDate == null ? '' : _jalali(e.endDate!),
        _fa(employeeExperience(e, now: now).toString()),
        e.isActive ? 'فعال' : 'غیرفعال',
      ];
    }).toList();
    setState(() => _exporting = true);
    try {
      final saved = await saveEmployeeReport(rows, now);
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فایل Excel با موفقیت ذخیره شد')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در ایجاد فایل Excel')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final employees = filterEmployeeReport(
      widget.controller.employees,
      minimumYears: _minimumYears,
      active: _status == 0 ? null : _status == 1,
      query: _search.text,
      now: now,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: AppText.reports,
          description: 'گزارش کارکنان بر اساس سابقه کار',
          action: IconButton(
            tooltip: 'به‌روزرسانی',
            onPressed: _exporting || widget.controller.isMutating
                ? null
                : widget.controller.loadEmployees,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        const SizedBox(height: 28),
        _Panel(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int>(
                  key: const ValueKey('report-experience'),
                  isExpanded: true,
                  initialValue: _minimumYears,
                  decoration: const InputDecoration(
                    labelText: 'حداقل سابقه',
                    border: OutlineInputBorder(),
                  ),
                  items: [0, 5, 10, 15, 20]
                      .map(
                        (years) => DropdownMenuItem(
                          value: years,
                          child: Text(
                            years == 0 ? 'همه' : '${_fa('$years')} سال به بالا',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _minimumYears = value!),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<int>(
                  key: const ValueKey('report-status'),
                  isExpanded: true,
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'وضعیت',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('همه')),
                    DropdownMenuItem(value: 1, child: Text('فعال')),
                    DropdownMenuItem(value: 2, child: Text('غیرفعال')),
                  ],
                  onChanged: (value) => setState(() => _status = value!),
                ),
              ),
              SizedBox(
                width: 360,
                child: TextField(
                  key: const ValueKey('report-search'),
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'جستجو',
                    hintText: 'نام، نام خانوادگی، کد پرسنلی یا کد ملی',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 24,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${_fa('${employees.length}')} کارمند یافت شد',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: employees.isEmpty || _exporting
                        ? null
                        : () => _export(employees, now),
                    icon: _exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download_outlined),
                    label: Text(
                      _exporting ? 'در حال ایجاد فایل…' : 'خروجی Excel',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (employees.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    widget.controller.employees.isEmpty
                        ? 'هنوز کارمندی ثبت نشده است.'
                        : 'کارمندی با این فیلترها یافت نشد.',
                  ),
                )
              else
                Scrollbar(
                  controller: _horizontalScroll,
                  thumbVisibility: true,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  child: SingleChildScrollView(
                    controller: _horizontalScroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DataTable(
                      headingRowColor: const WidgetStatePropertyAll(
                        Color(0xFFF6F8FC),
                      ),
                      columns: const [
                        'ردیف',
                        'نام و نام خانوادگی',
                        'کد پرسنلی',
                        'کد ملی',
                        'شماره موبایل',
                        'واحد سازمانی',
                        'سمت',
                        'تاریخ استخدام',
                        'تاریخ پایان همکاری',
                        'سابقه',
                        'وضعیت',
                      ].map((label) => DataColumn(label: Text(label))).toList(),
                      rows: employees.indexed.map((entry) {
                        final (index, e) = entry;
                        return DataRow(
                          cells: [
                            DataCell(Text(_fa('${index + 1}'))),
                            DataCell(Text(e.fullName)),
                            DataCell(Text(e.personnelCode)),
                            DataCell(Text(e.nationalCode)),
                            DataCell(Text(e.mobile)),
                            DataCell(Text(e.department)),
                            DataCell(Text(e.jobTitle)),
                            DataCell(Text(_jalali(e.hireDate))),
                            DataCell(
                              Text(
                                e.endDate == null ? '—' : _jalali(e.endDate!),
                              ),
                            ),
                            DataCell(
                              Text(
                                _fa(employeeExperience(e, now: now).toString()),
                              ),
                            ),
                            DataCell(_StatusBadge(active: e.isActive)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
