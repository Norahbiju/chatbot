const SESSION_KEY = "bedrock-rag-session-id";
const messages = document.getElementById("messages");
const form = document.getElementById("chatForm");
const input = document.getElementById("messageInput");
const sendButton = document.getElementById("sendButton");
const newButton = document.getElementById("newConversation");

let waiting = false;

function sessionId() {
  let id = localStorage.getItem(SESSION_KEY);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(SESSION_KEY, id);
  }
  return id;
}

function appendMessage(role, text, citations = []) {
  const item = document.createElement("article");
  item.className = `message ${role}`;
  const body = document.createElement("div");
  body.textContent = text;
  item.appendChild(body);

  if (citations.length) {
    const list = document.createElement("div");
    list.className = "citations";
    citations.forEach((citation) => {
      const node = document.createElement("div");
      node.className = "citation";
      node.textContent = `[${citation.id}] ${citation.title} - ${citation.source}`;
      list.appendChild(node);
    });
    item.appendChild(list);
  }

  messages.appendChild(item);
  messages.scrollTop = messages.scrollHeight;
  return item;
}

async function sendMessage(text) {
  waiting = true;
  sendButton.disabled = true;
  input.disabled = true;
  const loading = appendMessage("assistant", "Thinking...");

  try {
    const response = await fetch("/api/chat", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ sessionId: sessionId(), message: text }),
    });
    const payload = await response.json();
    loading.remove();
    if (!response.ok) {
      appendMessage("error", payload.error?.message || "The request failed.");
      return;
    }
    appendMessage("assistant", payload.answer, payload.citations || []);
  } catch (error) {
    loading.remove();
    appendMessage("error", "The chat service is unavailable.");
  } finally {
    waiting = false;
    sendButton.disabled = false;
    input.disabled = false;
    input.focus();
  }
}

form.addEventListener("submit", (event) => {
  event.preventDefault();
  if (waiting) return;
  const text = input.value.trim();
  if (!text) return;
  input.value = "";
  appendMessage("user", text);
  sendMessage(text);
});

input.addEventListener("keydown", (event) => {
  if (event.key === "Enter" && !event.shiftKey) {
    event.preventDefault();
    form.requestSubmit();
  }
});

newButton.addEventListener("click", () => {
  localStorage.removeItem(SESSION_KEY);
  messages.textContent = "";
  sessionId();
  input.focus();
});

sessionId();
appendMessage("assistant", "Ask me about Terraform state locking, Kubernetes basics, or GitHub Actions OIDC.");
