# Software Requirements Specification (SRS)

## Project Name

EduSphere

Version: 1.0

Document Status: Draft

Target Release: MVP (Coaching Institute)

---

# 1. Introduction

## 1.1 Purpose

EduSphere is a cloud-based Coaching Institute Management Platform designed to digitize daily coaching operations. It replaces manual registers, spreadsheets, and scattered WhatsApp communication with a centralized platform for administrators, teachers, students, and parents.

The MVP targets coaching institutes with 50–1000 students. The architecture will support future expansion into schools, colleges, and training institutes without requiring major redesign.

---

# 2. Scope

The system shall provide:

* Student Management
* Teacher Management
* Batch Management
* Attendance
* Homework
* Assignments
* Tests & Results
* Fee Management
* Push Notifications
* Reports & Analytics
* Role-Based Access Control
* Offline Support
* Cloud Synchronization

---

# 3. Stakeholders

Primary Stakeholders

* Coaching Owner
* Administrator
* Teacher
* Student
* Parent

Secondary Stakeholders

* Accountant
* Receptionist
* Super Administrator
* Technical Support Team

---

# 4. User Roles

## Super Admin

Responsibilities

* Manage Organizations
* Manage Subscription Plans
* Monitor Platform Usage
* View System Analytics
* Suspend Organizations
* Configure Global Settings

---

## Coaching Admin

Responsibilities

* Manage Students
* Manage Teachers
* Manage Batches
* Configure Fees
* View Reports
* Send Notifications
* Manage Exams

---

## Teacher

Responsibilities

* Take Attendance
* Upload Homework
* Enter Marks
* Send Notices
* View Assigned Batches

---

## Student

Responsibilities

* View Attendance
* Submit Assignments
* View Homework
* View Test Results
* Pay Fees
* Download Notes

---

## Parent

Responsibilities

* Monitor Student Progress
* Receive Notifications
* Pay Fees
* View Attendance
* Contact Coaching

---

# 5. Functional Requirements

## Authentication

The system shall

* Support Email Authentication
* Support Mobile OTP Authentication
* Maintain Secure Sessions
* Support Password Reset
* Support Multi-device Login

---

## Student Management

The system shall

* Add Student
* Edit Student
* Delete Student
* Import Students via CSV
* Generate QR ID Cards
* Store Documents
* Promote Students

---

## Batch Management

The system shall

* Create Batch
* Assign Teacher
* Assign Subjects
* Configure Timetable
* Assign Students

---

## Attendance Module

The system shall

* Record Attendance
* Edit Attendance
* Bulk Attendance
* QR Attendance
* Attendance Analytics
* Monthly Reports

---

## Homework Module

The system shall

* Create Homework
* Attach Files
* Attach Images
* Set Due Date
* Receive Student Submission
* Grade Homework

---

## Test Module

The system shall

* Create Test
* Record Marks
* Calculate Percentage
* Generate Rank
* Generate Report Card

---

## Fee Module

The system shall

* Create Fee Structure
* Generate Monthly Fees
* Track Pending Fees
* Generate Receipts
* Online Payment Support
* Reminder Notifications

---

## Notification Module

The system shall

* Send Push Notifications
* Send Notices
* Send Emergency Alerts
* Broadcast Messages

---

## Reports Module

Generate

* Attendance Reports
* Fee Reports
* Revenue Reports
* Student Performance Reports
* Teacher Reports

---

# 6. Non-Functional Requirements

Performance

* Dashboard loads within 3 seconds
* Attendance submission within 2 seconds
* Support 10,000 concurrent users across organizations

Availability

* 99.5% uptime

Security

* Role-Based Access Control
* JWT Authentication
* Encrypted Database Connections
* Secure File Storage
* HTTPS Only

Reliability

* Automatic Backup
* Data Recovery
* Audit Logs

Usability

* Material Design 3
* Responsive Layout
* Dark Mode
* Accessibility Support

Scalability

* Multi-Tenant Architecture
* Horizontal Scaling
* Modular Design

Maintainability

* Feature-Based Architecture
* Clean Architecture
* Repository Pattern

---

# 7. Data Requirements

Entities

* Organization
* User
* Student
* Parent
* Teacher
* Batch
* Subject
* Attendance
* Homework
* Assignment
* Exam
* Marks
* Fee
* Payment
* Notification
* Timetable
* Document

---

# 8. External Interfaces

Mobile Application

Flutter

Admin Dashboard

Flutter Web

Backend

Supabase

Authentication

Supabase Auth

Notifications

Firebase Cloud Messaging

Storage

Supabase Storage

Payment Gateway

Razorpay

---

# 9. Constraints

* Flutter for Mobile & Web
* Material Design 3
* Free-tier compatible architecture
* Offline-first
* Multi-tenant database
* Modular architecture

---

# 10. Future Scope

Phase 2

* Live Classes
* Chat
* Discussion Forum
* Parent Meetings
* Certificate Generator

Phase 3

School Support

* Library
* Transport
* Hostel
* Payroll
* Inventory
* Staff Management

Phase 4

College Support

* Semester Management
* Placements
* Alumni
* Clubs
* Academic Credits

---

# 11. Acceptance Criteria

The MVP shall be considered complete when:

* Student management is operational.
* Attendance can be recorded and reported.
* Fees can be created, tracked, and paid.
* Homework workflow is functional.
* Teachers can enter examination results.
* Parents receive notifications.
* Reports are generated successfully.
* Data synchronization works correctly.
* Offline mode functions as expected.
* The platform supports multiple coaching institutes independently.
