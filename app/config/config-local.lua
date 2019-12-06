local whitelist = require('app.config.whitelist')

return {
	-- 白名單配置：不需要登錄即可訪問；除非要二次開發，否則不應更改

	whitelist = whitelist,

	-- 靜態模板配置，保持默認不修改即可
	view_config = {
		engine = "tmpl",
		ext = "html",
		views = "./app/views"
	},

	-- 分頁時每頁條數配置
	page_config = {
		index_topic_page_size = 10, -- 首頁每頁文章數
		topic_comment_page_size = 20, -- 文章詳情頁每頁評論數
		notification_page_size = 10, -- 通知每頁個數
	},

	-- ########################## 以下配置需要使用者自定義爲本地需要的配置 ########################## --

	advanced_filter={
		-- 時間顆粒度
		time_dimension = {
			day = "天",
			week = "周",
			month = "月",
			quarter = "季度",
			year = "年"
		},
		-- 條件範圍
		condition_range = {
			eq = "等於",
			en = "不等於",
			ge = "大於等於",
			gt = "大於",
			le = "小於等於",
			lt = "小於"
		},
		-- 邏輯符號
		logical_symbol = {
			land = "與",
			lor = "或",
			lnot = "非",
			lno = "無"
		},
	},
	-- app訪問超級token
	app_root_token = "2b5c2d36fc41358c299f9230d8a15e501b45f1b473c0cbacb54afa7bdc03e800",

  	-- 是否可以跨域
	allow_cross_domain = true,


	-- mysql配置
	mysql = {
		timeout = 120000,
		connect_config = {
			host = "127.0.0.1",
	        port = 3306,
	        database = "sf_devel",
	        user = "danny",
	        password = "yadmin8",
	        max_packet_size = 1024 * 1024
		},
		pool_config = {
			max_idle_timeout = 20000, -- 20s
        	pool_size = 50 -- connection pool size
		}
	},
	
	smtp_sv = {
		timeout = 5000,
		url = "http://10.132.241.214:6666/mail",
	},

	sms_sv = {
		timeout = 5000,
		url = "http://127.0.0.1:5555"
	},

	server_self = {
		url = "http://127.0.0.1:8888",
	},

	redis = {

		timeout = 1000,

		connect_config = {
			host = "127.0.0.1",
			port = 6379
		},
		pool_config = {
			max_idle_timeout = 20000, -- 20s
        	pool_size = 50 -- connection pool size
		}
	},

	approval_inv_setting = {
		publish = 2*60*60
	},

	websocket = {
		timeout = 1000,  -- in milliseconds
    	max_payload_len = 65535
    },

	eval_scripts = {
		path = "/opt/vssas/app/vsws/eval_script"
	},
	-- 上傳文件配置，如上傳的頭像、文章中的圖片等
	upload_config = {
		dir = "/opt/vssas/app/static/images/layout", -- 文件目錄，修改此值時須同時修改nginx配置文件中的$static_files_path值
	--	dir = "/home/miah/dev/vssas/app/static/images/layout",  --miah
		path = "/static/images/layout",
	},
	download_files= {
		dir = "/opt/vssas/app/static",
		path = '/static'
	},
	upload_files = {
		dir = "/opt/vssas/app/static/files", -- 文件目錄，修改此值時須同時修改nginx配置文件中的$static_files_path值
	--	dir = "/home/miah/dev/vssas/app/static/images/layout",  --miah
		path = "/static/files",
	},

	emp_photo_config = {
		dir = "/opt/vssas/app/static/images/emp_photo",  -- 前段上傳路徑
		path = "/static/images/emp_photo",  --
		default = "/static/images/avatar.png",
	},

	local_emp_photo_config = {
		dir = "/opt/vssas/app/static/images/emp",
		path = "/static/images/emp",
		default = "/static/images/avatar.png",
	},

	logo_pdf_path = {
		dir = "/opt/vssas/app/static/images/logo.pdf"
	},

	menu = {
		group = {
            {id = "ssas03",
                name = "概況" ,
                icon = "icon-dashboard",
                page = "welcome",
                order_item = 1,
                project_code = "SYS"
            },
		},
		project = "智能工廠系統"
			},
	permission_change_key = {
		key_prefix = "permission-change-"
	},
	no_lucky = {
		'F2846970'
	}
}
