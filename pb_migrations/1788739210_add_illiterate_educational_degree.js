/// Adds the illiterate option for existing educational-degree fields.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  const field = employees.fields.getByName('educational_degree');
  if (field && !field.values.includes('بی سواد')) {
    field.values.push('بی سواد');
    app.save(employees);
  }
});
