/// Configure application accounts; PocketBase superusers remain separate.
migrate((app) => {
  let auth;
  try {
    auth = app.findCollectionByNameOrId('Auth');
  } catch (_) {
    auth = new Collection({name: 'Auth', type: 'auth'});
  }
  if (auth.type !== 'auth') throw new Error('Auth must be an auth collection');
  if (!auth.fields.getByName('name')) {
    auth.fields.add(new TextField({name: 'name', max: 255}));
  }
  let role = auth.fields.getByName('role');
  if (role && role.type !== 'select') throw new Error('Existing role must be a select field');
  if (!role) role = new SelectField({name: 'role'});
  role.values = ['Admin', 'User'];
  role.maxSelect = 1;
  role.required = false;
  auth.fields.add(role);
  auth.passwordAuth.enabled = true;
  auth.passwordAuth.identityFields = ['email'];
  // Account provisioning and role changes belong to PocketBase's superuser UI.
  // No public sign-up or self-service role escalation.
  auth.createRule = null;
  auth.updateRule = null;
  auth.deleteRule = null;
  auth.manageRule = null;
  auth.listRule = 'id = @request.auth.id';
  auth.viewRule = 'id = @request.auth.id';
  auth.authRule = 'role = "Admin" || role = "User"';
  app.save(auth);
  // Existing accounts without a role receive the least privileged role.
  app.db().newQuery("UPDATE Auth SET role = 'User' WHERE role = '' OR role IS NULL").execute();
  role = auth.fields.getByName('role');
  role.required = true;
  auth.fields.add(role);
  app.save(auth);

  const employees = app.findCollectionByNameOrId('employees');
  const member = '@request.auth.id != "" && @request.auth.collectionName = "Auth"';
  const reader = member + ' && (@request.auth.role = "Admin" || @request.auth.role = "User")';
  const admin = member + ' && @request.auth.role = "Admin"';
  employees.listRule = reader;
  employees.viewRule = reader;
  employees.createRule = admin;
  employees.updateRule = admin;
  employees.deleteRule = admin;
  app.save(employees);
});
