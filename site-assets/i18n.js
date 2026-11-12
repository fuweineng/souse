/* Souse 官网文案字典：简体中文（国语） / 粤语 / English
   页面元素用 data-i18n="key" 取纯文本，data-i18n-html="key" 取带标签的片段。
   新增语言：在 D 里加一份同 key 的表，再把 locale 加进 ORDER/LANG_ATTR。 */
(function () {
  var D = {
    'zh-Hans': {
      'meta.title': 'Souse · 出租屋管理系统',
      'meta.desc': 'Souse 管出租屋与公寓：收租催缴、电子合同、门禁网络、水电抄表、住户手机页。免费自托管，部署在你自己的机器上。',

      'nav.features': '能力',
      'nav.deploy': '部署',
      'nav.compare': '对比',
      'nav.faq': '常见问题',
      'nav.try': '登录',
      'nav.menu': '菜单',

      'hero.kicker': '自托管 · 出租屋 / 公寓 / 民宿',
      'hero.h1': '一个片区，一套系统。<br><span class="grad">从签约管到退租。</span>',
      'hero.sub': '租金、合同、门禁、网络、水电共用一份数据。先从一栋楼开始，加到整个片区也不用换系统。欠费自动断网，缴费自动恢复。',
      'hero.cta1': '登录 →',
      'hero.cta2': '部署到自己的机器',
      'hero.m1': '免费自托管 · 无订阅费',
      'hero.m2': '数据留在本地',
      'hero.m3': '无硬件绑定',
      'hero.m4': '手机与电脑都能用',
      'hero.note': '不想注册？先看界面演示（浏览器内模拟，无需登录）→',
      'hero.win': 'souse — 收租工作台 · 片区 12 栋',
      'hero.s1': '本月已收',
      'hero.s2': '待收',
      'hero.s3': '入住率',
      'hero.s4': '逾期',
      'hero.ok': '已收',
      'hero.due': '待收',
      'hero.bad': '逾期',
      'hero.free': '空置',
      'hero.auto.t': '自动规则 · 已执行',
      'hero.auto.m': 'A-202 逾期 3 天 → 断网 + 催缴已发',

      'feat.k': '能力',
      'feat.h2': '每天要处理的事，都在这里',
      'feat.d': '房态、账单、门禁、网络、水电共用同一份数据：改一处，其余同步，不重复录入。',
      'f.rent.t': '房态与收租',
      'f.rent.p': '这个月哪间已收、哪间待收、哪间逾期，打开就是一屏。收租、押金、旧账一次确认，不必逐条点。',
      'f.rent.tag': '房间 · 租客 · 收据 · 押金 · 自动规则',
      'f.flow1': '逾期 3 天',
      'f.flow2': '断网',
      'f.flow3': '断门禁',
      'f.flow4': '催缴通知',
      'f.access.t': '门禁与监控',
      'f.access.p': '对接海康门禁，开门走本地网络，外网断开也能开；退租即收回权限。接入大华录像机后，门口画面随时看，可按时间段回放。',
      'f.access.tag': '海康门禁 · 云眸备用 · 大华回放',
      'f.net.t': '房间网络',
      'f.net.p': '每间房的宽带账号自动写入路由（爱快、MikroTik）。欠费断网、缴费恢复；可按房间限速，或套用路由里的套餐。',
      'f.net.tag': '爱快 · MikroTik',
      'f.meter.t': '水电抄表',
      'f.meter.p': '拍一张表的照片，读数自动识别并进账单；历史读数可查，识别有误可人工补抄。',
      'f.meter.tag': '拍照识别 · 自动算费',
      'f.contract.t': '合同与押金',
      'f.contract.p': '合同生成、归档，续租、换房、退租全程留痕。退租时押金与水电一并结算，结算单生成一张图，直接发给住户。',
      'f.contract.tag': '电子合同 · 押金 · 结算单',
      'f.tenant.t': '住户手机页',
      'f.tenant.p': '房间贴一张二维码，微信扫码即用，不装 App：查账单、手机开门、充值、报修。',
      'f.tenant.tag': '微信扫码 · 免安装',
      'f.tenant.line': '<span class="p">住户 ›</span> 7-302 本月账单 <span class="u">¥1,860</span> · 手机开门 ✓ · 报修 #128 处理中',
      'f.ai.t': 'AI 管家',
      'f.ai.p': '一句话查欠费、下指令，例如「今天谁欠费」「把 A-202 断网」，执行结果直接返回。',
      'f.ai.line': '<span class="p">AI 管家 ›</span> 今天谁欠费 <span class="u">→ 2 间逾期 · 催缴已发送 · 已断 A-202 网络</span>',
      'feat.more': '另有：续租提醒 · 工单流转 · 服务公告 · 多楼栋',

      'arch.k': '结构',
      'arch.h2': '数据只有一份',
      'arch.d': '门禁、路由、水电表、住户手机与监控都接在同一个后台。主机可以是一台小主机、虚拟机或云服务器。',
      'arch.n1': '门口门禁',
      'arch.n1s': '刷卡 · 人脸 · 手机开门',
      'arch.n2': '房间网络',
      'arch.n2s': '欠费断网 · 缴费恢复',
      'arch.n3': '水表电表',
      'arch.n3s': '拍照识别 · 自动算费',
      'arch.n4': '监控画面',
      'arch.n4s': '随时看 · 能回放',
      'arch.n5': '住户手机',
      'arch.n5s': '查账 · 开门 · 报修',
      'arch.core.t': 'Souse 系统',
      'arch.core.s': '房态 · 账单 · 合同 · 自动规则',
      'arch.o1': '管理后台',
      'arch.o2': '住户手机页',
      'arch.o3': 'AI 管家',
      'arch.o4': '自动备份',

      'dep.k': '部署',
      'dep.h2': '装在自己的机器上',
      'dep.d': '下载安装包，双击，跟着向导走。程序、管理台、自动备份与开机自启一次装好，装完直接给出地址和初始密码。',
      'dep.win.t': 'Windows',
      'dep.win.d': '下载一个 exe，双击打开向导，选目录和端口就行。',
      'dep.win.btn': '下载 Windows 安装器（.exe）',
      'dep.win.n': '安装过程没有控制台窗口；首次运行若提示「已保护你的电脑」：更多信息 → 仍要运行。',
      'dep.mac.t': 'macOS',
      'dep.mac.d': '下载解压，双击「Souse 安装器」，全程系统对话框，不弹终端。',
      'dep.mac.btn': '下载 macOS 安装包',
      'dep.mac.n': '装好后从「应用程序」打开 Souse，是无地址栏的应用窗口。',
      'dep.lin.t': 'Linux / 小主机',
      'dep.lin.d': '服务器或 Linux 小主机用一条命令装好，由 systemd 托管。',
      'dep.lin.copy': '复制',
      'dep.lin.n': '服务：systemctl status souse（详见下载页）。',
      'dep.w1t': '设备账号只填一次',
      'dep.w1p': '路由、门禁、水表的地址与账号都在「系统设置」里，改完立即生效，无需重启。',
      'dep.w2t': '6 步向导配齐一栋楼，多栋照加',
      'dep.w2p': '楼栋、收款码、水电表、路由、门禁，按向导走完即可用；再加一栋，向导照走一遍就行。',
      'dep.w3t': '自动备份与自启',
      'dep.w3p': '每 6 小时备份一份，进程异常自动重启；外网访问走一条 Cloudflare 隧道。',

      'cmp.k': '对比',
      'cmp.h2': '与常见做法比',
      'cmp.d': '只比每天都会碰到的事：费用、欠费处理、住户入口、数据归属。',
      'cmp.c1': 'Excel + 微信群',
      'cmp.c2': '公寓 SaaS',
      'cmp.c3': 'Souse',
      'cmp.r1': '费用',
      'cmp.r2': '欠费处理',
      'cmp.r3': '住户入口',
      'cmp.r4': '数据与硬件',
      'cmp.r1c1': '免费，但对账靠人',
      'cmp.r1c2': '订阅费，多数绑自家硬件',
      'cmp.r1c3': '免费自托管',
      'cmp.r2c1': '人工催缴',
      'cmp.r2c2': '断电或锁门（绑硬件）',
      'cmp.r2c3': '断网与门禁，用现有路由 + 海康',
      'cmp.r3c1': '群里口头通知',
      'cmp.r3c2': '装 App 或关注公众号',
      'cmp.r3c3': '房间二维码，零安装',
      'cmp.r4c1': '在自己手里',
      'cmp.r4c2': '数据在平台云，硬件绑定',
      'cmp.r4c3': '数据在自己的机器上，不卖硬件、不经手租金',
      'cmp.close': '差别不在功能条数，而在商业结构：不卖硬件、不经手租金、数据留在你的机器上——这三条，平台型 SaaS 无法跟进。',

      'faq.k': '问题',
      'faq.h2': '常见问题',
      'faq.q1': '收费吗？',
      'faq.a1': '不收。免费自托管，装在自己的机器上，没有订阅费；不卖硬件，也不经手租金。',
      'faq.q2': '需要先买硬件吗？',
      'faq.a2': '不需要。已有设备能接就接：爱快、MikroTik 路由，海康门禁，大华录像机，水电表。没有门禁也能用：收租、账单、合同、押金、住户手机页一个不少。',
      'faq.q3': '数据放在哪里？',
      'faq.a3': '在你自己的机器上：家里的小主机、虚拟机或云服务器。系统每 6 小时自动备份一份，平台拿不到你的数据。',
      'faq.q4': '住户需要装 App 吗？',
      'faq.a4': '不需要。房间贴一张二维码，微信扫码进入网页版，查账单、开门、充值、报修都在里面。',
      'faq.q5': '怎么部署？升级会丢数据吗？',
      'faq.a5': 'Linux 一条命令（<code>install.sh</code>），需要 systemd；小主机、虚拟机、云服务器都行。升级只更换程序版本，数据留在原处，另有每 6 小时的备份兜底。',

      'cta.k': '开始',
      'cta.h2': '先从一栋楼试',
      'cta.p': '账号按房东开通，房源与住户数据各自隔离。想先看效果可以不登录，直接看界面演示。',
      'cta.b1': '登录 →',
      'cta.b2': '部署到自己机器',

      'foot.copy': '© 2026 Souse · 出租屋管理系统',
      'foot.status': 'souse.dpxon.com · 持续在线',
      'foot.try': '登录',
      'foot.github': 'GitHub',
      'foot.features': '能力',
      'foot.compare': '对比',
      'foot.faq': '常见问题',
      'foot.download': '下载',
      'foot.demo': '界面演示'
    },

    'yue': {
      'meta.title': 'Souse · 出租屋管理系统',
      'meta.desc': 'Souse 管出租屋同公寓：收租催缴、电子合同、门禁网络、水电抄表、住户手机页。免费自托管，装喺你自己部机度。',

      'nav.features': '功能',
      'nav.deploy': '部署',
      'nav.compare': '对比',
      'nav.faq': '常见问题',
      'nav.try': '登录',
      'nav.menu': '菜单',

      'hero.kicker': '自架 · 出租屋 / 公寓 / 民宿',
      'hero.h1': '一个片区，一套系统。<br><span class="grad">由签约管到退租。</span>',
      'hero.sub': '租金、合同、门禁、网络、水电共用同一份数据。先由一栋楼开始，加到成个片区都唔使换系统。欠费自动断网，交钱自动恢复。',
      'hero.cta1': '登录 →',
      'hero.cta2': '装喺自己部机度',
      'hero.m1': '免费自托管 · 冇订阅费',
      'hero.m2': '数据留喺本地',
      'hero.m3': '无硬件绑定',
      'hero.m4': '手机、电脑都用得',
      'hero.note': '唔想注册？先睇界面演示（浏览器内模拟，唔使登录）→',
      'hero.win': 'souse — 收租工作台 · 片区 12 栋',
      'hero.s1': '本月已收',
      'hero.s2': '待收',
      'hero.s3': '入住率',
      'hero.s4': '逾期',
      'hero.ok': '已收',
      'hero.due': '待收',
      'hero.bad': '逾期',
      'hero.free': '空置',
      'hero.auto.t': '自动规则 · 已执行',
      'hero.auto.m': 'A-202 逾期 3 日 → 断网 + 催缴已发',

      'feat.k': '功能',
      'feat.h2': '每日要处理嘅嘢，都喺呢度',
      'feat.d': '房态、账单、门禁、网络、水电共用同一份数据：改一处，其余跟住变，唔使重复入。',
      'f.rent.t': '房态与收租',
      'f.rent.p': '呢个月边间已收、边间待收、边间逾期，打开就一屏睇晒。收租、押金、旧账一次过确认，唔使逐条点。',
      'f.rent.tag': '房间 · 租客 · 收据 · 押金 · 自动规则',
      'f.flow1': '逾期 3 日',
      'f.flow2': '断网',
      'f.flow3': '断门禁',
      'f.flow4': '催缴通知',
      'f.access.t': '门禁与监控',
      'f.access.p': '对接海康门禁，开门走本地网络，外网断咗都开得；退租即刻收回权限。接埋大华录像机，门口画面随时睇，可以按时间段翻返录像。',
      'f.access.tag': '海康门禁 · 云眸备用 · 大华回放',
      'f.net.t': '房间网络',
      'f.net.p': '每间房嘅宽带账号自动写入路由（爱快、MikroTik）。欠费断网、交钱恢复；可以按房间限速，或者套用路由里面嘅套餐。',
      'f.net.tag': '爱快 · MikroTik',
      'f.meter.t': '水电抄表',
      'f.meter.p': '拍一张表嘅相，读数自动认出嚟直接入账单；历史读数查得返，认错咗可以人手补抄。',
      'f.meter.tag': '拍照识别 · 自动算费',
      'f.contract.t': '合同与押金',
      'f.contract.p': '合同生成、归档，续租、换房、退租全程有记录。退租时押金同水电一次过结算，结算单出一张图，直接发畀住户。',
      'f.contract.tag': '电子合同 · 押金 · 结算单',
      'f.tenant.t': '住户手机页',
      'f.tenant.p': '房间贴一张二维码，微信扫一扫就用，唔使装 App：查账单、手机开门、充值、报修。',
      'f.tenant.tag': '微信扫码 · 免安装',
      'f.tenant.line': '<span class="p">住户 ›</span> 7-302 本月账单 <span class="u">¥1,860</span> · 手机开门 ✓ · 报修 #128 处理中',
      'f.ai.t': 'AI 管家',
      'f.ai.p': '一句话查欠费、落指令，例如「今日边个欠费」「将 A-202 断网」，做完直接覆你。',
      'f.ai.line': '<span class="p">AI 管家 ›</span> 今日边个欠费 <span class="u">→ 2 间逾期 · 催缴已发 · 已断 A-202 网络</span>',
      'feat.more': '另外：续租提醒 · 工单流转 · 服务公告 · 多栋楼',

      'arch.k': '结构',
      'arch.h2': '数据只有一份',
      'arch.d': '门禁、路由、水电表、住户手机同监控都接喺同一个后台。主机可以系一部小主机、虚拟机或者一台云服务器。',
      'arch.n1': '门口门禁',
      'arch.n1s': '刷卡 · 人脸 · 手机开门',
      'arch.n2': '房间网络',
      'arch.n2s': '欠费断网 · 交钱恢复',
      'arch.n3': '水表电表',
      'arch.n3s': '拍照识别 · 自动算费',
      'arch.n4': '监控画面',
      'arch.n4s': '随时睇 · 有回放',
      'arch.n5': '住户手机',
      'arch.n5s': '查账 · 开门 · 报修',
      'arch.core.t': 'Souse 系统',
      'arch.core.s': '房态 · 账单 · 合同 · 自动规则',
      'arch.o1': '管理后台',
      'arch.o2': '住户手机页',
      'arch.o3': 'AI 管家',
      'arch.o4': '自动备份',

      'dep.k': '部署',
      'dep.h2': '装喺自己部机度',
      'dep.d': '下载安装包，双击，跟住向导行。程序、管理台、自动备份同开机自启一次装好，装完直接畀地址同初始密码。',
      'dep.win.t': 'Windows',
      'dep.win.d': '下载一个 exe，双击开向导，拣目录同端口就得。',
      'dep.win.btn': '下载 Windows 安装器（.exe）',
      'dep.win.n': '安装过程冇控制台窗口；第一次行如果弹「已保护你的电脑」：更多信息 → 仍要运行。',
      'dep.mac.t': 'macOS',
      'dep.mac.d': '下载解压，双击「Souse 安装器」，全程系统对话框，唔会弹终端。',
      'dep.mac.btn': '下载 macOS 安装包',
      'dep.mac.n': '装好之后喺「应用程序」开 Souse，就系无地址栏嘅应用窗口。',
      'dep.lin.t': 'Linux / 小主机',
      'dep.lin.d': '服务器或 Linux 小主机一条命令装好，由 systemd 托管。',
      'dep.lin.copy': '复制',
      'dep.lin.n': '服务：systemctl status souse（详情见下载页）。',
      'dep.w1t': '设备账号只填一次',
      'dep.w1p': '路由、门禁、水表嘅地址同账号都喺「系统设置」，改完即刻生效，唔使重启。',
      'dep.w2t': '6 步向导配齐一栋楼，多栋照加',
      'dep.w2p': '栋楼、收款码、水电表、路由、门禁，跟向导行完就用得；再加一栋，照行一次。',
      'dep.w3t': '自动备份同自启',
      'dep.w3p': '每 6 个钟备份一份，进程出事自动重启；外网访问走一条 Cloudflare 隧道。',

      'cmp.k': '对比',
      'cmp.h2': '同常见做法比',
      'cmp.d': '只比每日都撞到嘅事：费用、欠费处理、住户入口、数据归属。',
      'cmp.c1': 'Excel + 微信群',
      'cmp.c2': '公寓 SaaS',
      'cmp.c3': 'Souse',
      'cmp.r1': '费用',
      'cmp.r2': '欠费处理',
      'cmp.r3': '住户入口',
      'cmp.r4': '数据与硬件',
      'cmp.r1c1': '免费，但对账靠人',
      'cmp.r1c2': '订阅费，多数绑自家硬件',
      'cmp.r1c3': '免费自托管，自架',
      'cmp.r2c1': '人手催缴',
      'cmp.r2c2': '断电或锁门（绑硬件）',
      'cmp.r2c3': '断网同门禁，用返你现有嘅路由 + 海康',
      'cmp.r3c1': '群里面口头通知',
      'cmp.r3c2': '装 App 或关注公众号',
      'cmp.r3c3': '房间二维码，零安装',
      'cmp.r4c1': '喺自己手',
      'cmp.r4c2': '数据喺平台云，硬件绑定',
      'cmp.r4c3': '数据喺自己部机，唔卖硬件、唔经手租金',
      'cmp.close': '差别唔在功能条数，而喺商业结构：唔卖硬件、唔经手租金、数据留喺你部机——呢三条，平台型 SaaS 跟唔到。',

      'faq.k': '问题',
      'faq.h2': '常见问题',
      'faq.q1': '收唔收钱？',
      'faq.a1': '唔收。免费自托管，装喺自己部机，冇订阅费；唔卖硬件，亦都唔经手租金。',
      'faq.q2': '要唔要先买硬件？',
      'faq.a2': '唔使。现有嘅接得到就接：爱快、MikroTik 路由，海康门禁，大华录像机，水电表。冇门禁都用得：收租、账单、合同、押金、住户手机页一样唔少。',
      'faq.q3': '数据放喺边？',
      'faq.a3': '喺你自己部机：屋企小主机、虚拟机或者云服务器。系统每 6 个钟自动备份一份，平台攞唔到你嘅数据。',
      'faq.q4': '住户要唔要装 App？',
      'faq.a4': '唔使。房间贴一张二维码，微信扫一扫码入网页版，查账单、开门、充值、报修都喺里面。',
      'faq.q5': '点样部署？升级会唔会唔见数据？',
      'faq.a5': 'Linux 一条命令（<code>install.sh</code>），需要 systemd；小主机、虚拟机、云服务器都得。升级只系换程序版本，数据留喺原处，另外每 6 个钟有备份。',

      'cta.k': '开始',
      'cta.h2': '先由一栋楼试下',
      'cta.p': '账号按房东开通，房源同住户资料各自隔离。想先睇效果可以唔登录，直接睇界面演示。',
      'cta.b1': '登录 →',
      'cta.b2': '装喺自己部机度',

      'foot.copy': '© 2026 Souse · 出租屋管理系统',
      'foot.status': 'souse.dpxon.com · 持续在线',
      'foot.try': '登录',
      'foot.github': 'GitHub',
      'foot.features': '功能',
      'foot.compare': '对比',
      'foot.faq': '常见问题',
      'foot.download': '下载',
      'foot.demo': '界面演示'
    },

    'en': {
      'meta.title': 'Souse · Rental property management, self-hosted',
      'meta.desc': 'Souse runs rentals and apartment buildings: rent collection, contracts, door access, room networks, meter reading and a tenant mobile page. Free self-hosted, deployed on your own machine.',

      'nav.features': 'Features',
      'nav.deploy': 'Deploy',
      'nav.compare': 'Compare',
      'nav.faq': 'FAQ',
      'nav.try': 'Sign in',
      'nav.menu': 'Menu',

      'hero.kicker': 'Self-hosted · Rentals · Apartments',
      'hero.h1': 'One district.<br><span class="grad">One system, end to end.</span>',
      'hero.sub': 'Rent, leases, door access, Wi-Fi and utilities share one dataset. Start with a single building; add the rest of the district without changing systems. Overdue rent cuts the network; payment restores it.',
      'hero.cta1': 'Sign in →',
      'hero.cta2': 'Deploy on your machine',
      'hero.m1': 'Free self-hosted · no subscription',
      'hero.m2': 'Data stays local',
      'hero.m3': 'No vendor hardware',
      'hero.m4': 'Phone and desktop',
      'hero.note': 'Not ready to sign up? Try the interface demo (generated in the browser, no login) →',
      'hero.win': 'souse — rent desk · 12 buildings',
      'hero.s1': 'Collected',
      'hero.s2': 'Pending',
      'hero.s3': 'Occupancy',
      'hero.s4': 'Overdue',
      'hero.ok': 'Paid',
      'hero.due': 'Due',
      'hero.bad': 'Overdue',
      'hero.free': 'Vacant',
      'hero.auto.t': 'Rule · executed',
      'hero.auto.m': 'A-202 overdue 3 days → network off + reminder sent',

      'feat.k': 'Features',
      'feat.h2': 'Everything you deal with daily, in one place',
      'feat.d': 'Occupancy, invoices, door access, network and utilities share one dataset: change it once and everything follows. Nothing is entered twice.',
      'f.rent.t': 'Occupancy and rent',
      'f.rent.p': 'Which rooms are paid, pending or overdue this month, on one screen. Confirm rent, deposit and arrears together instead of one by one.',
      'f.rent.tag': 'Rooms · tenants · receipts · deposits · rules',
      'f.flow1': 'Overdue 3 days',
      'f.flow2': 'Network off',
      'f.flow3': 'Access off',
      'f.flow4': 'Reminder sent',
      'f.access.t': 'Access and cameras',
      'f.access.p': 'Hikvision door controllers run over the local network, so doors still open when the internet is down; permissions are revoked on move-out. Dahua recorders add live view and playback by time range.',
      'f.access.tag': 'Hikvision · cloud fallback · Dahua playback',
      'f.net.t': 'Room network',
      'f.net.p': 'Each room\'s broadband account is provisioned on the router (iKuai, MikroTik). Overdue rent cuts that room; payment restores it. Rate limits can be set per room or inherited from a router plan.',
      'f.net.tag': 'iKuai · MikroTik',
      'f.meter.t': 'Meter reading',
      'f.meter.p': 'Photograph the meter and the reading is recognised and billed automatically. History is kept, and a wrong reading can be corrected by hand.',
      'f.meter.tag': 'OCR · automatic billing',
      'f.contract.t': 'Contracts and deposits',
      'f.contract.p': 'Contracts are generated and archived; renewals, room changes and move-outs are all logged. Deposits and utilities settle into a single statement image you can send to the tenant.',
      'f.contract.tag': 'Contracts · deposits · statements',
      'f.tenant.t': 'Tenant mobile page',
      'f.tenant.p': 'A QR code on the door opens a WeChat web page, no app install: bills, phone unlock, top-ups and repair requests.',
      'f.tenant.tag': 'WeChat · nothing to install',
      'f.tenant.line': '<span class="p">Tenant ›</span> 7-302 bill <span class="u">¥1,860</span> · door unlocked ✓ · repair #128 in progress',
      'f.ai.t': 'AI assistant',
      'f.ai.p': 'Ask in plain language — who is overdue today, cut A-202 off — and it executes, then reports back.',
      'f.ai.line': '<span class="p">AI ›</span> who is overdue today <span class="u">→ 2 overdue · reminders sent · A-202 network off</span>',
      'feat.more': 'Also: renewal reminders · work orders · notices · multiple buildings',

      'arch.k': 'Architecture',
      'arch.h2': 'One copy of the data',
      'arch.d': 'Door controllers, routers, meters, tenant phones and cameras all connect to the same backend. The host can be a mini-PC, a VM or a cloud server.',
      'arch.n1': 'Door access',
      'arch.n1s': 'card · face · phone',
      'arch.n2': 'Room network',
      'arch.n2s': 'cut on arrears · restore on payment',
      'arch.n3': 'Water and power',
      'arch.n3s': 'OCR · automatic billing',
      'arch.n4': 'Cameras',
      'arch.n4s': 'live · playback',
      'arch.n5': 'Tenant phone',
      'arch.n5s': 'bills · unlock · repairs',
      'arch.core.t': 'Souse',
      'arch.core.s': 'occupancy · invoices · contracts · rules',
      'arch.o1': 'Admin console',
      'arch.o2': 'Tenant page',
      'arch.o3': 'AI assistant',
      'arch.o4': 'Auto backup',

      'dep.k': 'Deploy',
      'dep.h2': 'Run it on your own machine',
      'dep.d': 'Download the installer, double-click, follow the wizard. App, console, automatic backups and boot startup install in one pass, then it prints the address and the initial password.',
      'dep.win.t': 'Windows',
      'dep.win.d': 'Download one exe, double-click it, pick a folder and port in the wizard.',
      'dep.win.btn': 'Download for Windows (.exe)',
      'dep.win.n': "No console window at any point. If Windows says 'Windows protected your PC': More info → Run anyway.",
      'dep.mac.t': 'macOS',
      'dep.mac.d': 'Unzip and double-click the installer; native dialogs only, no terminal.',
      'dep.mac.btn': 'Download for macOS',
      'dep.mac.n': 'Open Souse from Applications afterwards: a window without an address bar.',
      'dep.lin.t': 'Linux / 小主机',
      'dep.lin.d': 'One command on a server or Linux mini-PC; managed by systemd.',
      'dep.lin.copy': 'Copy',
      'dep.lin.n': 'Service: systemctl status souse (see the download page).',
      'dep.w1t': 'Device credentials, entered once',
      'dep.w1p': 'Router, door controller and meter addresses live in Settings and take effect immediately, with no restart.',
      'dep.w2t': 'Six steps per building, repeat for the rest',
      'dep.w2p': 'Building, payment QR, meters, router, door controller: follow the wizard once and it is ready. Add another building the same way.',
      'dep.w3t': 'Backups and self-healing',
      'dep.w3p': 'A backup every 6 hours, automatic restarts on failure, and a Cloudflare tunnel for remote access.',

      'cmp.k': 'Compare',
      'cmp.h2': 'Compared with the usual options',
      'cmp.d': 'Only the things you deal with daily: cost, overdue rent, how tenants get in, and who owns the data.',
      'cmp.c1': 'Excel + group chat',
      'cmp.c2': 'Apartment SaaS',
      'cmp.c3': 'Souse',
      'cmp.r1': 'Cost',
      'cmp.r2': 'Overdue rent',
      'cmp.r3': 'Tenant entry',
      'cmp.r4': 'Data and hardware',
      'cmp.r1c1': 'Free, but reconciliation is manual',
      'cmp.r1c2': 'Subscription, usually tied to their hardware',
      'cmp.r1c3': 'Free self-hosted',
      'cmp.r2c1': 'Manual reminders',
      'cmp.r2c2': 'Power or door lock cut, hardware-bound',
      'cmp.r2c3': 'Network and door access, on your routers and Hikvision',
      'cmp.r3c1': 'Word of mouth in a group chat',
      'cmp.r3c2': 'Install an app or follow an account',
      'cmp.r3c3': 'QR code, nothing to install',
      'cmp.r4c1': 'In your hands',
      'cmp.r4c2': 'In the vendor cloud, hardware lock-in',
      'cmp.r4c3': 'On your machine; no hardware sales, no handling of rent',
      'cmp.close': 'The difference is not the feature list but the commercial structure: no hardware sales, no handling of your rent, and your data on your own machine. Platform SaaS cannot match that.',

      'faq.k': 'FAQ',
      'faq.h2': 'Common questions',
      'faq.q1': 'Does it cost anything?',
      'faq.a1': 'No. Free and self-hosted, with no subscription fee. We sell no hardware and never touch your rent.',
      'faq.q2': 'Do I need to buy hardware first?',
      'faq.a2': 'No. Connect what you already run: iKuai or MikroTik routers, Hikvision door controllers, Dahua recorders, water and power meters. Without a door controller it still works: rent, invoices, contracts, deposits and the tenant page are all there.',
      'faq.q3': 'Where does the data live?',
      'faq.a3': 'On your machine: a mini-PC at home, a VM or your own cloud server. Backups run every 6 hours, and we never see your data.',
      'faq.q4': 'Do tenants need an app?',
      'faq.a4': 'No. A QR code on the door opens a web page in WeChat: bills, door unlock, top-ups and repair requests.',
      'faq.q5': 'How do I deploy it, and will upgrades lose data?',
      'faq.a5': 'One command on Linux (<code>install.sh</code>), systemd required; a mini-PC, a VM and a cloud server all work. Upgrades swap the program version, the data stays where it is, and the 6-hour backup is the safety net.',

      'cta.k': 'Start',
      'cta.h2': 'Start with a single building',
      'cta.p': 'Accounts are provisioned per landlord; properties and residents stay isolated. Preview the interface without signing in.',
      'cta.b1': 'Sign in →',
      'cta.b2': 'Deploy on your machine',

      'foot.copy': '© 2026 Souse · Rental property management',
      'foot.status': 'souse.dpxon.com · online',
      'foot.try': 'Sign in',
      'foot.github': 'GitHub',
      'foot.features': 'Features',
      'foot.compare': 'Compare',
      'foot.faq': 'FAQ',
      'foot.download': 'Download',
      'foot.demo': 'Interface demo'
    }
  };

  var ORDER = ['zh-Hans', 'yue', 'en'];
  var LANG_ATTR = {'zh-Hans': 'zh-CN', 'yue': 'zh-HK', 'en': 'en'};
  var LABEL = {'zh-Hans': '简', 'yue': '粵', 'en': 'EN'};
  var STORE = 'souse-lang';
  var cur = 'zh-Hans';

  function pick() {
    var saved = null;
    try { saved = localStorage.getItem(STORE); } catch (e) {}
    if (saved && D[saved]) return saved;
    var nav = (navigator.languages && navigator.languages[0]) || navigator.language || 'zh-CN';
    nav = nav.toLowerCase();
    if (nav.indexOf('yue') === 0 || nav === 'zh-hk' || nav === 'zh-mo') return 'yue';
    if (nav.indexOf('zh') === 0) return 'zh-Hans';
    return 'en';
  }

  function apply(code) {
    if (!D[code]) return;
    cur = code;
    var dict = D[code];
    var nodes = document.querySelectorAll('[data-i18n],[data-i18n-html]');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      var k = el.getAttribute('data-i18n');
      if (k) {
        if (dict[k] != null) el.textContent = dict[k];
        else if (window.console) console.warn('[i18n] missing', code, k);
        continue;
      }
      k = el.getAttribute('data-i18n-html');
      if (k) {
        if (dict[k] != null) el.innerHTML = dict[k];
        else if (window.console) console.warn('[i18n] missing', code, k);
      }
    }
    // 标题 / 描述 / OG
    if (dict['meta.title']) document.title = dict['meta.title'];
    var pairs = [['meta[name=description]', 'meta.desc'], ['meta[property="og:title"]', 'meta.title'],
      ['meta[property="og:description"]', 'meta.desc'], ['meta[name="twitter:title"]', 'meta.title'],
      ['meta[name="twitter:description"]', 'meta.desc']];
    pairs.forEach(function (p) {
      var el = document.querySelector(p[0]);
      if (el && dict[p[1]]) el.setAttribute('content', dict[p[1]]);
    });
    var ogLocale = document.querySelector('meta[property="og:locale"]');
    if (ogLocale) ogLocale.setAttribute('content', code === 'en' ? 'en_US' : (code === 'yue' ? 'zh_HK' : 'zh_CN'));
    document.documentElement.lang = LANG_ATTR[code] || 'zh-CN';
    document.documentElement.setAttribute('data-lang', code);
    var btns = document.querySelectorAll('[data-lang]');
    for (var j = 0; j < btns.length; j++) btns[j].classList.toggle('on', btns[j].getAttribute('data-lang') === code);
    try { localStorage.setItem(STORE, code); } catch (e) {}
  }

  function set(code) { if (D[code]) apply(code); }

  window.SouseI18N = {
    dict: D, order: ORDER, label: LABEL, set: set, current: function () { return cur; }
  };

  // 尽早确定语言，避免首屏闪一次
  function boot() {
    apply(pick());
    var btns = document.querySelectorAll('[data-lang]');
    for (var i = 0; i < btns.length; i++) {
      btns[i].addEventListener('click', function () { set(this.getAttribute('data-lang')); });
    }
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
