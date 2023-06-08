enum IsolateStatus {
  //隔离正在运行
  running,
  //隔离任务所有完成已休眠
  stop,
  //隔离被Kill
  finish,
  //未初始化SendPort
  unInit,
  //保持存活状态
  survive
}