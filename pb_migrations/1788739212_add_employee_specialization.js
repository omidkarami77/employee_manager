/// Adds the employee's specialization.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  if (!employees.fields.getByName('specialization')) {
    employees.fields.add(new TextField({name: 'specialization', max: 250}));
    app.save(employees);
  }
});
