migrate((app) => {
  const auth = app.findCollectionByNameOrId('Auth');
  const employees = app.findCollectionByNameOrId('employees');

  if (auth.type !== 'auth') throw new Error('Auth must be an auth collection');
  // Keep the stored values and API rules consistent with the app's role names.
  app.db().newQuery("UPDATE Auth SET role = 'admin' WHERE role IN ('Admin', 'ََََAdmin')").execute();
  app.db().newQuery("UPDATE Auth SET role = 'user' WHERE role = 'User'").execute();
  auth.fields.addAt(7, new SelectField({
    name: 'role',
    values: ['admin', 'user'],
    maxSelect: 1,
  }));
  auth.authRule = 'role = "admin" || role = "user"';
  app.save(auth);

  const member = '@request.auth.id != "" && @request.auth.collectionName = "Auth"';
  const reader = member + ' && (@request.auth.role = "admin" || @request.auth.role = "user")';
  const admin = member + ' && @request.auth.role = "admin"';
  employees.listRule = reader;
  employees.viewRule = reader;
  employees.createRule = admin;
  employees.updateRule = admin;
  employees.deleteRule = admin;
  app.save(employees);
});