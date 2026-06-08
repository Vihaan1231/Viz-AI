# Viz-AI: AI Operating System

A production-grade multi-model AI orchestration platform inspired by JARVIS from Iron Man.

## Overview

Viz-AI intelligently routes tasks to the best AI model based on user intent, combining multiple AI systems into one unified assistant.

## Project Structure

```
Viz-AI/
├── backend/                 # TypeScript Node.js backend
│   ├── src/
│   │   ├── config/         # Configuration files
│   │   ├── controllers/    # API controllers
│   │   ├── middleware/     # Express middleware
│   │   ├── routes/         # API routes
│   │   ├── services/       # Business logic
│   │   ├── utils/          # Utility functions
│   │   ├── types/          # TypeScript types
│   │   └── index.ts        # Entry point
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── package.json
│   └── tsconfig.json
├── ai-layer/                # Python AI orchestration
│   ├── src/
│   │   ├── orchestrator.py  # Main orchestration logic
│   │   ├── intent_classifier.py
│   │   ├── model_router.py
│   │   ├── voice_processor.py
│   │   └── utils.py
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/                # Next.js frontend (bare-bones)
│   ├── app/
│   ├── components/
│   ├── lib/
│   └── package.json
├── database/
│   ├── schema.sql          # Master schema
│   └── migrations/         # Future migrations
└── docs/
    └── ARCHITECTURE_AND_DATABASE_DESIGN.md
```

## Tech Stack

- **Backend**: Node.js + Express + TypeScript
- **AI Layer**: Python + FastAPI
- **Database**: PostgreSQL (master + per-user tenants)
- **Cache**: Redis
- **Frontend**: Next.js + React (bare-bones)
- **Voice**: Whisper API + ElevenLabs
- **Deployment**: Docker

## Getting Started

### Prerequisites

- Docker & Docker Compose
- Node.js 18+
- Python 3.10+
- PostgreSQL 14+
- Redis 7+

### Setup

1. **Clone and enter directory**
   ```bash
   cd Viz-AI
   ```

2. **Copy environment file**
   ```bash
   cp .env.example .env
   ```

3. **Start services with Docker**
   ```bash
   docker-compose up -d
   ```

4. **Run database migrations**
   ```bash
   docker exec viz-ai-backend npm run db:migrate
   ```

5. **Start backend**
   ```bash
   cd backend && npm install && npm run dev
   ```

6. **Start AI layer** (in another terminal)
   ```bash
   cd ai-layer && pip install -r requirements.txt && python -m uvicorn src.main:app --reload
   ```

7. **Start frontend** (in another terminal)
   ```bash
   cd frontend && npm install && npm run dev
   ```

## Phase 1 Checklist

- [x] Project structure
- [x] Docker setup
- [x] Database schema
- [ ] Express backend scaffold
- [ ] OAuth setup
- [ ] Rate limiting middleware
- [ ] Database connection
- [ ] API routes
- [ ] Python AI layer
- [ ] Bare-bones UI

## API Endpoints (Phase 1)

- `POST /api/v1/auth/login` - OAuth login
- `GET /api/v1/auth/me` - Get current user
- `POST /api/v1/api-keys/add` - Add API key
- `GET /api/v1/api-keys` - List API keys
- `POST /api/v1/conversations` - Create conversation
- `GET /api/v1/conversations` - List conversations

## Future Phases

- Phase 2: Core features (chat, voice, AI routing)
- Phase 3: Advanced features (automations, integrations)
- Phase 4: Polish & deployment

## License

MIT
