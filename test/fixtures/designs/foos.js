{
  views: {
    by_bar: {
      map: function(doc) {
        emit(doc.bar, null)
      },
      reduce: function(keys, values, rereduce) {
        return(sum(values))
      }
    },
  }
}