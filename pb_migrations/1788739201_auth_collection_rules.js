migrate((app) => {
  const auth = app.findCollectionByNameOrId('auth');
  const employees = app.findCollectionByNameOrId('employees');
  const member = '@request.auth.id != "" && @request.auth.collectionName = "auth"';
  const reader = member + ' && (@request.auth.role = "admin" || @request.auth.role = "user")';
  const admin = member + ' && @request.auth.role = "admin"';

  if (auth.type !== 'auth') throw new Error('Auth must be an auth collection');
  const role = auth.fields.getByName('role');
  if (!role || role.type !== 'select') throw new Error('Auth role must be a select field');
  role.values = ['admin', 'user'];
  auth.fields.add(role);
  auth.authRule = 'role = "admin" || role = "user"';
  app.save(auth);
  employees.listRule = reader;
  employees.viewRule = reader;
  employees.createRule = admin;
  employees.updateRule = admin;
  employees.deleteRule = admin;
  app.save(employees);
});