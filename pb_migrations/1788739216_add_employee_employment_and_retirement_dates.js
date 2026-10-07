migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  for (const name of ['employment_date', 'retirement_date']) {
    if (!employees.fields.getByName(name)) {
      employees.fields.add(new DateField({name: name, required: false}));
    }
  }
  app.save(employees);
});