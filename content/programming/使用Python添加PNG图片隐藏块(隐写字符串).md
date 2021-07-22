---
title: "使用Python添加PNG图片隐藏块(隐写字符串)"
date: 2021-07-22T22:26:35+08:00
draft: false
tags: ["编程", "Python", "Steganography", "隐写"]
categories: ["编程", "Python"]
katex: false
mermaid: false
author: "Icheon Tao"
toc: false
slug: "add_png_chunks_with_python"
---
最近想批量给PNG图片添加一些隐藏标识，所以google一番，这里记录一下。

首先是了解PNG文件格式结构[<sup>1</sup>](#refer-anchor)，PNG数据块Chunk主要是有`IHDR`、`IDAT`和`IEND`组成(缺一不可)

本篇的主角`tEXt`和`zTXt`数据块：
	- `tEXt`: 文本信息数据块 [可选] 所在PNG文件结构的位置无限制
	- `zTXt`: 压缩文本数据块 [可选] 所在PNG文件结构的位置无限制

由于是只处理PNG图片，这里用到是`PyPNG`模块，该项目Github可访问[drj11/pypng](https://github.com/drj11/pypng)

这里使用下面这张图片来测试
![ivan-rudoy-Ot90TwQGAeE-unsplash](imags/ivan-rudoy-Ot90TwQGAeE-unsplash.png)

使用的代码如下：
```python

import zlib
import random
import binascii
from typing import List

import png


def add_text(src_img_path: str, dest_img_path: str, contents: List[str], is_compress: bool=True) -> None:
    reader = png.Reader(src_img_path)
    # 返回图片chunks迭代器并转化为列表
    chunks = list(reader.chunks())
    for content in contents:
        # 将其转化为bytes
        content = content.encode(encoding='utf-8')
        if is_compress:
            add_chunk = tuple([b'zTXt', zlib.compress(content)])
        else:
            add_chunk = tuple([b'tEXt', content])

        # PNG格式中chunk的第一个(IHDR)和最后一个(IEND)固定，所以我们可以随机生成一个索引
        chunks.insert(random.randint(1, len(chunks)-1), add_chunk)

    with open(dest_img_path, 'wb') as dest_file:
        png.write_chunks(dest_file, chunks)
 

def cat_text(src_img: str) -> None:
    reader = png.Reader(src_img)
    chunks = reader.chunks()
    for i, j in chunks:
        if i == b'zTXt':
            print(f"{i.decode(encoding='utf-8')}: {zlib.decompress(j).decode(encoding='utf-8')}")
        if i == b'tEXt':
            print(f"{i.decode(encoding='utf-8')}: {j.decode(encoding='utf-8', errors='ignore')}")


def main() -> None:
    src_img_path = "./test1.png"
    dest_img_path = "./test1_res.png"
    # 需要隐写的内容
    content = ["This is a test1 content", "This is a test2 content"]
    add_text(src_img_path, dest_img_path, content)
    # 如需要查看PNG图片中是否含有`tEXt`和`zTXt`文本相关的数据块
    # cat_text(dest_img_path)

 
if __name__ == '__main__':
    main()

```

#### 简单展示下`tEXt`和`zTXt`数据块在PNG文件里的区别
- tEXt
	1. 使用`tEXt`，hexdump隐写后的PNG图片`hexdump -C test1_res.png > /var/tmp/11`
    2. 查询关键字`tEXt`，使用命令`grep -C5 "tEXt" /var/tmp/11`，如下输出：
    ```bash
    000cffb0  f5 c3 af 5f 35 83 75 c5  2b 1e f7 5d 5f d6 c4 47  |..._5.u.+..]_..G|
    000cffc0  5f 3c 2d 75 cb f7 d0 07  df e6 d3 2e f6 04 da e5  |_<-u............|
    000cffd0  84 f6 bb 9c 62 7c b8 cd  ed 11 88 2d f4 fd 55 dd  |....b|.....-..U.|
    000cffe0  af b0 f9 d5 a8 a7 ae 91  7b 81 6e 73 3d e4 ab ef  |........{.ns=...|
    000cfff0  d0 7e d0 e2 6b cf ec 1b  ec 1a e4 ef 35 59 0e 5e  |.~..k.......5Y.^|
    000d0000  b7 04 f0 6f 00 00 00 17  74 45 58 74 54 68 69 73  |...o....tEXtThis|
    000d0010  20 69 73 20 61 20 74 65  73 74 31 20 63 6f 6e 74  | is a test1 cont|
    000d0020  65 6e 74 ab ab 44 d9 00  00 ff f4 49 44 41 54 d8  |ent..D.....IDAT.|
    000d0030  b8 3d 59 6c 5f 9b af 46  fe e6 ef 6a 15 5b 14 93  |.=Yl_..F...j.[..|
    000d0040  b3 f9 8d 6a ae 2f cd 46  5a cd db bb d0 1c f7 ac  |...j./.FZ.......|
    000d0050  ff 14 6b 5e bc 3d b5 7f  ae 81 3d 2d 5e ad fc d5  |..k^.=....=-^...|
    --
    003effd0  49 fc fe e7 9f c6 3f fe  f2 f3 f8 dd 2f 3e 8b af  |I.....?...../>..|
    003effe0  3f bf 13 5f 3d f8 38 7e  fd 8b 6f e3 97 bf f8 2e  |?.._=.8~..o.....|
    003efff0  7e fe f3 ef e3 57 bf fa  45 fc fd df ff 36 7e fd  |~....W..E....6~.|
    003f0000  db 5f c5 27 5f 7d 1e af  df ba 1d 67 df b8 11 e7  |._.'_}.....g....|
    003f0010  df b9 1b 27 ae 7f 1a 07  41 73 3f 2f cf d0 fc 23  |...'....As?/...#|
    003f0020  8c e6 9e 74 24 de ce 00  00 00 17 74 45 58 74 54  |...t$......tEXtT|
    003f0030  68 69 73 20 69 73 20 61  20 74 65 73 74 32 20 63  |his is a test2 c|
    003f0040  6f 6e 74 65 6e 74 92 26  78 1c 00 00 ff f4 49 44  |ontent.&x.....ID|
    003f0050  41 54 b1 e7 3a cf 5f cd  3d e3 dd 66 dc dc f7 24  |AT..:._.=..f...$|
    003f0060  66 f1 fc 27 31 cb ef 74  8c b9 17 15 02 57 73 df  |f..'1..t.....Ws.|
    003f0070  3f 7c f3 41 c1 be eb f7  7a f7 53 f4 c4 f5 9e c7  |?|.A....z.S.....|

    ```
    3. 如上输出隐写后的`tEXt`的数据`"This is a test1 content", "This is a test2 content"`相关字符串为**明文**
- zTXt
    1. 使用`zTXt`，步骤上1
    2. 查找关键字`zTXt`，命令`grep -C5 "zTXt" /var/tmp/11`
    ```bash
    0020ffb0  bf 7c 6e d3 2f de 5a 9c  97 fc 5f e7 fc 36 be 5f  |.|n./.Z..._..6._|
    0020ffc0  cc fa e0 7e bf ac 13 3e  f5 be f3 8a 7f f6 67 8d  |...~...>......g.|
    0020ffd0  d9 fd 19 b2 35 ad 15 df  d9 df 33 cf d7 c5 80 fb  |....5.....3.....|
    0020ffe0  7d f2 ca f9 ac 03 8f ba  9f c8 9f af 31 2d 7c f3  |}...........1-|.|
    0020fff0  9e f1 fd ec 2d 8a df e7  ef e2 fb 0f 9a 3e ed e6  |....-........>..|
    00210000  36 49 35 a0 00 00 00 1d  7a 54 58 74 78 9c 0b c9  |6I5.....zTXtx...|
    00210010  c8 2c 56 00 a2 44 85 92  d4 e2 12 23 85 e4 fc bc  |.,V..D.....#....|
    00210020  92 d4 bc 12 00 5f 9f 08  43 26 51 68 b8 00 00 ff  |....._..C&Qh....|
    00210030  f4 49 44 41 54 7c a1 1f  ac 2d fa 61 e0 c2 3f 30  |.IDAT|...-.a..?0|
    00210040  fb 21 e1 fe 80 a9 1f 28  5d fe 85 1f 6e 3d f9 f8  |.!.....(]...n=..|
    00210050  d7 5e 7c 8b 7d ac f3 03  4f 17 b3 5e e7 fd 89 f6  |.^|.}...O..^....|
    --
    004fffe0  5f 1c 92 c2 0f e0 1a af  46 d1 9a 40 c7 f8 a9 c3  |_.......F..@....|
    004ffff0  39 18 5f ae 7d ec f8 e5  aa 4d 2b d4 28 5c 33 d7  |9._.}....M+.(\3.|
    00500000  d6 eb a2 cd 7b 10 1e eb  cc 98 7e ff dd 51 43 68  |....{.....~..QCh|
    00500010  f3 fe 13 bd 66 d3 86 ae  3e 75 ec d3 ee d7 74 83  |....f...>u....t.|
    00500020  b6 7b de ac 95 73 76 ec  35 18 30 5f b4 00 00 00  |.{...sv.5.0_....|
    00500030  1d 7a 54 58 74 78 9c 0b  c9 c8 2c 56 00 a2 44 85  |.zTXtx....,V..D.|
    00500040  92 d4 e2 12 43 85 e4 fc  bc 92 d4 bc 12 00 5f 96  |....C........._.|
    00500050  08 42 d2 5a ec 88 00 00  ff f4 49 44 41 54 14 ae  |.B.Z......IDAT..|
    00500060  15 80 b7 af 4f 6a 6a 5e  d7 a7 eb af 06 71 de 37  |....Ojj^.....q.7|
    00500070  f2 85 1a ce 7f e6 76 5c  db 84 b5 ed f5 2d f8 d3  |......v\.....-..|
    00500080  46 6b ad ab 7b f7 0a be  27 7a 73 d8 21 e8 c1 18  |Fk..{...'zs.!...|
    ```
    3. 如上输出隐写后的`zTXt`的数据`"This is a test1 content", "This is a test2 content"`相关字符串为**密文**

<div id="refer-anchor"></div>


#### 参考文章：

[1] [PNG文件格式](https://blog.csdn.net/hherima/article/details/45846901)

[2] [PyPNG documentation](https://pypng.readthedocs.io/en/latest/)



Enjoy.

