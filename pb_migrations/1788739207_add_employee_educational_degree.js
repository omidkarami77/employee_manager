/// Adds the employee's educational degree.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  if (!employees.fields.getByName('educational_degree')) {
    employees.fields.add(
      new SelectField({
        name: 'educational_degree',
        values: ['بی سواد', 'سیکل', 'دیپلم', 'فوق دیپلم', 'لیسانس', 'فوق لیسانس', 'دکترا'],
        maxSelect: 1,
      }),
    );
    app.save(employees);
  }
});
