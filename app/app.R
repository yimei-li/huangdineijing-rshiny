library(shiny)

# Resolve project root for assets (works whether app runs from root or app/)
resolve_project_root <- function() {
	wd <- getwd()
	# If openingvideo.mp4 exists here, we are at project root
	if (file.exists(file.path(wd, "openingvideo.mp4"))) {
		return(wd)
	}
	# Otherwise, try parent directory (common when app/ subdir is the working dir)
	parent_dir <- normalizePath(file.path(wd, ".."), mustWork = FALSE)
	return(parent_dir)
}

project_root <- resolve_project_root()
addResourcePath(prefix = "assets", directoryPath = project_root)
video_src <- "assets/openingvideo.mp4"

# Prefer Railway PORT if provided
options(
	shiny.host = "0.0.0.0",
	shiny.port = as.numeric(Sys.getenv("PORT", unset = "3838"))
)

# API key placeholder (no key yet)
llm_api_key <- Sys.getenv("LLM_API_KEY", unset = "待定")

ui <- fluidPage(
	tags$head(
		tags$meta(charset = "utf-8"),
		tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
		tags$title("黄帝内经 · 个性化健康建议"),
		tags$style(HTML(
			"body { background-color: #fafafa; }\n\n\n.sidebar { background: #ffffff; border-right: 1px solid #e9ecef; }\n\n\n.section-title { margin-top: 0.5rem; margin-bottom: 0.75rem; font-weight: 600; }\n\n\n.helper { color: #6c757d; font-size: 0.9rem; }\n\n\n#answer { background: #ffffff; border: 1px solid #e9ecef; border-radius: 8px; padding: 16px; }\n\n\nblockquote { border-left: 4px solid #f0ad4e; padding-left: 12px; color: #555; }\n\n\n.modal-video { width: 100%; height: auto; border-radius: 8px; }\n\n\n@media (min-width: 992px) {\n  .concern-row { display: grid; grid-template-rows: auto 1fr; gap: 12px; }\n}\n"
		))
	),

	sidebarLayout(
		sidebarPanel(
			div(class = "sidebar",
				h3("个性化信息"),
				selectInput(
					"region", "地区",
					choices = c(
						"中国大陆", "港澳台", "东亚其他", "东南亚", "南亚", "欧洲", "北美", "南美",
						"非洲", "中东", "大洋洲"
					),
					selected = "中国大陆"
				),
				sliderInput("age", "年龄", min = 0, max = 100, value = 30, step = 1),
				radioButtons("gender", "性别", inline = TRUE,
					choices = c("女", "男", "不便透露"), selected = "不便透露"
				),
				sliderInput("stress", "近期压力 (0-10)", min = 0, max = 10, value = 4),
				checkboxGroupInput(
					"lifestyle", "生活方式",
					choices = c("久坐", "熬夜", "吸烟", "饮酒", "规律运动", "素食/清淡"),
					selected = c("久坐", "熬夜")
				),
				checkboxGroupInput(
					"conditions", "慢性/既往状况",
					choices = c("高血压", "糖尿病", "高血脂", "胃肠易激", "过敏体质", "甲状腺问题", "焦虑/抑郁"),
					selected = NULL
				),
				actionButton("generate", "生成建议", class = "btn btn-primary"),
				div(class = "helper", style = "margin-top:8px;",
					HTML(sprintf("当前大模型 API 密钥：<b>%s</b>（未配置时为“待定”）", htmltools::htmlEscape(llm_api_key)))
				)
			)
			, width = 4
		),
		mainPanel(
			div(class = "concern-row",
				div(
					div(class = "section-title", "健康关注点（可具体描述）"),
					textAreaInput(
						"concern", label = NULL, width = "100%", height = "140px",
						placeholder = paste(
							"示例：睡眠困难/早醒；长期疲劳；胃肠不适；眼睛干涩；鼻过敏；",
							"经期不调；术后/肿瘤康复调理；季节交替容易感冒等"
						)
					),
					helpText("提示：尽量描述起止时间、诱因、伴随症状、昼夜/季节规律。")
				),
				div(
					div(class = "section-title", "《黄帝内经》风格的个性化建议"),
					div(id = "answer", uiOutput("answer_ui"))
				)
			)
			, width = 8
		)
	)
)

server <- function(input, output, session) {
	# Startup modal with looping video
	observe({
		showModal(modalDialog(
			size = "l",
			title = HTML("<b>欢迎进入 · 黄帝内经 健康顾问</b>"),
			tags$video(
				src = video_src, type = "video/mp4",
				autoplay = NA, muted = NA, loop = NA, controls = NA,
				class = "modal-video"
			),
			detail = NULL,
			easyClose = TRUE,
			footer = tagList(
				modalButton("进入应用")
			)
		))
	}, once = TRUE)

	# Attempt to load Huangdi Neijing full text if present (optional)
	load_neijing <- function() {
		cand <- file.path(project_root, "data", "huangdi_neijing_full.txt")
		if (file.exists(cand)) {
			return(paste(readLines(cand, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
		}
		return(NULL)
	}

	neijing_text <- load_neijing()

	# Build LLM prompt from inputs (will be used once API is configured)
	build_prompt <- function() {
		personal <- list(
			地区 = input$region,
			年龄 = input$age,
			性别 = input$gender,
			压力 = input$stress,
			生活方式 = if (length(input$lifestyle)) paste(input$lifestyle, collapse = "、") else "未填写",
			既往状况 = if (length(input$conditions)) paste(input$conditions, collapse = "、") else "未填写",
			关注点 = if (nzchar(input$concern)) input$concern else "未填写"
		)

		persona <- paste0(
			"你是《黄帝内经》的作者，同时也是著名老中医。",
			"阅读我给你的黄帝内经全文，深度思考，根据《黄帝内经》的思维方式和口吻，",
			"回答我后面给你的健康问题。回答的时候，请你给我《黄帝内经》的原文、翻译、",
			"以及根据个人情况的个性化回答，请你的回答具有同理心、简洁、让读者看了心里感觉到温暖、舒服。"
		)

		context <- if (!is.null(neijing_text)) substr(neijing_text, 1L, 200000L) else "（未提供全文，后续可补充）"

		paste0(
			persona, "\n\n",
			"【用户信息】\n", paste0(names(personal), ": ", unlist(personal), collapse = "\n"), "\n\n",
			"【参考语料】\n", context, "\n\n",
			"【请输出格式】\n",
			"1) 原文：\n2) 翻译：\n3) 个性化建议：\n"
		)
	}

	# Placeholder LLM call (returns structured demo when key is not configured)
	generate_advice <- function() {
		prompt <- build_prompt()
		using_placeholder <- (identical(llm_api_key, "待定") || !nzchar(llm_api_key))

		if (using_placeholder) {
			# Demo content inspired by Huangdi Neijing style
			orig <- paste(
				"早卧早起，与鸡俱兴。虚邪贼风，避之有时。",
				"食饮有节，起居有常，不妄作劳。"
			)
			tran <- paste(
				"顺应昼夜，早睡早起；在气候失常时学会避寒避风；",
				"饮食有度、作息规律，不过度透支精力。"
			)
			personalized <- paste0(
				"结合您的情况（", input$region, "；", input$age, "岁；", input$gender, "；压力 ", input$stress, "/10），",
				if (length(input$lifestyle)) paste0("生活方式：", paste(input$lifestyle, collapse = "、"), "；") else "",
				if (length(input$conditions)) paste0("既往：", paste(input$conditions, collapse = "、"), "；") else "",
				if (nzchar(input$concern)) paste0("关注点：", input$concern, "。") else "",
				"建议从作息、情志与饮食三方面先行微调：\n",
				"- 作息：建议在23:00前入睡，晨起适度舒展，周末补足自然光照。\n",
				"- 情志：每日安排10-15分钟缓和步行或呼吸放松，先稳心气。\n",
				"- 饮食：温热清淡为主，七分饱；少辛辣酒咖；晚餐提前至睡前≥3小时。\n",
				"若症状持续或加重，请及时线下就医评估。"
			)

			return(list(original = orig, translation = tran, personalized = personalized, from = "placeholder"))
		}

		# TODO: When LLM key is available, call the provider here.
		# For now, fall back to placeholder to ensure app runs.
		return(list(
			original = "（待接入大模型 API 后返回原文段落）",
			translation = "（待接入大模型 API 后返回对应现代文翻译）",
			personalized = "（待接入大模型 API 后结合个体信息生成建议）",
			from = "no-key"
		))
	}

	render_answer_html <- function(res) {
		HTML(paste0(
			"<div>",
			"<div style='margin-bottom:8px'><span class='badge bg-warning text-dark'>原文</span></div>",
			"<blockquote>", htmltools::htmlEscape(res$original), "</blockquote>",
			"<div style='margin-bottom:8px'><span class='badge bg-success'>翻译</span></div>",
			"<div>", htmltools::htmlEscape(res$translation), "</div>",
			"<div style='margin:12px 0 8px'><span class='badge bg-primary'>个性化建议</span></div>",
			"<div>", htmltools::htmlEscape(res$personalized), "</div>",
			"</div>"
		))
	}

	observeEvent(input$generate, {
		res <- generate_advice()
		output$answer_ui <- renderUI({ render_answer_html(res) })
	}, ignoreInit = TRUE)

	# Initialize with empty content
	output$answer_ui <- renderUI({
		HTML("<div class='helper'>请在右上方填写健康关注点，并点击“生成建议”。</div>")
	})
}

shinyApp(ui, server)


