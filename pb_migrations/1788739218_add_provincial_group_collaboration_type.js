/// Adds the provincial group leadership collaboration type to existing fields.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  const field = employees.fields.getByName('collaboration_type');
  const value = 'معارف جنگ و روساء گروه های استانی';
  if (field && !field.values.includes(value)) {
    field.values.push(value);
    app.save(employees);
  }
});