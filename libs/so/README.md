# CLuaSO

在Lua中，可以使用loadlib的方式直接的加载C语言写的库，如同加载.lua文件一样。C写的模块可以做一些对效率要求相对比较高的模块，或是一些底层操作。下面举例

说明：

第一步：创建C模块文件。

foo.h头文件


```c
#ifndef foo_h__

#define foot_h__

extern void foo(lua_State* L);

#endif
```

foo.c实现文件

```c
#include <stdio.h>
#include "lauxlib.h"

void foo(lua_State* L)
{
    puts("Hello, I'm a shared library");
}
```
第二步：创建.o文件。

```c
gcc -c -Wall -Werror -fpic foo.c -I/usr/include/lua5.1
```
注意一下的是.h文件中包含了"lauxlib.h"文件，所以要在编译的时候加上-I选项，后面追加.h文件的路径。

第三步：创建.so文件。

```c
gcc -shared -o libfoo.so foo.o
```
如此操作后，”.so“文件就完成了生成，在使用libfoo.so动态库的时候，有以下几种方式让Lua找到库文件。

a). 设置LD_LIBRARY_PATH环境变量。

```c
export LD_LIBRARY_PATH=/home/username/foo:$LD_LIBRARY_PATH
```
b). 复制库文件到系统目录。

```c
sudo cp /home/coding/workspace/libfoo.so /usr/lib
ldconfig 
```
用ldconfig更新一下缓冲，然后看是否生效。

```c
ldconfig -p | grep foo
```
(也可以看一下.so文件是否关联到其他的库。ldd XXX{XXX为非lua文件，可以含有main函数的C程序。}

c). 把.so文件放到当前目录。

第四步：在lua中加载.so库。

test.lua文件。

```c
f = package.loadlib("libfoo.so", "foo")
f()
```
以上，就是如何创建.so共享库，然后在Lua加载调用的过程，使用Lua版本是Lua5.15, 开发环境是在coding.net的WEB IDE的terminal终端环境。


之前so库，是没有传递参数的，下面我们用一个简单传参的例子来说明问题，然后以Makefile的形式编译共享程序。


首先要定义就是.h文件，定义最常见的接口add, sub。

```c
#ifndef __tangguo_h__
#define __tangguo_h__
#include "lua.h"
#include "lualib.h" 
#include "lauxlib.h"

extern int add(lua_State* L);
extern int sub(lua_State* L);
static luaL_Reg libtangguo[] = {
    {"add", add},
    {"sub", sub},
    {NULL, NULL}
};  

#endif 
```
luaL_Reg 这个结构体相对很重要，下面是引用这个结构全的原型：

```c
typedef struct luaL_Reg {
  const char *name;
  lua_CFunction func;
} luaL_Reg;
```
主要的元素:一个函数名字符串，另外一个是lua_CFunction的函数指针。
在定义时地函数最后要用两个NULL,作业结构体数据的结尾。

Type for arrays of functions to be registered byluaL_register.name is the function name and func is a pointer to the function.Any array of luaL_Reg must end with an sentinel entry in which both name and func are NULL.

lua_CFunction函数指针原型定义，如下：

```c
typedef int (*lua_CFunction) (lua_State *L);
```
下面是函数体的实体部分，所有函数的接口定义都是遵循lua_CFunction指针函数的原型定义，形参都是lua_State* L。



```c
#include "tangguo.h"

int sub(lua_State* L) {
    double op1 = luaL_checknumber(L, 1);
    double op2 = luaL_checknumber(L, 2);
    lua_pushnumber(L, op1 - op2);
    return 1;
}

int add(lua_State* L) {
    double op1 = luaL_checknumber(L, 1);
    double op2 = luaL_checknumber(L, 2);
    lua_pushnumber(L, op1 + op2);
    return 1;
}

int luaopen_libtangguo(lua_State* L)
{
    luaL_openlibs(L);
    const char *libName = "libtangguo";
    luaL_register(L, libName, libtangguo);
    return 0;
}

```
涉及到lua调用c语言，面对的一个课题是，如何在c函数中取得lua传递的对数，如果将计算结果，返回给lua程序。在这种最常见的add、sub函数例子都数字运算，我们用luaL_checknumber这个函数，原型如下：
```c
lua_Number luaL_checknumber (lua_State *L, int narg);
```
Checks whether the function argument narg is a numberand returns this number.
检查函数的参数是不是数字，返回这个数字。第一个参数是入参的状态机，第二个参数是lua调用c函数时，形参列表里第几个形参。

还有一个比较重要的函数，luaopen_libtangguo，这函数是用来注册这此函数。

luaL_register


lua_pushnumber


为了更好的适应编译环境，生成一个简单的Makefile， 需要注意的是LUALIB的定义要与你自己的环境相符。主要的参数是就是-I来指定.h的位置，-L用来定义用了那些库。

默认的编辑选项是要提定平台。


make linux
Makefile文件如下。

```c
LUALIB=-I/usr/include/lua5.1 -L/usr/local/lib -ldl -lm

.PHONY: all win linux

all:
        @echo Please do \'make PLATFROM\' where PLATFORM is one of these;
        @echo win linux

win:

linux: libtangguo.so

libtangguo.so : tangguo.c
        #gcc --shared -Wall -fPIC -O2 $^ -o $@ $(LUALIB)
        gcc --shared -fPIC -O2 $^ -o $@ $(LUALIB)

clean:
        rm -f libtangguo.so
```
编译后会在当前目录生成.so文件，我们要以把.so文件复制到/usr/lib下

```c
sudo ldconfig
```
我们来测试一下库是否工作，用package.loadlib直接了复对应的函数指钍。

```lua
local aadd = package.loadlib("libtangguo.so", "add")
local asub = package.loadlib("libtangguo.so", "sub")
local ret = aadd(1,5)
print(ret)

local ret = asub(6,3)
print(ret)
```
输出的结是：


3
6

后记： 
涉及到lua调用c语言，面对的一个课题是，如何在c函数中取得lua传递的对数，如果将计算结果，返回给lua程序。



[原文](http://lua.ren/topic/109/lua%E4%B8%AD%E8%84%9A%E6%9C%AC%E4%B8%AD%E5%8A%A0%E8%BD%BDc%E8%AF%AD%E8%A8%80%E7%9A%84-so%E5%85%B1%E4%BA%AB%E5%BA%93)
