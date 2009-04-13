function(doc) {
  if (doc.tags) {
    // assumes doc.tags is an array of strings
    var tags = doc.tags;
    tags.sort();
    for (var i=0; i < tags.length; i++) {
      emit(tags[i], 1);
      for (var j = i+1; j < tags.length; j++) {
        emit(tags.slice(i, j+1), 1);
      }
    }
  }
}