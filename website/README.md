# SMT Fusion 官网与教程

官网：https://marginal-z.github.io/SMT-CHECK/
教程：https://marginal-z.github.io/SMT-CHECK/guide.html
语言：`?lang=zh`、`?lang=en`、`?lang=th`。

## 维护与部署

HTML / CSS / JavaScript 静态网站，无构建依赖。`content.js` 维护中英泰三语文案；`site.js` 渲染首页与 13 章教程、语言切换及本地搜索。Pages 项目路径下的链接、图片及字体均使用相对路径。

`.github/workflows/pages.yml` 在 main 分支 website/ 变化后执行检查、复制公开文件、上传 Pages artifact 并部署。通过 GitHub Pages 的公开网址访问，不依赖任何开发机服务。发布目录不包含检查脚本、说明文件或用户原始样本。

WSL Ubuntu 执行：`node --test website/check.mjs`。仅用于本地验收的预览：`python3 -m http.server 8176 --bind 127.0.0.1 --directory website`。

## 素材与内容

- `assets/hero-production.png` 是独立生成的宽幅工业工作流概念图，不是放大的应用图标，也不是设备实拍或软件检测结果。
- workbench / merge 三语配图由真实 Flutter 页面和合成样例生成，不含生产数据。
- 应用图标仅用于导航栏及 favicon。Manrope 与 Noto Sans Thai 字体的 OFL 许可随 assets 保留。
- 六个下载链接直达 GitHub 最新正式版本安装包。版本提示查询失败不影响下载。
- 教程只包括准备、操作、判读、输出和使用问题，不包含图标维护说明。AI 密钥、原始文件和生产数据不上传至网站。

旧版客户端中保留的历史官网地址仅用于迁移跳转，不再作为官网内容维护来源。旧 Site ID `appgprj_6ad37142dca0819187d250ccc92cf9c5` 用于兼容重定向，不能重复注册。迁移时保留语言参数及教程锚点；公开内容以本仓库和 GitHub Pages 为准。
