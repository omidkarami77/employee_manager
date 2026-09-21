/// Adds optional battlefront service details to employee records.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  if (!employees.fields.getByName('has_battlefront_service')) {
    employees.fields.add(
      new BoolField({name: 'has_battlefront_service'}),
    );
  }
  if (!employees.fields.getByName('battlefront_start_date')) {
    employees.fields.add(new DateField({name: 'battlefront_start_date'}));
  }
  if (!employees.fields.getByName('battlefront_end_date')) {
    employees.fields.add(new DateField({name: 'battlefront_end_date'}));
  }
  if (!employees.fields.getByName('battle_operations')) {
    employees.fields.add(new TextField({name: 'battle_operations', max: 2000}));
  }
  app.save(employees);
});
