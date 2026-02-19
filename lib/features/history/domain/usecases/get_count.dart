import 'package:play_sync_new/features/history/domain/repositories/history_repository.dart';

class GetCount {
  final HistoryRepository repository;

  GetCount(this.repository);

  Future<int> call() async {
    return await repository.getCount();
  }
}
