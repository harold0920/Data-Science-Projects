# Simple Chatbot Web App (Python Version)

This project is a simple chatbot web app with a frontend and a Python backend. It includes a chat box, message history, and four clickable sample prompts. The backend has one `/api/chat` route that either sends the user message to the OpenAI API or falls back to a required `$0 mode` using a local JSON mock-response file when no `OPENAI_API_KEY` is present. This makes the project usable even without API credits. The frontend is intentionally simple so the chatbot flow is easy to understand and demo. The project matches the course goal of building a chatbot with OpenAI tools while still being practical for beginners.

## Project Structure

```text
python-chatbot-app/
├── backend/
│   ├── data/
│   │   └── mock_responses.json
│   ├── main.py
│   └── requirements.txt
├── frontend/
│   ├── app.js
│   ├── index.html
│   └── styles.css
└── README.md
```

## How to Run

### 1) Start the backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload
```

### 2) Open the frontend

Open `frontend/index.html` in your browser.

## Mock Mode ($0 mode)

If there is **no** `OPENAI_API_KEY` environment variable, the app automatically uses `backend/data/mock_responses.json`.

That mode is required for the assignment because the chatbot still works for free.

## API Mode (Optional)

Set your environment variable first:

### Windows PowerShell

```powershell
$env:OPENAI_API_KEY="your_api_key_here"
```

Then restart the backend:

```bash
uvicorn main:app --reload
```

The backend uses the official OpenAI Python SDK and the Responses API, which OpenAI recommends for new projects.

## Checklist




I managed context by storing the conversation history on the frontend and sending the recent messages back to the backend with each new request. I only kept a limited number of previous messages so the context stays relevant and the request stays lightweight. This creates a simple session-like experience because the user can continue one conversation and still see earlier messages in the same thread. My UI includes four clickable sample prompts so the user has clear starting actions instead of facing an empty chat box. That reflects the idea behind prompts and guided actions because the interface helps users discover what the chatbot can do. The persistent message history reflects the thread or session concept since the conversation remains visible and organized in one place. I also added a mode badge so the user can clearly see whether the app is using OpenAI or the free local mock file. These choices make the chatbot easier to understand, easier to demo, and closer to the structured interaction style discussed in ChatKit and AgentKit concepts.

## Notes

- Responses API is recommended for new projects. citeturn413189search0turn413189search11
- The official Python library supports the Responses API. citeturn413189search3turn413189search6
- Streaming is available too, but this project keeps one simple route returning a single response for easier grading. citeturn413189search10
