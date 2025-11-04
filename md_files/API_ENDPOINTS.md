# Course Selling Platform - API Endpoints Reference

## Base Configuration
- **API Gateway**: `http://localhost:8765`
- **Frontend**: `http://localhost:3000`

---

## 1. User Management Service
**Base URL**: `/user-management-service/api/users`

### Authentication Endpoints

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| POST | `/register` | Register a new user | `{ firstName, lastName, email, password, role }` |
| POST | `/login` | Authenticate user | `{ email, password }` |
| GET | `/profile/{id}` | Get user profile | None |

### Example Registration
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "password": "SecurePassword123",
  "role": "STUDENT"
}
```

### Example Login
```json
{
  "email": "john.doe@example.com",
  "password": "SecurePassword123"
}
```

---

## 2. Course Management Service
**Base URL**: `/course-management-service/api/courses`

### Course Endpoints

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| GET | `/` | Get all courses | None |
| GET | `/{id}` | Get course by ID | None |
| POST | `/` | Create new course | `{ title, description, price, instructorId, duration?, level?, language? }` |
| PUT | `/{id}` | Update course | `{ title, description, price, instructorId, duration?, level?, language? }` |
| DELETE | `/{id}` | Delete course | None |

### Example Create Course
```json
{
  "title": "Java Spring Boot Masterclass",
  "description": "Comprehensive course on Spring Boot development",
  "price": 79.99,
  "instructorId": 2,
  "duration": "12 hours",
  "level": "Intermediate",
  "language": "English"
}
```

**Course Fields:**
- `title` (required) - Course title
- `description` (optional) - Course description
- `price` (required) - Course price
- `instructorId` (required) - ID of the instructor
- `duration` (optional) - Course duration (e.g., "12 hours", "3 weeks")
- `level` (optional) - Course level (e.g., "Beginner", "Intermediate", "Advanced")
- `language` (optional) - Course language (e.g., "English", "Spanish")

### Reviews & Ratings Endpoints

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| GET | `/reviews/summary` | Get global rating summary | None |
| GET | `/reviews/course/{courseId}/summary` | Get course rating summary | None |
| GET | `/reviews/course/{courseId}` | Get all reviews for a course | None |
| POST | `/reviews` | Create a review | `{ courseId, userId, rating, comment }` |

### Example Create Review
```json
{
  "courseId": 1,
  "userId": 2,
  "rating": 5,
  "comment": "Excellent course, highly recommend!"
}
```

---

## 3. Enrollment Service
**Base URL**: `/enrollment-service/api/enrollments`

### Enrollment Endpoints

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| POST | `/` | Enroll in a course | `{ studentId, courseId }` |
| GET | `/student/{studentId}` | Get student enrollments | None |
| GET | `/course/{courseId}` | Get course enrollments | None |
| GET | `/{id}` | Get enrollment by ID | None |
| PUT | `/{id}/progress` | Update progress | `{ progress }` |
| PUT | `/{id}/complete` | Mark as complete | `{ completed }` |
| PUT | `/{id}/stage1` | Mark stage 1 as complete | `{ completed }` |
| PUT | `/{id}/stage2` | Mark stage 2 as complete | `{ completed }` |
| PUT | `/{id}/current-stage` | Update current stage | `{ stage }` |
| DELETE | `/{id}` | Unenroll from course | None |
| GET | `/student/{studentId}/stats` | Get student enrollment statistics | None |
| GET | `/stats` | Get global enrollment statistics | None |

### Example Enroll
```json
{
  "studentId": 1,
  "courseId": 101
}
```

### Example Update Progress
```json
{
  "progress": 75
}
```

### Example Complete Enrollment
```json
{
  "completed": true
}
```

### Example Update Stage 1
```json
{
  "completed": true
}
```

### Example Update Stage 2
```json
{
  "completed": true
}
```

### Example Update Current Stage
```json
{
  "stage": 1
}
```

**Stage Values:**
- `0` - Not started
- `1` - Stage 1 completed (progress: 50%)
- `2` - Stage 2 completed (progress: 100%, course completed)
- `3` - Course fully completed (set automatically when both stages complete)

### Example Enrollment Response
```json
{
  "id": 1,
  "studentId": 1,
  "courseId": 101,
  "progress": 50,
  "completed": false,
  "stage1Completed": true,
  "stage2Completed": false,
  "currentStage": 1,
  "enrolledAt": "2024-01-15T10:30:00"
}
```

### Example Enrollment Stats Response
```json
{
  "totalEnrollments": 150,
  "completedCourses": 45,
  "averageProgress": 65.5,
  "recentEnrollments": [
    {
      "id": 1,
      "studentId": 1,
      "courseId": 101,
      "progress": 75,
      "completed": false,
      "stage1Completed": true,
      "stage2Completed": false,
      "currentStage": 1,
      "enrolledAt": "2024-01-15T10:30:00"
    }
  ]
}
```

**Enrollment Fields:**
- `progress` - Percentage (0-100), automatically updated by stages
- `stage1Completed` - Boolean, true when stage 1 is complete (progress: 50%)
- `stage2Completed` - Boolean, true when stage 2 is complete (progress: 100%, completed: true)
- `currentStage` - Integer (0=not started, 1=stage1, 2=stage2, 3=completed)
- `completed` - Boolean, true when both stages are complete

---

## 4. Content Delivery Service
**Base URL**: `/content-delivery-service/api/content`

### Content Endpoints

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| GET | `/` | Get all content | None |
| GET | `/{id}` | Get content by ID | None |
| GET | `/course/{courseId}` | Get content for a course | None |
| POST | `/` | Add new content | `{ courseId, type, title, url, body? }` |
| DELETE | `/{id}` | Delete content | None |

### Content Types
- `VIDEO` - Video content
- `PDF` - PDF document
- `DOC` - Document
- `IMAGE` - Image
- `TEXT` - Text content (uses `body` field)

### Example Add Content (Video/PDF/DOC/IMAGE)
```json
{
  "courseId": 101,
  "type": "VIDEO",
  "title": "Introduction Video",
  "url": "https://example.com/video.mp4"
}
```

### Example Add Content (TEXT)
```json
{
  "courseId": 101,
  "type": "TEXT",
  "title": "Course Introduction",
  "url": "",
  "body": "This course covers fundamentals of..."
}
```

### Content Access Logs
**Base URL**: `/content-delivery-service/api/logs`

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| POST | `/` | Log content access | `{ userId, content: { contentId }, action }` |
| GET | `/` | Get all logs | None |
| GET | `/user/{userId}` | Get logs for user | None |

### Example Log Access
```json
{
  "userId": 1,
  "content": { "contentId": 5 },
  "action": "STREAM"
}
```

---

## Testing with Postman

### Setup
1. Import the collection or manually set base URL to: `http://localhost:8765`
2. Use endpoint paths as shown above

### Quick Test Sequence

#### 1. Register User
```
POST http://localhost:8765/user-management-service/api/users/register
Content-Type: application/json

{
  "firstName": "Test",
  "lastName": "User",
  "email": "test@example.com",
  "password": "password123",
  "role": "STUDENT"
}
```

#### 2. Create Course (Instructor)
```
POST http://localhost:8765/course-management-service/api/courses
Content-Type: application/json

{
  "title": "Test Course",
  "description": "A test course",
  "price": 99.99,
  "instructorId": 1,
  "duration": "10 hours",
  "level": "Beginner",
  "language": "English"
}
```

#### 3. Enroll in Course
```
POST http://localhost:8765/enrollment-service/api/enrollments
Content-Type: application/json

{
  "studentId": 1,
  "courseId": 1
}
```

#### 4. Add Content
```
POST http://localhost:8765/content-delivery-service/api/content
Content-Type: application/json

{
  "courseId": 1,
  "type": "TEXT",
  "title": "Introduction",
  "url": "",
  "body": "Welcome to the course!"
}
```

#### 5. Add Review
```
POST http://localhost:8765/course-management-service/api/reviews
Content-Type: application/json

{
  "courseId": 1,
  "userId": 1,
  "rating": 5,
  "comment": "Great course!"
}
```

---

## Frontend API Client Usage

The frontend uses a centralized API client in `frontend/src/services/api.ts`:

### Key Functions

#### Courses
- `fetchCourses()` - Get all courses
- `fetchCourseById(id)` - Get course by ID
- `createCourse(course)` - Create new course
- `updateCourse(id, course)` - Update course
- `deleteCourse(id)` - Delete course

#### Reviews
- `fetchCourseRatingSummary(courseId)` - Get course rating summary
- `fetchGlobalRatingSummary()` - Get global rating summary
- `fetchCourseReviews(courseId)` - Get course reviews
- `createReview(review)` - Create review

#### Authentication
- `loginApi(email, password)` - Login
- `registerApi(payload)` - Register
- `getUserProfile(userId)` - Get user profile

#### Enrollment
- `enrollInCourse(enrollment)` - Enroll in course
- `getEnrollmentById(enrollmentId)` - Get enrollment by ID
- `getStudentEnrollments(studentId)` - Get student enrollments
- `getCourseEnrollments(courseId)` - Get course enrollments
- `updateEnrollmentProgress(enrollmentId, progress)` - Update progress
- `updateEnrollmentCompletion(enrollmentId, completion)` - Mark enrollment as complete
- `updateEnrollmentStage1(enrollmentId, completed)` - Mark stage 1 as complete
- `updateEnrollmentStage2(enrollmentId, completed)` - Mark stage 2 as complete
- `updateEnrollmentCurrentStage(enrollmentId, stage)` - Update current stage
- `unenrollFromCourse(enrollmentId)` - Unenroll from course
- `getEnrollmentStats(studentId?)` - Get enrollment statistics (optional studentId)

#### Content
- `fetchContentByCourse(courseId)` - Get course content
- `addContentItem(payload)` - Add content
- `deleteContentItem(contentId)` - Delete content
- `logContentAccess(userId, contentId, action)` - Log access

---

## 5. User Management Service - Additional Endpoints

### User Statistics Endpoint

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| GET | `/api/users/stats` | Get platform statistics (students, instructors, courses) | None |

**Example Response:**
```json
{
  "students": 150,
  "instructors": 25,
  "courses": 50
}
```

**Note:** This endpoint is publicly accessible (no authentication required) for displaying platform statistics on the homepage.

---

## Notes

### Service Communication
- All endpoints go through API Gateway at port 8765
- **Docker Containers**: API Gateway uses Eureka service discovery with `lb://` protocol for load-balanced routing
- **Container Names**: Services communicate using Docker container names:
  - Eureka: `course-platform-eureka:8761`
  - Config Server: `course-platform-config:8888`
  - MySQL: `course-platform-mysql:3306`
  - API Gateway: `course-platform-api-gateway:8765`

### Service Discovery
- Services use Eureka for service discovery
- API Gateway routes use `lb://{service-name}` protocol (e.g., `lb://user-management-service`)
- Service names must match Eureka registration names exactly

### Configuration
- Config Server provides centralized configuration
- MySQL databases are separate per service (users_db, courses_db, enrollment_db, content_db)

### Course Management
- **Removed**: `categoryId` field (category table removed)
- **Added**: `duration`, `level`, `language` fields for course creation
- Courses display enrollment count dynamically

### Enrollment System
- **Two-Stage Completion**: Courses have two stages (stage1, stage2) before completion
- **Stage Tracking**: `currentStage` field tracks progress (0=not started, 1=stage1, 2=stage2, 3=completed)
- **Progress**: Automatically updated based on stages (50% at stage1, 100% at stage2)
- **Removed**: `certificateUrl` field (no longer generated)

### Content Types
- Content types include VIDEO, PDF, DOC, IMAGE, and TEXT
- TEXT type uses `body` field instead of `url` field
- Content access logs are tracked in real-time

### Database Changes
- Removed `category` and `course_content` tables from courses_db
- Removed `bio`, `phone`, `profile_image` columns from users table
- Removed `certificate_url` column from enrollments table
