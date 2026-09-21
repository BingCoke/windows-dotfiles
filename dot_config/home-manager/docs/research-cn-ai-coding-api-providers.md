# 中国境内/中国背景 AI Coding API 服务商（截至 2026-09-07）

**访问日/截止日：2026-09-07。** 本文只把“公司自己运营、开发者可申请 API key、官方文档给出可调用 HTTP/API 入口，并且官方材料明确代码/软件工程能力”的服务纳入确认表。网页聊天、仅 IDE/插件、仅开源权重、没有可申请 key 的产品，以及仅有 function calling 而无代码证据的模型，不算。A 是官方代码专用模型/API；B 是通用模型 API，但官方文档明确代码任务、软件工程或代码智能体能力。估值采用可追溯的最近公开估值；融资金额本身不当估值。价格只引用官方定价页；动态页没有保存快照的，明确写“未核实/询价”，不填旧数字。

## 一句话结论

截至本次核验，证据链完整、可作为 AI Coding API 候选的主要服务商是：**阿里云百炼/通义（A）、火山方舟/豆包（A）、百度千帆（B）、科大讯飞星火（B）、智谱 GLM（B，另有 Coding Plan 但有客户端限制）、月之暗面 Kimi（A）、MiniMax 开放平台（A）**。腾讯混元有正式 API，但本次未能让其当前可调用模型与一条可打开的官方代码能力页面闭环，因此保守放入待核实。其中百度曾有 Coding Plan，但官方公告显示 **2026-07-13 起停止新购**；不要把已停售/仅指定工具的套餐当作通用商业 API。DeepSeek、华为盘古、百川、阶跃、商汤在本次核验中至少缺少一项硬证据，列入待核实而不是确认。

## 口径和限制

* “中国背景”包括大陆公司及其云/平台运营主体；用母公司上市市值证明子品牌门槛时，明确写出母子关系。上市门槛仅人民币 1000 万元，数量级极低；上市身份加可核验的 2026 年 9 月市值快照已足以判定超过门槛，但不是投资建议。
* 对上市公司，投资者关系页证明上市身份，CompaniesMarketCap 作为带月份的公开行情交叉检查；它不是交易所原始行情，因此不伪造某一日精确市值。对未上市公司只使用公开报道中明确的 valuation/估值，不能用融资额替代。
* 动态控制台、登录后价格、地区和阶梯价格会变化。以下价格栏仅记官方页可见的计费方式；无法在无登录状态稳定读取数字就写“未核实/询价”。
* “截至”不是声称穷尽市场，也不作性能排名。模型下线、域名重定向和套餐政策均需采购时重新确认。

## 确认名单总表

| 公司/运营平台 | 组别 | API/key 证据 | 官方代码能力证据 | 市值/估值门槛 | 价格（官方页，2026-09-07） |
|---|---|---|---|---|---|
| 阿里云百炼/通义（阿里巴巴） | A | [Qwen-Coder API 文档](https://help.aliyun.com/zh/model-studio/qwen-coder) 明确需 API Key，示例使用 OpenAI 兼容 endpoint；区域入口为 `https://{WorkspaceId}.cn-beijing.maas.aliyuncs.com/compatible-mode/v1` | 同一官方页写明“专用于代码任务”，代码生成、补全、工具调用，并以 `qwen3-coder-next` 编程示例 | [阿里巴巴 IR 年报页](https://www.alibabagroup.com/en/ir-financial-reports)；[2026-09 月市值公开快照](https://companiesmarketcap.com/alibaba/marketcap/) 显示约 **US$281.47bn**，远超 RMB 10m | [官方模型价格](https://help.aliyun.com/zh/model-studio/model-pricing)；页面当前列出 `qwen3-coder-plus` 按输入/输出每百万 Token、按上下文阶梯计费。具体报价以页面和地域为准；不要沿用旧草稿数字 |
| 火山引擎方舟/豆包（字节跳动） | A | [方舟模型服务文档](https://www.volcengine.com/docs/82379/) 提供模型调用、Chat/Responses API、SDK 和控制台 key；`https://ark.cn-beijing.volces.com/api/v3` 为方舟常用 API base URL（以账户地域为准） | [官方 Doubao-Seed-Code 发布材料](https://developer.volcengine.com/articles/7577301460712030258) 将 Seed-Code 定位为代码生成/编程 Agent；方舟文档提供模型和 API 入口 | 字节未上市；[Reuters 2025-08-27/28](https://www.reuters.com/business/finance/tiktok-owner-bytedance-sets-valuation-over-330-billion-revenue-grows-sources-say-2025-08-27/) 明确报道员工回购使 ByteDance 估值 **超过 US$330bn**（Reuters 页面本次 HTTP 401，见末尾限制，但 URL 和日期可追溯） | [方舟产品/计费入口](https://www.volcengine.com/product/ark)；按 token、模型和阶梯计费。公开页/控制台未能稳定保存 Seed-Code 当日数字，记 **未核实/询价**。Coding Plan 是订阅/用途受限方案，不等于任意第三方 SaaS 的通用余额 |
| 百度智能云千帆（百度） | B | [千帆 API 快速开始](https://cloud.baidu.com/doc/qianfan/s/rmh4stn9m) 明确创建 API Key、Bearer 鉴权并发送 REST/OpenAI 兼容请求；官方模型列表含可调用模型。 | [官方模型列表](https://cloud.baidu.com/doc/qianfan/s/rmh4stp0j) 对 ERNIE-5.1/DeepSeek-V4-Pro 的适用场景明确含“整站代码库一次性通读解析”“代码全工程开发”；平台还提供 Coding/Token Plan 工具接入。该证据支持 B，但不是把函数调用推成代码能力 | [百度 IR 年报](https://ir.baidu.com/financial-information/annual-reports)；[2026-09 月市值快照](https://companiesmarketcap.com/baidu/marketcap/) 约 **US$33.73bn**；上市身份和数量级远超门槛 | [官方计费文档](https://cloud.baidu.com/doc/qianfan/s/wmh4sv6ya)（页面更新时间 2026-09-02）列模型服务按 Token 计费；具体模型/高峰时段价格需从当日表核对，本文不复制易变旧数字 |
| 科大讯飞星火（科大讯飞） | B | [官方 HTTP API 文档](https://www.xfyun.cn/doc/spark/HTTP调用文档.html) 给出 API Password、OpenAI SDK 和 `https://spark-api-open.xf-yun.com/v1/chat/completions` | 同一官方 HTTP 文档在参数说明中明确“数学、推理、代码等任务”建议参数，属于官方代码任务证据；不把 Function Call 单独当成代码证据 | [科大讯飞投资者关系](https://www.iflytek.com/en/investor/)；[2026-09 月市值快照](https://companiesmarketcap.com/iflytek/marketcap/) 约 **US$14.09bn**；上市身份足以超过门槛 | [星火 API 产品入口](https://xinghuo.xfyun.cn/sparkapi)；按 Token/资源包的现行价格需账户或动态页确认，记 **未核实/询价** |
| 智谱 AI / GLM（Knowledge Atlas Technology，原北京智谱华章） | B；Coding Plan 另行说明 | [官方开发指南](https://docs.bigmodel.cn/cn/guide/start/introduction) 明确标准 API、API Key/OpenAI 兼容接入，并写明 GLM 支持代码生成和 Agent 应用；普通 API endpoint 为 `https://open.bigmodel.cn/api/paas/v4` | 同一官方指南是通用模型代码生成证据，故 B；[GLM Coding Plan 概览](https://docs.bigmodel.cn/cn/coding-plan/overview) 另明确需求理解、代码生成、调试修复、代码库问答和自动化任务 | [Reuters 2025-12-30](https://www.reuters.com/world/asia-pacific/chinese-ai-firm-minimax-targets-up-539-million-hong-kong-ipo-2025-12-30/) 报道其同日 IPO 估值约 **HK$51.2bn**；其后已以 2513.HK 上市，故远超 RMB 10m（Reuters 本次直连 401；报道日期和 URL 如实保留） | [官方价格页](https://bigmodel.cn/pricing)；普通 API 价格动态。Coding Plan 说明“仅限官方支持的指定工具与产品环境”，且 API 在规定工具外调用不能享受套餐额度；它不是通用商业 API 余额。普通 API 具体价格 **未核实/询价** |
| 月之暗面 Kimi（Moonshot AI） | A | [Kimi API 获取 Key/文档](https://platform.kimi.com/docs/get-api-key) 与[模型文档](https://platform.kimi.com/docs/models)；官方模型 API 使用 key，平台常用 endpoint 为 `https://api.moonshot.cn/v1`（旧域名重定向时以控制台为准） | 官方模型页（当前页面写明 2026-08-31 下线旧 K2.5/v1，并列出 `kimi-k2.7-code` 为 Coding 模型、软件工程描述）是直接代码能力证据 | [TechCrunch 2026-05-07](https://techcrunch.com/2026/05/07/chinas-moonshot-ai-raises-2b-at-20b-valuation-as-demand-for-open-source-ai-skyrockets/) 明确写融资后估值 **US$20bn**；超过门槛。该页本次 HTTP 200 | [官方 Kimi 推理定价](https://platform.kimi.com/docs/pricing/chat) 明确 Token 输入/输出、缓存、批量及 `Kimi K2.7 Code` 定价入口；当日动态数字未在报告中固化，具体价 **未核实/询价** |
| MiniMax 开放平台（MiniMax Group） | A | [官方文本模型 API 文档](https://platform.minimaxi.com/docs/guides/text-generation) 明确 API Key、Anthropic/OpenAI 兼容 base URL：`https://api.minimax.cn/anthropic` 或 `https://api.minimax.cn/v1` | 同一官方页将 M3 定位 Frontier Coding，写明 M 系列适用于代码和多语言编程、Agent 工作流 | MiniMax 已在港交所上市；[Reuters 2026-01-09](https://www.reuters.com/world/asia-pacific/china-ai-firm-minimax-set-surge-hong-kong-debut-2026-01-09/) 报道其上市首日估值约 **US$13.7bn**；[2026-09 月市值快照](https://companiesmarketcap.com/minimax-group/marketcap/) 约 **US$17.25bn**，远超门槛 | [官方定价概览](https://platform.minimaxi.com/docs/pricing/overview) 明确区分面向企业的实时 API 价格与面向个人/小团队的 Token Plan；API 具体模型价 **未核实/询价**，不得用 Token Plan 价格替代 |

## 逐公司证据补充和边界

### 阿里云/通义
Qwen-Coder 官方页的原文同时满足三项硬条件：专用于代码任务、示例通过 API Key 调用 `qwen3-coder-next`、给出代码生成/补全与工具交互。价格页当前显示 `qwen3-coder-plus` 的输入/输出每百万 Token 阶梯表；这是最稳妥的 A 类直接候选。百炼 Coding Plan/Claude Code 额度仍应与按量 API 分开采购。

### 火山方舟/豆包
运营主体是火山引擎，估值用 ByteDance 母集团而非融资额。方舟普通模型调用与 Coding Plan 网关不能混淆；采购时要求确认企业 key、区域、商业用途、速率和是否允许把结果嵌入自有开发者产品。Reuters 估值是可靠二手来源但本次被反爬，不能描述为已直接打开全文。

### 百度千帆
当前官方文档显示 Coding Plan 已于 **2026-07-13 10:00（北京时间）起停止新购**，存量用户可继续到周期结束并迁移；所以确认依据是普通千帆 API + ERNIE/DeepSeek 的整站代码库/全工程开发说明，不是把已停售套餐算作公共 API。模型列表页面更新时间为 2026-08-27，计费文档更新时间为 2026-09-02。

### 科大讯飞星火
官方 HTTP 页面确实出现“代码等任务”，因此满足本报告最低 B 类代码证据，但这不等于代码专用模型、也不代表经过独立 SWE benchmark 验证。API Password 与腾讯/阿里 key 体系不同，模型名、套餐和免费额以控制台为准。

### 智谱
标准 GLM API 是可调用 API，官方平台文档明确代码生成；Coding Plan 则是另一种订阅。Coding Plan 概览明确限制指定工具/产品环境，不能当通用 SaaS 的按量接口；需要普通 API 额度和企业合同的采购不应只买 Coding Plan。

### Kimi
当前官方平台域名已从旧 Moonshot 页面重定向到 `platform.kimi.com`，且旧 `kimi-k2.5`/`moonshot-v1` 已于 2026-08-31 下线。确认依据使用当日模型页中的 `kimi-k2.7-code` 和 API key 文档，不复用旧草稿中的 K2.5 结论。

### MiniMax
官方文档明确区分企业按量 API 与 Token Plan；这正好满足“自己运营且 key 调用”的要求。MiniMax 的上市后估值证据比未上市融资报道更强，采用 Reuters IPO/首日和 2026-09 月行情交叉核对。

## 产品匹配、估值或其他证据待核实

| 公司 | 已找到的产品/API | 缺口及处理 |
|---|---|---|
| 腾讯云混元 | [混元 OpenAI 兼容调用](https://cloud.tencent.com/document/product/1729/111007) 与[原生 API](https://cloud.tencent.com/document/product/1729/105701) 均可 HTTP 200 打开；[IR](https://www.tencent.com/en-us/investors.html) 和[2026-09 市值快照](https://companiesmarketcap.com/tencent/marketcap/) 足以证明市值门槛 | 本次找到的腾讯 Hy3 代码生成公告 URL 返回 404，现有可打开 API 页面本身又未明确代码生成；不能只靠搜索摘要或 function calling 推断，故待核实当前模型代码能力官方直达页 |
| DeepSeek（幻方背景） | [官方 API 文档](https://api-docs.deepseek.com/)（HTTP 200）明确 API Key、`https://api.deepseek.com`，并明确可作为 Claude Code/GitHub Copilot/OpenCode 等 coding assistant 后端；[官方价格](https://api-docs.deepseek.com/quick_start/pricing/) | API/代码证据充分，但本次没有取得公司自己披露或 Reuters/Bloomberg 等可靠来源明确写出的已实现估值；市场热度、开源权重、融资传闻不能代替估值，故不进确认表 |
| 华为云/盘古 | [ModelArts/盘古官方入口](https://support.huaweicloud.com/modelarts/index.html)；云 API/企业模型服务存在 | 华为非上市，本次未取得明确公司估值；且统一面向开发者的代码专用 API/当前定价链未稳定核验，列待核实 |
| 百川智能 | [官方平台文档](https://platform.baichuan-ai.com/docs/api) 可见开放平台 API | 本次未取得足够明确的官方代码生成/软件工程定位和明确估值；融资额不替代估值 |
| 阶跃星辰 | [官方 OpenAI 兼容接入页](https://platform.stepfun.com/docs/zh/guides/developer/openai) 可见 API 入口；平台也有 Agent/代码相关页面 | 本次未取得完成交易的可靠估值证据；报道中的“计划以某估值融资/IPO”不能直接当公司当前 valuation，故待核实 |
| 商汤科技 SenseCore/SenseNova | 官方平台 API 页面曾可见，但旧的 [API 文档链接](https://platform.sensenova.cn/product/APIService/document) 本次返回 404 | 上市门槛（[IR/财报](https://www.sensetime.com/en/financial-reports)、[行情快照](https://companiesmarketcap.com/sensetime/marketcap/)）不成问题；但当前直接 API endpoint 和官方明确代码能力未同时核验，不进确认表 |

## 指定公司逐一结论

| 公司 | 结论 |
|---|---|
| 阿里云/通义 | **确认 A**：API key、Qwen-Coder 代码任务、上市市值三项齐全 |
| 字节/火山 | **确认 A**：方舟 API 和 Seed-Code 代码证据齐全；估值为 Reuters 二手且直连受限 |
| 百度千帆 | **确认 B**：普通 API + 官方整站代码库/全工程开发说明；Coding Plan 已停止新购，不能混淆 |
| 腾讯混元 | **待核实**：API/市值充分，但当前官方代码能力直达页未闭环 |
| 华为盘古 | **待核实**：产品/API可见，估值与当前 coding API 链不足 |
| 科大讯飞 | **确认 B（保守）**：官方 API 文档明确代码任务；不宣称代码专用 |
| 智谱 | **确认 B**：标准 API 的代码生成证据和上市/IPO估值证据齐全；Coding Plan 仅指定工具 |
| DeepSeek | **待核实**：API/代码证据齐全，估值硬证据缺失 |
| Moonshot/Kimi | **确认 A**：当前官方页面列 Coding 模型、API key 和估值证据齐全 |
| MiniMax | **确认 A**：官方 API/Frontier Coding、上市后行情/IPO证据齐全 |
| 百川 | **待核实**：API可见，代码能力/估值不足 |
| 阶跃 | **待核实**：API可见，估值不足 |
| 商汤 | **待核实**：市值门槛足够，但当前 endpoint/代码能力不足 |

## 不应混淆的服务

1. **Coding Plan/Token Plan ≠ 通用商业 API。** 计划若仅允许 Cursor、Claude Code、OpenCode、ZCode 等指定工具，必须按“指定客户端/用途”采购；只有官方明确给出可由开发者申请 key 调用、允许目标用途的 endpoint 才能算 API。百度 Coding Plan 已停售新购；智谱 Coding Plan 页面明确指定工具限制；MiniMax 官方明确把 API 按量与 Token Plan 分开。
2. **网页聊天、IDE 插件和代码助手产品不能反向证明 API。** 例如智能代码助手、ZCode、网页 Kimi 等只有在另外找到公司官方 API/key 文档时才算。
3. **开源权重不等于托管 API。** DeepSeek 等即便有开源模型，本文仍要求另有官方 `api.deepseek.com` 和 API Key 文档；反之没有托管 endpoint 的模型不得纳入。
4. **Function calling 不等于代码能力。** 本文只使用官方“代码生成/代码任务/代码库/软件工程/编程 Agent”等文字；通用工具调用本身未作为纳入理由。

## 采购选型建议（不构成性能排名）

* 需要代码专用模型，先比较 Qwen-Coder、Doubao-Seed-Code、Kimi Code、MiniMax M3；核对模型 ID、区域、上下文、商业再分发和日志留存。
* 需要标准云 API/SLA，优先按量 API 而非个人 Coding Plan；要求供应商书面确认数据驻留、是否训练、并发/QPS、超时重试、审计、内容安全和停服迁移。
* 价格应把输入/输出、缓存命中、批量、上下文阶梯和工具描述 Token 一并测算；本文没有把旧价格或搜索摘要数字当报价。用同一组真实代码生成、修复、测试和大仓库问答任务做 PoC，不据本报告宣称性能排名。

## 来源索引与 HTTP 检查（访问日 2026-09-07）

### 实际访问成功（HTTP 200，或发生 200 重定向）

* 阿里：Qwen-Coder、模型价格（`help.aliyun.com`）；重定向后的火山方舟文档（`docs.volcengine.com`）；百度千帆总目录、API 快速开始、模型列表、计费文档；腾讯混元兼容 API/原生 API；讯飞 HTTP API（URL 编码后）；智谱 Coding Plan/标准开发指南/价格页；Kimi 模型/Key/价格页；MiniMax 文本 API/定价页；DeepSeek API/价格页。
* 估值/行情：TechCrunch Moonshot 2026-05-07 返回 HTTP 200；CompaniesMarketCap 的阿里、百度、腾讯、讯飞、SenseTime、MiniMax 市值页返回 HTTP 200；HKEX 股票数据入口返回 HTTP 200。

### 访问受限或页面状态变化

* Reuters ByteDance 两篇估值报道、Reuters MiniMax/Zhipu IPO报道直连均返回 **HTTP 401 Forbidden**（反爬/访问权限）；因此报告只如实引用其公开 URL、发布日期和搜索可见的标题/摘要事实，不声称本次打开全文。采购/出版前应由人工浏览器或授权数据库保存快照。
* Tencent Hy3 搜索得到的官方文章 URL `tencent.com/en-us/articles/2202386.html` 返回 **HTTP 404**；现有混元 API 页面未明确代码能力，因此腾讯转入待核实，不把搜索摘要当核心证据。
* SenseNova 旧 API 文档 `platform.sensenova.cn/product/APIService/document` 返回 **HTTP 404**；因此商汤不进入确认表。
* Moonshot 旧 `platform.moonshot.cn` 文档重定向至 `platform.kimi.com`；旧模型文档中的下线信息不能复用为当前可用模型。
* 动态价格页多数能 HTTP 200，但部分内容由前端/登录态加载；没有稳定读到的数字统一记“未核实/询价”，未把搜索摘要或营销转载当核心价格证据。

## 本次交付检查

* 文件存在于指定目标路径；本次只写入该 Markdown 文件。
* 确认表每家公司均有三类证据：官方 API/key、官方代码能力、上市市值或明确估值；待核实表明确写出缺口。
* 已抽查阿里、百度、Kimi、MiniMax 官方链接及多个市值/估值链接；HTTP 限制已在上节记录。
* 未解决风险：动态模型/价格/套餐会继续变化；Reuters 估值全文被 401；上市市值页面为二手月度快照而非交易所逐日快照；火山、智谱的 Coding Plan 用途限制和区域商业条款仍需合同级确认。
