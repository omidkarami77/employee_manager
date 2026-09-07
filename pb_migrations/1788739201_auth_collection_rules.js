migrate((app) => {
  const auth = app.findCollectionByNameOrId('Auth');
  const employees = app.findCollectionByNameOrId('employees');
  const member = '@request.auth.id != "" && @request.auth.collectionName = "Auth"';
  const reader = member + ' && (@request.auth.role = "Admin" || @request.auth.role = "User")';
  const admin = member + ' && @request.auth.role = "Admin"';

  if (auth.type !== 'auth') throw new Error('Auth must be an auth collection');
  const role = auth.fields.getByName('role');
  if (!role || role.type !== 'select') throw new Error('Auth role must be a select field');
  role.values = ['Admin', 'User'];
  auth.fields.add(role);
  auth.authRule = 'role = "Admin" || role = "User"';
  app.save(auth);
  employees.listRule = reader;
  employees.viewRule = reader;
  employees.createRule = admin;
  employees.updateRule = admin;
  employees.deleteRule = admin;
  app.save(employees);
});