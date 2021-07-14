---
title: "使用Github Actions自动构建Hugo个人博客"
date: 2021-07-14T20:07:57+08:00
draft: false
tags: ["教程", "hugo", "github actions"]
categories: ["教程"]
katex: false
mermaid: false
author: "Icheon Tao"
slug: "use-github-actions-building-hugo-blog"
toc: true
---
---
---
最近想搭建一个静态网站来记录自己的生活和编程笔记等，本着不折腾的心态选择了[Hugo](https://github.com/gohugoio/hugo)引擎和[MemE](https://github.com/reuixiy/hugo-theme-meme)主题，最后发现还是挺折腾的。所以就记录下搭建过程，希望这篇博客对你有帮助。

本篇主要内容是使用Github Actions自动构建Hugo+meme的个人博客，并绑定自己的域名。本文默认你熟悉Git。

### 部署Hugo环境
该环境是在`Windows 10`上搭建，平时写博客使用的是`Visual Studio Code`。

#### 安装hugo并设置环境变量
在[Hugo下载地址](https://github.com/gohugoio/hugo/releases/)下载你操作系统对应的安装包。**在windows版本上有两个版本:** `Hugo`和`Hugo extend`(extend版本支持Sass/SCSS)，根据自己的需要选择版本。笔者因为要使用`meme`主题，需使用`Hugo extend`。下载并解压到对应的目录，然后将其添加到系统环境变量中即可。

在cmd窗口中输入
```
hugo version
```
输出如下类似版本信息即Hugo安装成功
```bash
hugo v0.85.0-724D5DB5+extended windows/amd64 BuildDate=2021-07-05T10:46:28Z VendorInfo=gohugoio
```

#### 初始化你的站点
在相应的目录，笔者的目录为`C:\programs\MyGit\`下执行，建议使用你域名，如果没有域名，可以使用`username.github.io`来创建站点
```powershell
hugo new site 10001001.xyz[你站点的名字]

# 使用Git初始化该站点
cd 10001001.xyz
git init
```
进入`10001001.xyz`目录查看站点文件信息
```powershell
----                 -------------         ------ ----
d-----         2021/7/13     18:11                archetypes
d-----         2021/7/13     18:11                content
d-----         2021/7/13     18:11                data
d-----         2021/7/13     18:11                layouts
d-----         2021/7/13     18:11                static
d-----         2021/7/13     18:11                themes
-a----         2021/7/13     18:11             82 config.toml
```
hugo常用的命令
```bash
hugo new site path/to/site_name     # 创建站点
hugo new  xxx.md                    # 创建md页面
hugo new dir/xxx.md                 # 在目录dir下创建md页面
```

### 安装站点主题
安装自己喜欢的主题，可以去[Hugo Themes](https://themes.gohugo.io/)和`Github`上寻找主题。笔者使用时`MemE`极简主题，主题的一般安装步骤就是将你主题下载到站点根目录下的`themes`目录下。
```bash
git submodule add --depth 1 https://github.com/reuixiy/hugo-theme-meme.git themes/meme
```
再将`themes/meme/config-examples/zh-cn/config.toml`文件复制并覆盖站点根目录下的`config.toml`，并根据[官方示例配置](https://github.com/reuixiy/hugo-theme-meme/blob/master/config-examples/zh-cn/config.tomlthemes/meme/config-examples/zh-cn/config.toml)来个性化设置自己的站点，你也可以参考本站点的[配置](https://github.com/icheontao/10001001.xyz/blob/main/config.toml)。

接下来就可以执行`hugo server`启动一个服务端（访问地址`http://localhost:1313`）并适当修改`config.toml`调试站点的布局。

折腾出自己想要的样式还是需要些时间。

## 配置Git Actions
登录你的Github账号，新建仓库，可以使用你域名或者`username.github.io`作为你的仓库名。

### 配置Github Actions
在你本地站点根目录下新建目录`.github/workflows`，并新建一个yml文件，名字无所谓。这里新建一个`blog.yml`文件
```yml
name: GitHub Pages Deploy

on:
  push: 
    branches:
      - main                        # 需要构建的源代码分支

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout main branch
        uses: actions/checkout@v2
        with:
          submodules: true
          fetch-depth: 0
        
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.85.0'    # Hugo版本号
          extended: true            # 此处配置为 是否适用extend版本，根据自己的主题来定

      - name: Build Hugo
        run: hugo --minify

      - name: Deploy Hugo
        uses: peaceiris/actions-gh-pages@v3
        with:
          deploy_key: ${{ secrets.ACTIONS_DEPLOY_KEY }}     # 此处key需要配置，见文https://github.com/peaceiris/actions-gh-pages#%EF%B8%8F-create-ssh-deploy-key
          publish_branch: blog                              # 自动构建后发布到的分支，此处为自定义
          publish_dir: ./public
          cname: 10001001.xyz                               # 你域名地址(如果有域名的话，没有则去掉该字段)
          commit_message: ${{ github.event.head_commit.message }}
```
接下来就是编写`README.md`和`LICENSE`，有了这两个文件才算是一个完整的GIT仓库。可以参考笔者的仓库[点击查看](https://github.com/icheontao/10001001.xyz)。准备提交代码，看看构建效果。

```bash
git add .
git commit -m "first commit"
git branch -M main

# 设置远程仓库
git remote add origin https://github.com/icheontao/10001001.xyz.git # 此处为你仓库地址
git push -u origin main
```
打开仓库地址，点击`Actions`，查看构建结果。
![Github Actions构建结果](imags/github_actions.png)

## 配置Github Pages
登录到你的站点Github下，点击 `Setttings` -> `Pages`进行对应的设置，如下：(标红处是需要注意的地方)
![github pages settings](images/github_pages_setting.png)

**Branch: 为你自定义的git分支；Enforce HTTPS: 为强制开启HTTPS，如果开启的话，需要等待一段时间刷新即可，Github会自动给你生成证书**

## 自定义域名解析(可选)
笔者域名在阿里云，以下步骤都是在阿里云控制台完成。其他厂商可自行登录到域名解析界面操作。

添加一条`CNAME`记录到`username.github.io`(username为你github用户名)
并添加`A`记录到`Github Pages`的IP地址：(至少一个)
```bash
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```
最后域名解析状态如下:
![域名解析状态](images/github_pages_setting_2.png)

域名解析具体说明见[配置Github Pages站点的自定义域](https://docs.github.com/cn/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site)

## 结束
最后添加文章，提交github，查看站点
```bash
# 1. 新建md文件
hugo new xxx.md
# 2. 编辑文件

# 3. 提交代码(由于每次写完都要提交，所以这一步可集成到脚本中，参考见update_pages.sh，在windows上使用Git Bash下运行)
git add .
git commit -m "commit msg"
git push

# 查看站点
# 查看github actions构建是否构建成功，最后就可以看到文章自动构建到你的站点了。
```
enjoy.