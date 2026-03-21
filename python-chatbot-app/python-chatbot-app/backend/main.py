import json
import os
from pathlib import Path
from typing import List, Literal

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

try:
    from openai import OpenAI
except Exception:
    OpenAI = None

BASE_DIR = Path(__file__).resolve().parent
MOCK_FILE = BASE_DIR / 'data' / 'mock_responses.json'
MODEL = os.getenv('OPENAI_MODEL', 'gpt-5.4-mini')
SYSTEM_PROMPT = (
    'You are a helpful chatbot for a project. '
    'Give clear, short, friendly answers unless the user asks for more detail.'
)

app = FastAPI(title='Simple Chatbot API')
app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)


class Message(BaseModel):
    role: Literal['user', 'assistant']
    content: str


class ChatRequest(BaseModel):
    message: str
    history: List[Message] = []


@app.get('/api/health')
def health_check():
    return {
        'status': 'ok',
        'mode': 'api' if os.getenv('OPENAI_API_KEY') else 'mock'
    }


@app.post('/api/chat')
def chat(req: ChatRequest):
    if not os.getenv('OPENAI_API_KEY'):
        return JSONResponse(_mock_reply(req.message))

    if OpenAI is None:
        return JSONResponse(
            {
                'reply': 'The OpenAI package is not installed, so the app cannot use API mode yet.',
                'mode': 'error'
            },
            status_code=500,
        )

    client = OpenAI()

    input_items = [
        {
            'role': 'system',
            'content': [{'type': 'input_text', 'text': SYSTEM_PROMPT}],
        }
    ]

    for item in req.history[-10:]:
        input_items.append(
            {
                'role': item.role,
                'content': [{'type': 'input_text', 'text': item.content}],
            }
        )

    input_items.append(
        {
            'role': 'user',
            'content': [{'type': 'input_text', 'text': req.message}],
        }
    )

    try:
        response = client.responses.create(
            model=MODEL,
            input=input_items,
        )
        text = getattr(response, 'output_text', None) or 'Sorry, I could not generate a response.'
        return {'reply': text, 'mode': 'api'}
    except Exception as e:
        return JSONResponse(
            {
                'reply': f'API mode failed, so please check your API key and dependencies. Error: {e}',
                'mode': 'error',
            },
            status_code=500,
        )


def _mock_reply(user_message: str):
    data = json.loads(MOCK_FILE.read_text(encoding='utf-8'))
    lowered = user_message.lower()

    for item in data['keyword_responses']:
        if any(keyword in lowered for keyword in item['keywords']):
            return {'reply': item['response'], 'mode': 'mock'}

    fallback = data['fallback_template'].replace('{message}', user_message)
    return {'reply': fallback, 'mode': 'mock'}
