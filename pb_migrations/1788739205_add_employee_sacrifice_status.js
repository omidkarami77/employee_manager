/// Adds the employee's sacrifice-status category.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  if (!employees.fields.getByName('sacrifice_status')) {
    employees.fields.add(
      new SelectField({
        name: 'sacrifice_status',
        values: ['ندارد', 'آزاده', 'جانباز', 'ایثارگر', 'جانباز آزاده'],
        maxSelect: 1,
      }),
    );
    app.save(employees);
  }
});
