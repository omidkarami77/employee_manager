/// Adds the province where the employee's organizational unit is located.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  if (!employees.fields.getByName('province')) {
    employees.fields.add(new TextField({name: 'province', max: 100}));
    app.save(employees);
  }
});
