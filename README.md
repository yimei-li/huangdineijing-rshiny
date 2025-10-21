# 黄帝内经 · 个性化健康建议

基于《黄帝内经》智慧的 R Shiny 健康建议应用。

## 功能

- **左侧输入**：年龄、性别、地区、压力水平、生活方式、慢性疾病等
- **上方文本框**：详细描述健康关注点（睡眠、疲劳、胃肠、眼睛、情绪等）
- **右下输出**：基于《黄帝内经》风格的个性化建议（原文、翻译、个性化方案）

## Railway 部署步骤

### 前提条件
- GitHub 仓库：`yimei-li/huangdineijing-rshiny`
- Railway 项目已创建并连接该仓库

### 部署

1. **推送代码到 GitHub**
```bash
git add app.R Dockerfile railway.toml .dockerignore README.md
git commit -m "Add Shiny app for Railway deployment"
git push origin main
```

2. **Railway 自动部署**
   - Railway 检测到 `railway.toml` 和 `Dockerfile` 会自动构建
   - 构建完成后访问分配的 URL（如 `https://xxx.railway.app`）

3. **（可选）配置环境变量**
   - 在 Railway Dashboard → Variables 添加：
     - `LLM_API_KEY=你的API密钥`（当前为"待定"，应用仍可正常运行）

### 本地测试

```bash
# 安装依赖
R -e "install.packages('shiny')"

# 运行应用
R -e "shiny::runApp('app.R', port=3838, host='0.0.0.0')"

# 访问 http://localhost:3838
```

### Docker 本地测试

```bash
docker build -t huangdineijing-shiny .
docker run -p 8080:8080 -e PORT=8080 huangdineijing-shiny

# 访问 http://localhost:8080
```

## 文件说明

- `app.R` - Shiny 应用主文件
- `Dockerfile` - Docker 构建配置（使用 rocker/shiny 基础镜像）
- `railway.toml` - Railway 部署配置
- `.dockerignore` - Docker 构建时忽略的文件

## 故障排查

### Railway 部署失败
1. 检查 Railway Logs 查看错误信息
2. 确认 `app.R` 在仓库根目录
3. 确认 `Dockerfile` 和 `railway.toml` 在根目录
4. 检查 Railway 是否正确连接了 GitHub 仓库

### 应用运行但无法访问
1. 检查 Railway → Settings → Networking 是否已生成公开域名
2. 确认防火墙未阻止 Railway 域名

### API 功能
- 当前为占位符模式（显示示例内容）
- 需要配置 `LLM_API_KEY` 环境变量后才能调用真实 AI 模型
- 在 Railway Dashboard → Variables 中添加密钥

## 技术栈

- R Shiny
- Docker (rocker/shiny:4.3.2)
- Railway (PaaS)

## 许可

MIT
