library(shiny)
library(bslib)
library(shinythemes)
library(jsonlite)
library(httr2)
library(readr)
library(stringr)
library(dplyr)
library(commonmark)

# Expose project root as static assets so the opening video can be served
shiny::addResourcePath("static", getwd())

# Utility to read corpus from uploaded file or bundled excerpt
read_corpus <- function(uploaded_path = NULL, max_chars = 20000) {
  if (!is.null(uploaded_path) && file.exists(uploaded_path)) {
    text <- readr::read_file(uploaded_path)
  } else {
    bundled <- file.path(getwd(), "data", "huangdi_neijing_excerpt.txt")
    if (file.exists(bundled)) {
      text <- readr::read_file(bundled)
    } else {
      text <- ""
    }
  }
  if (nchar(text) > max_chars) substr(text, 1, max_chars) else text
}

# Compose structured profile text from inputs
compose_profile <- function(input) {
  glue_text <- sprintf(
    paste(
      "年龄: %s; 性别: %s; 地区: %s;",
      "压力评分: %s/10; 睡眠: %s; 运动: %s; 饮食: %s;",
      "症状/关注: %s"),
    input$age, input$sex, input$region,
    input$stress, input$sleep, input$activity, input$diet,
    ifelse(nchar(input$symptoms %||% "") > 0, input$symptoms, "无"))
  glue_text
}

`%||%` <- function(a, b) if (!is.null(a)) a else b

# Call OpenAI Chat Completions API
call_openai <- function(system_prompt, user_prompt, model = Sys.getenv("OPENAI_MODEL", "gpt-4o-mini")) {
  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (identical(api_key, "")) {
    stop("OPENAI_API_KEY is not set.")
  }
  base_url <- Sys.getenv("OPENAI_BASE_URL", "https://api.openai.com")

  req <- httr2::request(paste0(base_url, "/v1/chat/completions")) |>
    req_headers(Authorization = paste("Bearer", api_key)) |>
    req_body_json(list(
      model = model,
      temperature = 0.7,
      messages = list(
        list(role = "system", content = system_prompt),
        list(role = "user", content = user_prompt)
      )
    ), auto_unbox = TRUE)

  resp <- req_perform(req)
  body <- resp_body_json(resp, simplifyVector = TRUE)
  body$choices[[1]]$message$content
}

app_theme <- bs_theme(bootswatch = "cosmo")

ui <- page_sidebar(
  theme = app_theme,
  title = "黄帝内经 · 体质与养生问答",
  sidebar = sidebar(
    width = 350,
    sliderInput("age", "年龄", min = 1, max = 100, value = 30),
    selectInput("sex", "性别", c("女性", "男性", "其他"), selected = "女性"),
    selectInput("region", "地区", c(
      "华北", "华东", "华南", "西南", "东北", "西北",
      "东亚", "东南亚", "欧洲", "北美", "南美", "非洲", "大洋洲"
    ), selected = "东亚"),
    sliderInput("stress", "压力(0-10)", min = 0, max = 10, value = 5),
    selectInput("sleep", "睡眠情况", c("良好", "一般", "欠佳"), selected = "一般"),
    selectInput("activity", "运动水平", c("高", "中", "低"), selected = "中"),
    selectInput("diet", "饮食偏好", c("清淡", "均衡", "偏油腻", "素食", "外食为主"), selected = "均衡"),
    textInput("symptoms", "症状/主要关注(可选)", placeholder = "如：容易疲劳、失眠、胃胀等"),
    textAreaInput("question", "请描述你的健康问题或目标", rows = 4,
                  placeholder = "例如：近期压力大、睡眠差，如何调养？"),
    fileInput("corpus", "上传《黄帝内经》全文(.txt，选填)", accept = ".txt"),
    actionButton("generate", "生成建议", class = "btn-primary")
  ),
  # Opening animation video (looping, muted, autoplay)
  card(
    tags$video(
      src = "static/openingvideo.mp4",
      autoplay = NA,
      loop = NA,
      muted = NA,
      playsinline = NA,
      preload = "auto",
      style = "width: 100%; height: auto; border-radius: 8px;"
    )
  ),
  card(
    card_header("答复"),
    uiOutput("answer"),
    uiOutput("error", placeholder = TRUE)
  ),
  card(
    card_header("说明"),
    markdown("本应用为健康信息参考，不替代专业医疗建议。如有急重症状，请及时就医。")
  )
)

server <- function(input, output, session) {
  answer_text <- eventReactive(input$generate, {
    profile <- compose_profile(input)
    question <- input$question %||% ""
    corpus_path <- if (!is.null(input$corpus)) input$corpus$datapath else NULL
    corpus <- read_corpus(corpus_path)

    if (identical(question, "")) {
      return("请先描述你的健康问题或目标。")
    }

    system_prompt <- paste(
      "你是《黄帝内经》的作者，同时也是著名老中医。",
      "请以中文作答，语气温暖、同理、简洁。",
      "请严格按以下结构输出：\n",
      "一、原文引述：从提供的《黄帝内经》语料中择要引用（标明篇名/句段）。\n",
      "二、白话译文：对上述原文进行现代汉语翻译，力求清晰易懂。\n",
      "三、个性化建议：结合提问者的年龄、性别、地区、压力、作息等情况，给出可实施的起居、饮食、情志与运动建议，并提示风险与何时就医。",
      sep = " "
    )

    context_header <- "以下为《黄帝内经》语料片段（可能非全文，供参考）：\n\n"
    user_prompt <- paste0(
      context_header,
      corpus,
      "\n\n---\n",
      "提问者资料：", profile, "\n",
      "问题：", question, "\n\n",
      "请基于上述语料优先作答；若语料未涵盖，也可根据《黄帝内经》的思想体系进行推演，但请明确指出‘语料未直接收录’。"
    )

    tryCatch({
      call_openai(system_prompt, user_prompt)
    }, error = function(e) {
      paste0("调用模型失败：", e$message, "。请确认已配置 OPENAI_API_KEY 并稍后重试。")
    })
  })

  output$answer <- renderUI({
    req(answer_text())
    HTML(commonmark::markdown_html(answer_text()))
  })

  output$error <- renderUI({ NULL })
}

shinyApp(ui, server)