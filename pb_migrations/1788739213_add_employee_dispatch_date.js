/// Adds the military-service dispatch date for conscripts.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  if (!employees.fields.getByName('dispatch_date')) {
    employees.fields.add(new DateField({name: 'dispatch_date'}));
    app.save(employees);
  }
});
