class Pageable<T> {
  Pageable({
    required this.page,
    required this.limit,
    required this.data,
  }) {
    numResults = data.length;
    hasNext = numResults >= limit;
  }
  
  final int page;
  final int limit;
  final List<T> data;
  bool hasNext = true;
  int numResults = 0;

  bool get isEmpty {
    return numResults < 1;
  }

  bool get isNotEmpty {
    return !isEmpty;
  }
}
