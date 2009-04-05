function(doc) {
  if (doc.tags) {
    // assumes doc.tags is an array of strings
    for (var tag in doc.tags) {
      emit(doc.tags[tag], 1);
    }
  }
}