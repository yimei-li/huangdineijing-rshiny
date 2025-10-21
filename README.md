## 黄帝内经 · 个性化健康建议（R Shiny）

This repository contains an R Shiny app that provides empathic, concise advice inspired by Huangdi Neijing based on user inputs. It shows a looping startup video (`openingvideo.mp4`) and renders structured output (original text, translation, personalized advice). No LLM API key is required to run; a placeholder response is returned until `LLM_API_KEY` is configured.

### Project layout
- `app/app.R`: Shiny app (binds to `0.0.0.0` and `PORT`)
- `openingvideo.mp4`: Startup modal looping video
- `data/huangdi_neijing_full.txt` (optional): If present, used as context

### Run locally (R)
```r
shiny::runApp('app', host = '0.0.0.0', port = 3838)
```

### Docker
Build and run the container locally:
```bash
docker build -t huangdineijing-shiny .
docker run -p 3838:3838 -e PORT=3838 --name hdnj huangdineijing-shiny
```
App will be available at `http://localhost:3838`.

### Railway deployment
This repo includes a `Dockerfile`, so Railway will use Docker to build and run the service.

Option A: Railway Dashboard
1. Connect repo (`yimei-li/huangdineijing-rshiny`).
2. Railway auto-detects the Dockerfile. No special build command is needed.
3. Ensure service exposes the `PORT` environment variable (Railway sets it automatically). No manual port mapping required.
4. Deploy. After build, open the service URL.
5. Optional: Add environment variable `LLM_API_KEY` later when you have a key.

Option B: Railway CLI
```bash
railway link   # link local folder to your Railway project
railway up     # build and deploy using the Dockerfile
```

### Notes
- The app serves `openingvideo.mp4` via a static resource path so it works whether the working directory is the project root or `app/`.
- If you later add the full text file, place it at `data/huangdi_neijing_full.txt` (UTF-8).


