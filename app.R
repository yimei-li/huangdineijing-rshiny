library(shiny)

# API key placeholder
llm_api_key <- Sys.getenv("LLM_API_KEY", unset = "待定")

# UI
ui <- fluidPage(
  tags$head(
    tags$meta(charset = "UTF-8"),
    tags$title("黄帝内经 · 健康建议"),
    tags$style(HTML("
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background: #f5f5f5; }
      .main-container { max-width: 1400px; margin: 0 auto; padding: 20px; }
      .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; text-align: center; }
      .input-panel { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
      .output-panel { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); min-height: 400px; }
      .section-title { font-size: 18px; font-weight: 600; color: #333; margin-bottom: 15px; border-left: 4px solid #667eea; padding-left: 12px; }
      .generate-btn { background: #667eea; color: white; border: none; padding: 12px 30px; border-radius: 6px; font-size: 16px; font-weight: 600; cursor: pointer; width: 100%; margin-top: 20px; }
      .generate-btn:hover { background: #5568d3; }
      .advice-box { background: #f8f9fa; border-left: 4px solid #f0ad4e; padding: 15px; margin: 15px 0; border-radius: 4px; }
      .original-text { color: #8b4513; font-style: italic; line-height: 1.8; }
      .translation-text { color: #2c5282; line-height: 1.8; margin: 10px 0; }
      .personalized-text { color: #2d3748; line-height: 1.8; }
      .badge { display: inline-block; padding: 4px 12px; border-radius: 4px; font-size: 14px; font-weight: 600; margin-bottom: 10px; }
      .badge-warning { background: #ffc107; color: #000; }
      .badge-success { background: #28a745; color: white; }
      .badge-primary { background: #667eea; color: white; }
      .api-status { font-size: 13px; color: #666; margin-top: 15px; padding: 10px; background: #f8f9fa; border-radius: 4px; }
    "))
  ),
  
  div(class = "main-container",
    div(class = "header",
      h1("黄帝内经 · 个性化健康建议", style = "margin: 0; font-size: 32px;"),
      p("基于中医经典智慧，提供温暖贴心的健康指导", style = "margin: 10px 0 0 0; font-size: 16px; opacity: 0.9;")
    ),
    
    fluidRow(
      column(4,
        div(class = "input-panel",
          div(class = "section-title", "个人信息"),
          
          selectInput("region", "地区",
            choices = c("中国大陆", "港澳台", "东亚其他", "东南亚", "南亚", "欧洲", "北美", "南美", "非洲", "中东", "大洋洲"),
            selected = "中国大陆"
          ),
          
          sliderInput("age", "年龄", min = 0, max = 100, value = 30, step = 1),
          
          radioButtons("gender", "性别",
            choices = c("女" = "female", "男" = "male", "不便透露" = "other"),
            selected = "other",
            inline = TRUE
          ),
          
          sliderInput("stress", "近期压力水平 (0-10)", min = 0, max = 10, value = 5, step = 1),
          
          checkboxGroupInput("lifestyle", "生活方式（可多选）",
            choices = c("久坐" = "sedentary", "熬夜" = "late_sleep", "吸烟" = "smoking", 
                       "饮酒" = "drinking", "规律运动" = "exercise", "素食/清淡" = "light_diet"),
            selected = NULL
          ),
          
          checkboxGroupInput("conditions", "慢性/既往状况（可多选）",
            choices = c("高血压" = "hypertension", "糖尿病" = "diabetes", "高血脂" = "hyperlipidemia",
                       "胃肠易激" = "ibs", "过敏体质" = "allergy", "甲状腺问题" = "thyroid", "焦虑/抑郁" = "mental"),
            selected = NULL
          ),
          
          actionButton("generate", "生成建议", class = "generate-btn"),
          
          div(class = "api-status",
            HTML(paste0("API 状态: <strong>", if (identical(llm_api_key, "待定") || !nzchar(llm_api_key)) "待定" else "已配置", "</strong>"))
          )
        )
      ),
      
      column(8,
        div(class = "input-panel", style = "margin-bottom: 20px;",
          div(class = "section-title", "健康关注点"),
          textAreaInput("concern", NULL,
            width = "100%",
            height = "120px",
            placeholder = "请详细描述您的健康问题，例如：\n• 睡眠困难、早醒、多梦\n• 长期疲劳、精神不振\n• 胃肠不适、消化不良\n• 眼睛干涩、视力模糊\n• 鼻过敏、季节性不适\n• 经期不调、痛经\n• 癌症随访/治疗副作用\n• 术后调理、肿瘤康复\n• 情绪焦虑、压力大\n\n建议说明：症状起止时间、诱发因素、伴随症状、昼夜/季节规律等"
          )
        ),
        
        div(class = "output-panel",
          div(class = "section-title", "《黄帝内经》个性化建议"),
          uiOutput("advice_output"),
          tags$div(style = "margin-top:16px;",
            tags$video(src = "openingvideo.mp4", type = "video/mp4",
              autoplay = NA, muted = NA, loop = NA, controls = NA,
              style = "width:100%; border-radius:8px; background:#000;")
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # 构建提示词
  build_prompt <- function() {
    lifestyle_text <- if(length(input$lifestyle) > 0) {
      paste(c("久坐" = "sedentary", "熬夜" = "late_sleep", "吸烟" = "smoking", 
              "饮酒" = "drinking", "规律运动" = "exercise", "素食/清淡" = "light_diet")[input$lifestyle], 
            collapse = "、")
    } else {
      "未填写"
    }
    
    conditions_text <- if(length(input$conditions) > 0) {
      paste(c("高血压" = "hypertension", "糖尿病" = "diabetes", "高血脂" = "hyperlipidemia",
              "胃肠易激" = "ibs", "过敏体质" = "allergy", "甲状腺问题" = "thyroid", 
              "焦虑/抑郁" = "mental")[input$conditions], collapse = "、")
    } else {
      "无"
    }
    
    gender_text <- switch(input$gender,
      "female" = "女",
      "male" = "男",
      "other" = "不便透露"
    )
    
    persona <- "你是《黄帝内经》的作者，同时也是著名老中医。阅读我给你的黄帝内经全文，深度思考，根据《黄帝内经》的思维方式和口吻，回答我后面给你的健康问题。回答的时候，请你给我《黄帝内经》的原文、翻译、以及根据个人情况的个性化回答，请你的回答具有同理心、简洁、让读者看了心里感觉到温暖、舒服。"
    
    user_info <- paste0(
      "【用户信息】\n",
      "地区：", input$region, "\n",
      "年龄：", input$age, "岁\n",
      "性别：", gender_text, "\n",
      "压力水平：", input$stress, "/10\n",
      "生活方式：", lifestyle_text, "\n",
      "既往状况：", conditions_text, "\n",
      "健康关注：", ifelse(nzchar(input$concern), input$concern, "未填写"), "\n"
    )
    
    paste0(persona, "\n\n", user_info, "\n\n【请按以下格式输出】\n1) 原文：\n2) 翻译：\n3) 个性化建议：")
  }
  
  # 生成建议（占位符）
  generate_advice <- function() {
    using_placeholder <- (identical(llm_api_key, "待定") || !nzchar(llm_api_key))
    
    if (using_placeholder) {
      gender_text <- switch(input$gender, "female" = "女", "male" = "男", "other" = "不便透露")
      
      lifestyle_cn <- c("sedentary" = "久坐", "late_sleep" = "熬夜", "smoking" = "吸烟", 
                        "drinking" = "饮酒", "exercise" = "规律运动", "light_diet" = "素食/清淡")
      lifestyle_text <- if(length(input$lifestyle) > 0) {
        paste(lifestyle_cn[input$lifestyle], collapse = "、")
      } else { "" }
      
      conditions_cn <- c("hypertension" = "高血压", "diabetes" = "糖尿病", "hyperlipidemia" = "高血脂",
                        "ibs" = "胃肠易激", "allergy" = "过敏体质", "thyroid" = "甲状腺问题", 
                        "mental" = "焦虑/抑郁")
      conditions_text <- if(length(input$conditions) > 0) {
        paste(conditions_cn[input$conditions], collapse = "、")
      } else { "" }
      
      # 示例原文（可替换为接入大模型后的动态原文）
      original <- "上古之人，其知道者，法于阴阳，和于术数，食饮有节，起居有常，不妄作劳，故能形与神俱，而尽终其天年，度百岁乃去。"
      
      translation <- "古代懂得养生之道的人，遵循自然阴阳规律，顺应四时变化，饮食有节制，作息有规律，不过度劳累，所以能够身心和谐，享尽天年。"
      
      personalized <- paste0(
        "根据您的情况（", input$region, "，", input$age, "岁，", gender_text, "，压力 ", input$stress, "/10）",
        ifelse(nzchar(lifestyle_text), paste0("，生活方式包括：", lifestyle_text), ""),
        ifelse(nzchar(conditions_text), paste0("，既往状况：", conditions_text), ""),
        ifelse(nzchar(input$concern), paste0("，您关注：", input$concern), ""),
        "。\n\n",
        "建议您从以下三个方面调整：\n\n",
        "【作息调理】建议在晚上23:00前入睡，顺应子午流注，让肝胆在最佳时段修复。早晨适度舒展身体，接触自然光线。\n\n",
        "【情志养护】每日安排10-15分钟静心时光，可以是缓步行走、深呼吸或冥想，帮助疏解压力，调畅气机。\n\n",
        "【饮食调养】以温热清淡为主，七分饱；减少辛辣、酒精、咖啡因；晚餐在睡前≥3小时完成，减轻脾胃负担。\n\n",
        "若症状持续或加重，请及时寻求专业医师面诊评估。愿您身心安康，顺时养生。"
      )
      
      return(list(
        original = original,
        translation = translation,
        personalized = personalized
      ))
    } else {
      # TODO: 接入真实 LLM API
      return(list(
        original = "（待接入 API）",
        translation = "（待接入 API）",
        personalized = "（待接入 API）"
      ))
    }
  }
  
  # 渲染建议
  output$advice_output <- renderUI({
    HTML("<p style='color: #999; text-align: center; padding: 40px;'>请填写左侧个人信息和上方健康关注点，然后点击\"生成建议\"</p>")
  })
  
  observeEvent(input$generate, {
    if (!nzchar(input$concern)) {
      output$advice_output <- renderUI({
        HTML("<p style='color: #e74c3c; text-align: center; padding: 40px;'>⚠️ 请先填写您的健康关注点</p>")
      })
      return()
    }
    
    result <- generate_advice()
    
    output$advice_output <- renderUI({
      HTML(paste0(
        "<div class='advice-box'>",
        "<span class='badge badge-warning'>《黄帝内经》原文</span>",
        "<div class='original-text'>", result$original, "</div>",
        "</div>",
        
        "<div class='advice-box'>",
        "<span class='badge badge-success'>现代翻译</span>",
        "<div class='translation-text'>", result$translation, "</div>",
        "</div>",
        
        "<div class='advice-box'>",
        "<span class='badge badge-primary'>个性化建议</span>",
        "<div class='personalized-text'>", gsub("\n", "<br>", result$personalized), "</div>",
        "</div>"
      ))
    })
  })
}

shinyApp(ui = ui, server = server)

