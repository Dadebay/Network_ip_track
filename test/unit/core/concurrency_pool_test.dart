import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/concurrency/concurrency_pool.dart';

void main() {
  test('never runs more than maxConcurrent tasks at once', () async {
    final pool = ConcurrencyPool(3);
    var active = 0;
    var maxObserved = 0;

    final futures = List.generate(20, (i) {
      return pool.run(() async {
        active++;
        maxObserved = active > maxObserved ? active : maxObserved;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        active--;
        return i;
      });
    });

    final results = await Future.wait(futures);

    expect(maxObserved, lessThanOrEqualTo(3));
    expect(results, List.generate(20, (i) => i));
  });

  test(
    'runs every queued task exactly once, in submission order per slot',
    () async {
      final pool = ConcurrencyPool(1);
      final order = <int>[];

      await Future.wait(
        List.generate(
          5,
          (i) => pool.run(() async {
            order.add(i);
          }),
        ),
      );

      expect(order, [0, 1, 2, 3, 4]);
    },
  );
}
