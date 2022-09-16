import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hookified_infinite_scroll_pagination/hookified_infinite_scroll_pagination.dart';

class PagedQuery<T extends Object, Outside, PageParam extends Object,
    ItemType> {
  PagingController<PageParam, ItemType> pagingController;
  InfiniteQuery<T, Outside, PageParam> query;
  PagedQuery(this.pagingController, this.query);
}

PagedQuery<T, Outside, PageParam, ItemType> usePaginatedInfiniteQuery<
    T extends Object, Outside, PageParam extends Object, ItemType>(
  InfiniteQueryJob<T, Outside, PageParam> job, {
  required Outside externalData,
  required PageParam firstPageKey,
  void Function(
    T,
    PagingController<PageParam, ItemType> pagingController,
    PageParam pageKey,
  )?
      onData,
  void Function(Object)? onError,
}) {
  final pagingController = usePagingController<PageParam, ItemType>(
    firstPageKey: firstPageKey,
  );
  final mounted = useIsMounted();

  final query = useInfiniteQuery<T, Outside, PageParam>(
    job: job,
    externalData: externalData,
    onData: (page, pageParam, pages) {
      if (!mounted()) return;
      onData?.call(page, pagingController, pageParam);
    },
    onError: (error, pageParam, pages) {
      if (!mounted()) return;
      pagingController.error = error;
      onError?.call(error);
    },
  );

  useEffect(() {
    listener(PageParam pageKey) async {
      final page = await query.fetchNextPage((_, __) => pageKey);
      if (!mounted() || page == null) return;
      onData?.call(page, pagingController, pageKey);
    }

    pagingController.addPageRequestListener(listener);
    return () => pagingController.removePageRequestListener(listener);
  }, [pagingController, query.fetchNextPage]);

  return PagedQuery(pagingController, query);
}
