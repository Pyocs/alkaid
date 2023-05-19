
///表示模块处理状态：处理中、处理完成、不能处理
enum AlkaidStatus {
  // processing,
  ///处理完成,提前结束
  finish,
  ///处理失败，由下一个模块节点
  fail,
  ///终止
  stop,
  ///等待其他模块处理，返回一个处理结果
  wait,

}