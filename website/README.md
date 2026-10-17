# SMT Fusion 官网与教程

公开地址：https://smt-fusion-desktop.yy19273767397472432.chatgpt.site/

三语教程：`/guide.html?lang=zh`、`?lang=en`、`?lang=th`。

纯静态 HTML / CSS / JavaScript，无构建依赖。`content.js` 维护中英泰文本；`site.js` 渲染页面、保存语言偏好及执行本地教程搜索。六个下载链接直接指向 GitHub 最新正式安装包。可选 GitHub 版本查询超时不影响下载。页面不收集 Excel、AI 密钥或分析数据，无上传入口或追踪脚本。演示图由真实 Flutter 界面和合成测试数据渲染。

WSL Ubuntu（安装 Node.js 时）：`node --test website/check.mjs`；本地预览：`python3 -m http.server 8175 --bind 127.0.0.1 --directory website`。

发布通过 Sites source helper 将本目录的静态文件复制到独立 Site 仓库 `dist/`，推送并打包同一提交，再保存版本和部署。Site ID 为 `appgprj_6ad37142dca0819187d250ccc92cf9c5`，不要重复创建。凭据仅通过 helper 标准输入传递，不得保存在仓库。`check.mjs` 和本说明不需放入公开静态目录。

Noto Sans Thai 的 OFL 许可位于 assets。保留现有应用图标素材，不将原图中的设备品牌视为官方背书。
