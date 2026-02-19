/// Pagination parameters used across game list queries.
class GamePagination {
  final int page;
  final int pageSize;

  const GamePagination({
    this.page = 1,
    this.pageSize = 20,
  });

  static const first = GamePagination(page: 1, pageSize: 20);

  GamePagination nextPage() => GamePagination(page: page + 1, pageSize: pageSize);

  GamePagination withPageSize(int size) =>
      GamePagination(page: page, pageSize: size);

  int get offset => (page - 1) * pageSize;

  Map<String, dynamic> toQueryParams() => {
        'page': page,
        'limit': pageSize,
      };

  @override
  String toString() => 'GamePagination(page: $page, size: $pageSize)';
}
