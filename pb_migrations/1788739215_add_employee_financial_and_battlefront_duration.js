/// Replaces battlefront date entry with a duration in months and stores
/// employee wisdom-card and Sepah bank account numbers.
migrate((app) => {
  const employees = app.findCollectionByNameOrId('employees');

  if (!employees.fields.getByName('battlefront_duration_months')) {
    employees.fields.add(
      new NumberField({name: 'battlefront_duration_months', min: 0}),
    );
  }
  if (!employees.fields.getByName('wisdom_card_number')) {
    employees.fields.add(
      new TextField({name: 'wisdom_card_number', max: 100}),
    );
  }
  if (!employees.fields.getByName('sepah_bank_account_number')) {
    employees.fields.add(
      new TextField({name: 'sepah_bank_account_number', max: 100}),
    );
  }

  app.save(employees);
});
