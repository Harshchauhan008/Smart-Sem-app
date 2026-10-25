# SmartSem

A chat-first college assistant for managing semesters, subjects, timetables,
attendance, assignments and study questions in one mobile app.

**Core idea:** the database keeps the truth, the AI explains it, and the AI
never decides what is true.

## Tech stack
- **Frontend:** Flutter, Dart, Material Design 3, HTTP, Hive CE
- **Backend:** Java 17, Spring Boot, Spring Security (JWT), Spring Data JPA, PostgreSQL
- **AI:** Google Gemini 2.5 Flash (LLM) for chat, timetable extraction and intent detection

## Features
- JWT authentication with per-user ownership checks
- Semester, subject and timetable management
- AI timetable extraction from an image, with a review step before import
- Attendance tracking with percentage per subject
- Persistent AI academic chat
- Intent extraction (`/api/ai/extract-intent`)

## Status
- Backend: implemented and tested locally
- Frontend: auth, dashboard and attendance screens done; notifications in progress
- Planned: AI chat screen, assignments and document upload screens, RAG over study material, push notifications

## Run locally
Backend: `./mvnw spring-boot:run`
Set these as environment variables, never commit them: `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`, `GEMINI_API_KEY`
Frontend: `flutter pub get && flutter run`

