# Chatbot Widget API Documentation

This document outlines the REST API and WebSocket endpoints backing the chatbot widget service. Mobile or web SDK developers (e.g., Flutter, React Native, iOS, Android) can integrate these endpoints to build custom widget interfaces.

## Global Concepts

### Headers & Security
Most widget endpoints strictly enforce domain and authentication guardrails:
* **`Origin` or `Referer`**: **Required** on almost all requests to validate whether the widget is allowed to be served on that platform/app.
* **`x-api-key`**: API Key required for authenticated widget endpoints. (Or passed as `x-api-key` query param for WebSocket connections).
* **`x-widget-studio-preview`**: Custom header parameter (accepts `true`/`1`). When present and truthy, bypasses domain restriction checks for local testing.

### Standard Error Schema
HTTP errors typically follow this schema regardless of endpoint:
```json
{
  "error": "Error description",
  "code": "HTTP_401", // Or VALIDATION_ERROR for 422
  "details": null,    // May contain validation error array
  "timestamp": 1699999999.0
}
```

---

## 1. REST Endpoints

### 1.1 Get Public Widget configuration
Fetches the public UI config for the chatbot. API Key is *not* required, making it safe for public initialization.

* **Endpoint:** `GET /widget-config`
* **Query Parameters:**
  * `chatbot-id` (Required): The UUID of the chatbot.
* **Headers:** `Origin` or `Referer`
* **Response (200 OK):**
  Returns a JSON dictionary containing the public chatbot details (`chatbot_id`, `agent_name`, `welcome_message`, `theme`, etc.).

---

### 1.2 Get Widget Authentication Token / Session
Issues a short-lived auth token for initializing secure WebSocket connections later, bypassing the need to persist raw API keys on the client's socket.

* **Endpoint:** `GET /widget-auth`
* **Query Parameters:**
  * `chatbot-id` (Required)
  * `browser-id` (Required): A persistent unique identifier for the specific device/user.
  * `session-id` (Optional): An existing session string to resume. If omitted, a new one is created.
* **Headers:**
  * `x-api-key` (Required)
  * `Origin` or `Referer`
* **Response (200 OK):**
  ```json
  {
    "session_id": "uuid-string",
    "chatbot_id": "uuid-string",
    "expires_in": 36000,
    "auth_token": "token_string",
    "auth_expires_at": 1700000000.0
  }
  ```

---

### 1.3 Get Chatbot Details (Authenticated)
An alternative to `/widget-config` used by internal scripts. Requires the API key.

* **Endpoint:** `GET /widget-chatbot-details`
* **Query Parameters:** `chatbot-id` (Required)
* **Headers:** `x-api-key` (Required), `Origin`

---

### 1.4 Get Chat History (Linear)
Retrieves a paginated list of chat history for a specific user.

* **Endpoint:** `GET /widget-chat-history`
* **Query Parameters:**
  * `chatbot-id` (Required)
  * `browser-id` (Required)
  * `session-id` (Optional)
  * `widget-auth-token` (Optional, depending on required auth params)
  * `page` (Optional, Default `1`)
  * `limit` (Optional, Default `20`, Max `100`)
* **Headers:** `x-api-key` (Required), `Origin`
* **Response (200 OK):**
  ```json
  {
    "messages": [
      {"role": "user", "content": "Hello", "created_at": "..."},
      {"role": "assistant", "content": "Hi there!", "created_at": "..."}
    ],
    "scope": "visitor",
    "pagination": {
      "page": 1,
      "limit": 20,
      "total_count": 50,
      "total_pages": 3,
      "has_more": true
    }
  }
  ```

---

### 1.5 Get Chat History (Grouped)
Retrieves a list of historic chat sessions for the specified visitor.

* **Endpoint:** `GET /widget-chat-history-grouped`
* **Query Parameters & Headers:** Same as `/widget-chat-history`.
* **Response:** Returns `"sessions"` array containing message groups + start/end timestamps.

---

### 1.6 Track Product Click Interactivity
Persists analytics data concerning UI clicks (e.g. users clicking on recommended product links inside the chat).

* **Endpoint:** `POST /widget-product-click`
* **Query Parameters:**
  * `chatbot-id` (Required)
  * `widget-auth-token` (Optional)
* **Headers:** `x-api-key` (Required), `Origin`
* **Request Payload (`application/json`):**
  ```json
  {
    "browser_id": "device_identifier", 
    "session_id": "optional_session_uuid",
    "product_id": "optional_clicked_product_uuid",
    "action_type": "click",
    "converted": false,
    "query_text": "optional_search_term_used",
    "position": 1 
  }
  ```
* **Response (200 OK):** `{"ok": true, "id": "event_uuid", "clicked_at": "timestamp"}`

---

## 2. WebSocket Protocol (`/ws/chat`)

The primary connection point for the conversational LLM. 

* **WebSocket URL:** `ws://<domain>/ws/chat`
* **Connection Query Parameters:**
  * `chatbot-id` (Required)
  * `browser-id` (Required)
  * `session-id` (Optional, will resume an existing conversation)
  * `x-api-key` (Optional based on signed auth flags, but pass if available)
  * `widget-auth-token` (Required if the server's signed auth flag is enabled)
* **Connection Headers:**
  * `Origin` or `Referer` (Required)

### 2.1 Client ➔ Server Payloads

**Send a Message:**
Send a JSON payload detailing the user's input string. Max length is `4000` chars.
```json
{
  "input": "Can I get a refund?",
  "fingerprint": {
    "hash": "optional_device_fingerprint_string",
    "fingerprintChanged": false,
    "previousHash": null
  }
}
```

### 2.2 Server ➔ Client Payloads

The server pushes asynchronous events over the socket lifecycle. Look for the `"type"` field to route payloads properly within your frontend architecture.

**1. Session Initialization Event**
Fired right after socket connection.
```json
{
  "type": "session",
  "session_id": "uuid-string"
}
```

**2. Keep-Alive Ping**
Fired periodically (~every 10 seconds).
```json
{
  "type": "ping",
  "timestamp": 1700000000.0
}
```

**3. Text Generation Stream (Partial Chunk)**
As the LLM generates tokens.
```json
{
  "type": "stream",
  "content": "I can help ",
  "done": false
}
```

**4. Generation Complete**
Triggered when the agent finishes answering. Wait for this to mark the sequence `done`.
```json
{
  "type": "complete",
  "answer": "I can help with that. Refunds take 5 days.",
  "suggested_question": "What is the refund policy?",
  "session_id": "uuid-string",
  "done": true
}
```

**5. Error Response**
```json
{
  "type": "error",
  "error": "Failed to generate response. Please try again.",
  "details": null
}
```

**6. Rate Limit Enforced**
If a limit gets tripped based on IP or Session window rules.
```json
{
  "type": "rate_limit",
  "scope": "ip",           // "ip" or "session"
  "limit": 100,            // maximum threshold
  "blocked": false,        // If true, the user is temporarily suspended entirely
  "error": "IP rate limit exceeded: 100 messages per hour. Please slow down."
}
```