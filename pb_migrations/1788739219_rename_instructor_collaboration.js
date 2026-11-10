// Keep select options and stored employee values consistent.
migrate((app) => {
  const renames = {
    'معارف جنگ و روساء گروه های استانی': 'هیئت مرکزی و گروه های استانی',
    'اساتید': 'استاد',
    'اساتید پیشکسوت': 'استاد پیشکسوت',
  };
  const collection = app.findCollectionByNameOrId('employees');
  const field = collection.fields.getByName('collaboration_type');
  if (field && field.type === 'select') {
    const values = Array.from(field.values, (value) => renames[value] || value);
    Object.values(renames).forEach((value) => {
      if (!values.includes(value)) values.push(value);
    });
    field.values = [...new Set(values)];
    app.save(collection);
  }
  Object.entries(renames).forEach(([legacy, replacement]) => {
    app.db().newQuery(
      'UPDATE employees SET collaboration_type = {:replacement} WHERE collaboration_type = {:legacy}'
    ).bind({legacy, replacement}).execute();
  });
});
