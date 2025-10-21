## Huangdi Neijing Shiny App (Railway-ready)

### What this is
- A minimal R Shiny app that collects health-related inputs and asks a model to answer in the style/structure inspired by Huangdi Neijing: original quote, translation, and personalized guidance.
- Dockerized for easy Railway deployment (listens on `PORT`, default 8080).

### Local run (Docker)
1. Create `.env` from `.env.sample` and set `OPENAI_API_KEY` (and optional `OPENAI_BASE_URL`, `OPENAI_MODEL`).
2. Build: `docker build -t hdnj-shiny .`
3. Run: `docker run --rm -p 8080:8080 --env-file .env hdnj-shiny`
4. Open: `http://localhost:8080`

### Deploy to Railway
You can use either GitHub integration or direct CLI deploy. GitHub is simpler and recommended.

#### Option A: GitHub → Railway (recommended)
1. Push this folder to a new GitHub repository.
2. In Railway dashboard: New Project → GitHub Repository → select your repo.
3. Railway will detect the Dockerfile automatically.
4. In Project → Variables, add:
   - `OPENAI_API_KEY = your-key`
   - (optional) `OPENAI_BASE_URL` and `OPENAI_MODEL`
5. Deploy. After build completes, open the generated URL. Railway sets `PORT` automatically.

#### Option B: Railway CLI
1. Install Railway CLI and login.
2. Run in this directory:
   - `railway up` (or `railway run` depending on your workflow). Ensure Variables above are set in the project.

### App usage
- Optionally upload a `.txt` file containing the full Huangdi Neijing text to improve quotations. Without it, the app uses a short public-domain excerpt in `data/huangdi_neijing_excerpt.txt`.
- Fill inputs, write your health question, click "生成建议".

### Notes
- This app calls an OpenAI-compatible Chat Completions endpoint via `httr2`. You can point `OPENAI_BASE_URL` to a compatible provider if desired.
- The model output is rendered as HTML via `commonmark`.

