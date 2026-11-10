// Rename only the legacy collaboration type; preserve all other employee data.
migrate((app) => {
  app.db().newQuery(
    'UPDATE employees SET collaboration_type = {:replacement} WHERE collaboration_type = {:legacy}'
  ).bind({
    replacement: 'هیئت مرکزی و گروه های استانی',
    legacy: 'معارف جنگ و روساء گروه های استانی',
  }).execute();
});
