/// Adds the no-sacrifice-status option for existing fields.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  const field = employees.fields.getByName('sacrifice_status');
  if (field && !field.values.includes('ندارد')) {
    field.values.push('ندارد');
    app.save(employees);
  }
});
