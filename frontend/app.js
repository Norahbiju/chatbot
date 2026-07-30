const SESSION_KEY = "bedrock-rag-active-session-id";
const HISTORY_KEY = "bedrock-rag-chat-history";
const messages = document.getElementById("messages");
const historyList = document.getElementById("historyList");
const form = document.getElementById("chatForm");
const input = document.getElementById("messageInput");
const sendButton = document.getElementById("sendButton");
const newButton = document.getElementById("newConversation");

let waiting = false;
let activeSessionId = "";

function readHistory() {
  try {
    const parsed = JSON.parse(localStorage.getItem(HISTORY_KEY) || "[]");
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function writeHistory(history) {
  localStorage.setItem(HISTORY_KEY, JSON.stringify(history.slice(0, 30)));
}

function createSession() {
  const id = crypto.randomUUID();
  const session = {
    id,
    title: "New chat",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    messages: [],
  };
  writeHistory([session, ...readHistory().filter((item) => item.id !== id)]);
  localStorage.setItem(SESSION_KEY, id);
  activeSessionId = id;
  return session;
}

function currentSession() {
  const history = readHistory();
  let session = history.find((item) => item.id === activeSessionId);
  if (!session) {
    session = createSession();
  }
  return session;
}

function saveSession(session) {
  const history = readHistory().filter((item) => item.id !== session.id);
  session.updatedAt = new Date().toISOString();
  writeHistory([session, ...history]);
  localStorage.setItem(SESSION_KEY, session.id);
  activeSessionId = session.id;
}

function titleFromMessage(text) {
  const clean = text.replace(/\s+/g, " ").trim();
  if (!clean) return "New chat";
  return clean.length > 42 ? `${clean.slice(0, 42)}...` : clean;
}

function renderEmptyState() {
  messages.textContent = "";
  const empty = document.createElement("div");
  empty.className = "empty-state";
  const title = document.createElement("h1");
  title.textContent = "How can I help you today?";
  empty.appendChild(title);
  messages.appendChild(empty);
}

function renderHistory() {
  const history = readHistory();
  historyList.textContent = "";
  if (!history.length) {
    const empty = document.createElement("div");
    empty.className = "history-empty";
    empty.textContent = "No chats yet";
    historyList.appendChild(empty);
    return;
  }

  history.forEach((session) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = session.id === activeSessionId ? "history-item active" : "history-item";
    button.textContent = session.title || "New chat";
    button.addEventListener("click", () => {
      activeSessionId = session.id;
      localStorage.setItem(SESSION_KEY, session.id);
      renderConversation();
      renderHistory();
      input.focus();
    });
    historyList.appendChild(button);
  });
}

function appendMessageNode(role, text, citations = []) {
  const item = document.createElement("article");
  item.className = `message ${role}`;

  const body = document.createElement("div");
  body.className = "message-body";
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
    body.appendChild(list);
  }

  messages.appendChild(item);
  messages.scrollTop = messages.scrollHeight;
  return item;
}

function renderConversation() {
  const session = currentSession();
  messages.textContent = "";
  if (!session.messages.length) {
    renderEmptyState();
  } else {
    session.messages.forEach((message) => {
      appendMessageNode(message.role, message.content, message.citations || []);
    });
  }
}

function addMessage(role, content, citations = []) {
  const session = currentSession();
  if (role === "user" && (!session.title || session.title === "New chat")) {
    session.title = titleFromMessage(content);
  }
  session.messages.push({ role, content, citations, createdAt: new Date().toISOString() });
  saveSession(session);
  renderHistory();
  if (messages.querySelector(".empty-state")) {
    messages.textContent = "";
  }
  return appendMessageNode(role, content, citations);
}

async function sendMessage(text) {
  waiting = true;
  sendButton.disabled = true;
  input.disabled = true;
  const loading = appendMessageNode("assistant", "Thinking...");

  try {
    const response = await fetch("/api/chat", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ sessionId: activeSessionId, message: text }),
    });
    const payload = await response.json();
    loading.remove();
    if (!response.ok) {
      addMessage("error", payload.error?.message || "The request failed.");
      return;
    }
    addMessage("assistant", payload.answer, payload.citations || []);
  } catch {
    loading.remove();
    addMessage("error", "The chat service is unavailable.");
  } finally {
    waiting = false;
    sendButton.disabled = false;
    input.disabled = false;
    input.focus();
  }
}

function resizeInput() {
  input.style.height = "auto";
  input.style.height = `${Math.min(input.scrollHeight, 180)}px`;
}

form.addEventListener("submit", (event) => {
  event.preventDefault();
  if (waiting) return;
  const text = input.value.trim();
  if (!text) return;
  input.value = "";
  resizeInput();
  addMessage("user", text);
  sendMessage(text);
});

input.addEventListener("input", resizeInput);

input.addEventListener("keydown", (event) => {
  if (event.key === "Enter" && !event.shiftKey) {
    event.preventDefault();
    form.requestSubmit();
  }
});

newButton.addEventListener("click", () => {
  createSession();
  renderConversation();
  renderHistory();
  input.focus();
});

activeSessionId = localStorage.getItem(SESSION_KEY) || "";
if (!activeSessionId || !readHistory().some((item) => item.id === activeSessionId)) {
  createSession();
}
renderConversation();
renderHistory();
resizeInput();
