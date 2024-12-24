import 'dart:async';

import 'package:dart_net_core_api/cron/cron_job.dart';

class EveryMinutePrintJob extends CronJob {
  EveryMinutePrintJob() : super('*/1 * * * *');

  @override
  FutureOr doJob() async {
    print('`EveryMinutePrintJob` has been executed for: $jobStartCounter times');
    await Future.delayed(const Duration(seconds: 5));
  }

  @override
  void dispose() {
    print('$this has been disposed');
  }
  
  @override
  void onReady() {
    print('$EveryMinutePrintJob job is ready');
  }
}
