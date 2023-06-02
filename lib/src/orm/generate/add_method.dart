import 'dart:io';

///为Mapping添加抽象方法啊
///[method] 需要添加的抽象方法
///[filePath] 修改的文件路径
void addMethod(String method,String filePath) async {
  File file = File(filePath);
  var rs = await  file.open(mode: FileMode.append);
  //利用栈找到插入的位置
  List<int> stack = [];

  int index = 0;

  for(int i = 0 ; i < file.lengthSync() ; i++) {
    rs.setPositionSync(i);
    int value = rs.readByteSync();
    //找到 {
    if(value == 123) {
      stack.add(value);
    }
    //找到 }
    else if(value == 125) {
      if(stack.last == 123) {
        //出栈
        stack.removeLast();
        if(stack.isEmpty) {
          //找到class的末尾
          index = i;
          break;
        }
      } else {
        stack.add(value);
      }
    }
  }

  assert(index != 0,"位置错误!");
  rs.setPositionSync(index - 1);
  rs.writeStringSync('\n$method\n}');
  rs.close();
}