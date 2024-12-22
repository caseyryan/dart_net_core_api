import 'dart:async';

import 'package:cron/cron.dart';
import 'package:dart_net_core_api/exports.dart';

import 'job_locker.dart';

/// Extend this class and add your instance to the list of jobs
/// when instantiating the server
abstract class CronJob extends Configurable {
  final _cron = Cron();

  int get jobStartCounter => _jobLocker.counter;
  late final Schedule _schedule;
  late final JobLocker _jobLocker;

  /// [expression] is a standard cron expression
  /// https://en.wikipedia.org/wiki/Cron
  CronJob(String expression) {
    try {
      _schedule = Schedule.parse(expression);
      Logger.root.log(Level.INFO, '$runtimeType has been initialized');
      // _startCronJob(schedule);
    } on ScheduleParseException catch (e, s) {
      Logger.root.log(Level.SEVERE, e.message, s);
      _dispose();
    } catch (e, s) {
      Logger.root.log(Level.SEVERE, e.toString(), s);
      _dispose();
    }
  }

  void onReady();

  @override
  void onConfigurableReady() {
    final tempDir = getConfig<Config>()!.tempFilesRoot!;
    _jobLocker = JobLocker(
      tempDir,
      runtimeType.toString(),
    );
    _startCronJob(_schedule);
  }

  Future _startCronJob(Schedule schedule) async {
    /// this is a small hack to allow
    /// a Timer to be launched in isolate
    await Future.delayed(const Duration(milliseconds: 100));
    // print('ON START $hashCode CONFIG IS ${getConfig<Config>()}');
    _cron.schedule(
      schedule,
      () async {
        if (_jobLocker.obtainLock()) {
          await doJob();
          _jobLocker.releaseLock();
        }
          
      },
    );
    onReady();
  }

  FutureOr doJob();

  Future _dispose() async {
    await _cron.close();
    dispose();
  }

  void dispose();
}
