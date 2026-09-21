/// Adds the employee's collaboration type.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  if (!employees.fields.getByName('collaboration_type')) {
    employees.fields.add(
      new SelectField({
        name: 'collaboration_type',
        values: [
          'نظامی شاغل',
          'سرباز وظیفه',
          'پیشکوست شاغل ( هیئت مرکزی )',
          'پیشکوست شاغل ( گروه های استانی )',
          'اساتید',
        ],
        maxSelect: 1,
      }),
    );
    app.save(employees);
  }
});
