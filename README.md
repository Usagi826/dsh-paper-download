# 文献下载 (dsh-paper-download)

把 `download_paper` 技能做成左侧「文献下载」面板：输入论文标题 / DOI / arXiv 编号 / PDF 直链，
自动检索开放获取 PDF，按 `{年份} - {期刊} - {标题}.pdf` 命名保存到所选目录（默认桌面）。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![DeepSeek Harness plugin](https://img.shields.io/badge/DeepSeek%20Harness-plugin-blue.svg)

## 安装

需要先安装 **DeepSeek Harness 桌面版**（自带的 Node.js 运行时满足 `>=22`，无需另外安装 Node）。

1. 打开 **插件** 页面，点右上角 **添加插件**。
2. 在输入框填入以下任一来源，点 **安装**：
   - GitHub 仓库地址：`https://github.com/Usagi826/dsh-paper-download`
   - 包名（若已发布到 npm）：`dsh-paper-download`
   - 本地目录：插件文件夹的绝对路径，例如 `C:\Users\<你>\Documents\dsh-paper-download`
3. 重启 DeepSeek Harness。左侧「自动化」下方出现 **文献下载** 图标即安装成功。

> 插件以本机用户权限运行，请只安装来源可信的版本。升级时在插件页重装即可；本地目录安装则是实时生效。

## 使用

1. 左侧栏「自动化」面板下方的 **文献下载** 图标（或「更多」菜单）打开面板。
2. 搜索框输入标题、DOI、`arXiv:1706.03762`、`https://arxiv.org/abs/…` 或 PDF 直链，回车提交
   （`Shift+Enter` 换行）。搜索框随内容自动增高，最多 10 行，超出后框内滚动，不可手动拉伸。
3. **粘贴一整段文献列表**会自动切换为批量模式：按行逐条识别 DOI / arXiv / 标题，依次下载，
   显示 `已完成/总数`、成功与失败计数，可随时停止。识别上限 50 条。
4. 搜索框右侧的路径选择器切换保存位置；默认桌面，选择会被记住。
5. 结果显示保存的文件名、路径、来源、尝试过的链接；失败时给出可手动打开的链接。

界面尺寸统一：输入框、路径框、按钮均为 38px 高、9px 圆角，两行控件的间距与对齐一致；
搜索按钮始终与输入框首行对齐，不随多行内容拉伸。

## 检索顺序

按实测命中率排序，最可靠的来源先试；排在前面的来源命中后，后面的不会发起请求：

| 顺序 | 来源 | 实测表现 |
| --- | --- | --- |
| 1 | arXiv 已知编号 | 直链确定，命中即完成 |
| 2 | 出版商镜像（`10.1038/` → `link.springer.com`） | 约 3 s，实测 2/2 命中 |
| 3 | Unpaywall `best_oa_location` 与全部 `oa_locations[].url_for_pdf` | 1.8–2.5 s，覆盖最广 |
| 4 | Semantic Scholar `openAccessPdf` | 1.1–1.9 s，命中率偏低 |
| 5 | bioRxiv / medRxiv / chemRxiv 预印本 | 文件名标注 `(preprint)` |
| 6 | doi.org 落地页里的 PDF 链接 | 3–7 s，常返回 HTML；**仅在前 5 项全部失败时才发起** |

单个候选 20 s 超时，避免一个卡死的出版商拖垮整个任务。

元数据来自 Crossref → OpenAlex → Semantic Scholar（按 DOI 或标题，标题按「标题完全一致 > 论文类型 > 年份」排序）。

每个候选都校验 `%PDF-` 文件头与大小；若 PDF 中能读出 DOI 且与目标不符，则跳过该文件。
文件名规则、Windows 非法字符替换、预印本来源标注与技能文档一致。

## 期刊名使用 NLM/CASSI 缩写

文件名使用期刊的**标准缩写**（如 `Nat. Neurosci`），面板中同时展示全称与缩写。

- **能不能直接抓 cassi.cas.org？** 不能可靠做到。该站首页只返回 Usage Agreement 骨架，正文由
  JavaScript 生成（页面上明确写着 "You have to enable JavaScript…"），且外层套了 Imperva/Incapsula
  反爬（`_Incapsula_Resource` 脚本 + `incap_ses_*` Cookie）。纯脚本请求拿不到搜索结果表单，也就不可能稳定解析
  `Abbreviated Title`。所以插件**不依赖 CASSI 在线抓取**，改用下面三级来源。
- **缩写来源（按可信度）**：
  1. 论文元数据自带的缩写 —— Crossref 的 `short-container-title`（如 `Nat Neurosci`）；
  2. 插件内置缓存 `lib/journals.json`（离线、零请求）：
     - `abbreviations`：80 本常用期刊的人工整理全称→缩写表；
     - `issn`：8141 条「全称(小写归一化) → ISSN」表，采自 Crossref 期刊索引，用于补全缺失的刊名/ISSN；
  3. Crossref 按 DOI 或 ISSN 查询该刊其他论文的 `short-container-title`；
  4. 以上都拿不到时，按 NLM 词表规则拼装（`Nature Neuroscience` → `Nat. Neurosci.`），
     规则表含 200+ 常用期刊词（`Journal→J.`、`Proceedings→Proc.`、`National→Natl.`、`American→Am.` 等），
     功能词 `of/and/the/for…` 按 NLM 规范省略，单字刊名（`Nature`/`Cell`）保持原样。
- **标点统一**：Crossref 有的给 `Nat Neurosci`、有的给 `J. Neurosci.`，插件统一规范成
  「每个缩写词后一个点」的样式。Windows 不允许文件名段以点结尾，因此保存到磁盘时末尾那个点会去掉
  （`Nat. Neurosci`），界面中仍显示完整形式 `Nat. Neurosci.`。
- 出版社平台名（`Springer Science and Business Media LLC`、`Elsevier BV` 等）一律不当作刊名。

## 接口（同一 Host 路由，面板调用）

`POST /paper-download/<endpoint>`，JSON 请求，`{ ok: true, value }` / `{ ok: false, error }`：

- `resolve` `{ query, directory?, email? }`：完整检索并下载。
- `folders` `{ path? }`：目录浏览（面包屑、上级、子目录、桌面/主目录）。
- `reveal` `{ path }`：在资源管理器中定位文件（Windows）。
- `openExternal` `{ url }`：用系统默认浏览器打开 http(s) 链接（「手动搜索」用）。

## 说明

- 默认联系邮箱 `paper-download@dsh.local` 只用于 Unpaywall 接口；面板可改为真实邮箱，邮箱与保存目录只存在本机浏览器里，不随插件分发。
- Wiley / AAAS / Cell / PMC 等站点反爬或付费墙，无法自动下载，会列入手动链接。
- 网络请求均有超时；离线或接口限流时面板给出失败原因而不是挂起。
- 仅下载开放获取（OA）全文，不绕过付费墙；请遵守各出版商的使用条款与所在机构的订阅协议。
- 插件没有第三方运行时依赖，`dependencies` 为空，安装时不需要编译原生模块。

## 下载记录与角标

- 每完成一次检索（成功或失败）都会写入浏览器本地存储 `dsh-paper-download.history.v1`：
  关闭面板、切换页面、重启应用后记录仍在，最多保留 50 条、90 天。
- 面板「下载记录」列出全部条目，**两种结果都按规范文件名显示**（`{年份} - {期刊缩写} - {标题}.pdf`）：
  - 成功：显示实际保存的文件名、时间与文件大小；
  - 未成功：没有落盘，但同样显示按检索到的元数据（标题、年份、期刊）推算出的文件名，副标题标注「未保存 · 时间」，鼠标悬停可看到计划保存的完整路径；元数据缺失时依次退化为 DOI、arXiv 编号或原始查询词；
  - 点击一条可在上方查看详情，「重新下载」会重新检索（旧卡片先收起，进度条立即显示），垃圾桶按钮删除单条，右上角「清空记录」清空全部。
  - 每次检索带序号，迟到的旧结果不会覆盖新任务的进度条；点击记录只切换下方内容，不动正在进行的下载。
  - 记录列表自身最高 420px，超出在列表内部滚动；页面和列表都预留了滚动条槽位（滚动条只在悬停时显色），清空记录时内容变短、不会有关闭滚动条导致的宽度抖动。
- 左侧「文献下载」图标右上角是一个 **7px 小圆点，不显示数字**：
  - 下载进行中：圆点缓慢呼吸闪烁；
  - 有尚未查看的新记录：圆点常亮，打开面板看过即消失（已读位置记在 `dsh-paper-download.history.seen.v1`），此后再有下载才重新出现。
  - 悬停提示里带最近一条的文件名。
- 记录只存查询、结果状态、文件名/路径与 DOI 等元数据，不缓存 PDF 本身。
- 失败条目的详情里，在「重新下载」右侧有「手动搜索」：自动把文章标题（没有标题时用原始查询词）填进 `https://cn.bing.com/search?q=`，并用**系统默认浏览器**打开，而不是在应用内开标签页。

## 任务在后台继续

- 检索任务由模块持有而不是面板组件：**切换面板、关闭面板都不会中断下载**。回来时进度条、已用时和查询词原样还在；任务在你离开期间完成，也会在回来时直接显示结果卡片，并写入下载记录。
- 提交时会读取输入框的实际内容，因此切换面板再回来也不会提交到旧的一次输入。

## PDF 来源与校验（避免拿到摘要或封面）

- 每个候选下载后先校验 `%PDF-` 文件头与大小，再统计页数：**少于 3 页**的文件判定为摘要 / 封面 / 更正，直接丢弃并尝试下一个候选，失败信息里写明「only N pages」。
- Nature 系（DOI 前缀 `10.1038/`）的 PDF 在 `www.nature.com` 上会被 303 跳到 `idp.nature.com` 的 Cookie 校验页，脚本取不到文件；插件改为从 `link.springer.com/content/pdf/<doi>.pdf` 取同一篇全文，文件名仍使用真实期刊名（如 Nature Neuroscience）。
- 落地页抓到的链接会排除 `supplement`、`MOESM`、peer-review、correction 等附件与更正，优先取正文 PDF。

## 开发与发布

在仓库目录执行下列命令即可发布；每次发版改 `package.json` 的 `version` 并打 tag（`git tag v1.0.1 && git push --tags`）。
改动记录见 [CHANGELOG.md](CHANGELOG.md)。

```powershell
git init -b main
git add .
git commit -m "feat: 文献下载插件 v1.0.0"
git remote add origin https://github.com/Usagi826/dsh-paper-download.git
git push -u origin main
```

## 许可

[MIT](LICENSE) © 2026 朱骏 (Zhu Jun)
