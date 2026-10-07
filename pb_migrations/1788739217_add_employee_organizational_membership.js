/// Adds optional organizational membership without changing existing records.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  if (!employees.fields.getByName('organizational_membership')) {
    employees.fields.add(new TextField({name: 'organizational_membership', required: false, max: 250}));
    app.save(employees);
  }
});