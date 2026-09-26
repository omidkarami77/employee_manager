/// Adds the accommodation status used only for conscripts.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');
  if (!employees.fields.getByName('accommodation_status')) {
    employees.fields.add(
      new SelectField({
        name: 'accommodation_status',
        values: ['بومی', 'غیر بومی'],
        maxSelect: 1,
      }),
    );
    app.save(employees);
  }
});
