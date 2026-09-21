/// Adds the employee's last service unit.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  if (!employees.fields.getByName('last_service_unit')) {
    employees.fields.add(new TextField({name: 'last_service_unit', max: 250}));
    app.save(employees);
  }
});
