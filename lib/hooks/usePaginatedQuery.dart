import 'package:fl_query/fl_query.dart';
import 'package:fl_query/fl_query_hooks.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hookified_infinite_scroll_pagination/hookified_infinite_scroll_pagination.dart';

class PagedQuery<T extends Object, Outside, P, ItemType> {
  PagingController<P, ItemType> pagingController;
  Query<T, Outside> query;
  PagedQuery(this.pagingController, this.query);
}

PagedQuery<T, Outside, P, ItemType>
    usePaginatedQuery<T extends Object, Outside, P, ItemType>(
  QueryJob<T, Outside> Function(P pageKey) createJob, {
  required Outside externalData,
  required P firstPageKey,
  void Function(
    T,
    PagingController<P, ItemType> pagingController,
    P pageKey,
  )?
      onData,
  void Function(Object)? onError,
}) {
  final currentPageKey = useState(firstPageKey);
  final pagingController =
      usePagingController<P, ItemType>(firstPageKey: firstPageKey);

  final query = useQuery<T, Outside>(
    job: createJob(currentPageKey.value),
    externalData: externalData,
  );

  useEffect(() {
    listener(P pageKey) {
      if (currentPageKey.value != pageKey) {
        currentPageKey.value = pageKey;
      }
    }

    pagingController.addPageRequestListener(listener);
    return () => pagingController.removePageRequestListener(listener);
  }, [pagingController, currentPageKey.value]);

  useEffect(() {
    if (query.hasData) {
      onData?.call(query.data!, pagingController, currentPageKey.value);
    }
  }, [query.data]);

  useEffect(() {
    if (query.hasError) {
      pagingController.error = query.error;
      onError?.call(query.error);
    }
  }, [query.error]);

  return PagedQuery(pagingController, query);
}
