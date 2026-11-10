/// Adds an optional position, separate from the employee's rank.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  if (!employees.fields.getByName('position')) {
    employees.fields.add(new TextField({name: 'position', required: false, max: 250}));
    app.save(employees);
  }
});
