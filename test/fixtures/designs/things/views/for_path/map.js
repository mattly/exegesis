function(doc) {
  if (!doc.date) { return; }
  if (doc.path) {
    emit([doc.path, 'path', doc.date], null);
  }
  if (doc.tags) {
    for (var tag in doc.tags) {
      emit([doc.tags[tag], 'tag', doc.date], null);
    }
  }
}