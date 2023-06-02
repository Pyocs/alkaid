enum CacheControl {
  ///可以被客户端和中间代理服务器缓存
  public,
  ///只能被客户端缓存
  private,
  ///客户端使用缓存前必须向服务器验证自资源是否发生变化
  noCache,
  ///禁止缓存
  noStore
}