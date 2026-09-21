/// Adds the conscript option for existing collaboration-type fields.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  const field = employees.fields.getByName('collaboration_type');
  if (field && !field.values.includes('سرباز وظیفه')) {
    field.values.push('سرباز وظیفه');
    app.save(employees);
  }
});
