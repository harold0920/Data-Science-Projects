const API_BASE = 'http://127.0.0.1:8000';
const chatHistoryEl = document.getElementById('chatHistory');
const chatForm = document.getElementById('chatForm');
const messageInput = document.getElementById('messageInput');
const modeBadge = document.getElementById('modeBadge');
const promptButtons = document.querySelectorAll('.prompt-btn');

const history = [];

function addMessage(role, content) {
  history.push({ role, content });
  const div = document.createElement('div');
  div.className = `message ${role}`;
  div.textContent = content;
  chatHistoryEl.appendChild(div);
  chatHistoryEl.scrollTop = chatHistoryEl.scrollHeight;
}

async function loadMode() {
  try {
    const response = await fetch(`${API_BASE}/api/health`);
    const data = await response.json();
    modeBadge.textContent = data.mode === 'api' ? 'API mode' : '$0 mock mode';
  } catch {
    modeBadge.textContent = 'Backend offline';
  }
}

async function sendMessage(text) {
  addMessage('user', text);
  messageInput.value = '';

  try {
    const response = await fetch(`${API_BASE}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: text,
        history: history.filter(m => m.role !== 'assistant' || m.content !== 'Thinking...').slice(-12)
      })
    });

    const data = await response.json();
    addMessage('assistant', data.reply);
    modeBadge.textContent = data.mode === 'api' ? 'API mode' : data.mode === 'mock' ? '$0 mock mode' : 'Error mode';
  } catch (error) {
    addMessage('assistant', `Something went wrong: ${error.message}`);
  }
}

chatForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const text = messageInput.value.trim();
  if (!text) return;
  await sendMessage(text);
});

promptButtons.forEach((button) => {
  button.addEventListener('click', () => sendMessage(button.textContent));
});

addMessage('assistant', 'Welcome! Try one of the sample prompts or type your own message.');
loadMode();
