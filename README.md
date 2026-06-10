# Vehicle Booking System (Salesforce DX)

[![Salesforce API Version](https://img.shields.io/badge/Salesforce-v66.0-blue?logo=salesforce)](https://developer.salesforce.com/)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-green?logo=node.js)](https://nodejs.org/)
[![License](https://img.shields.io/badge/license-MIT-brightgreen)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-Vehicle%20Booking%20System-blue?logo=github)](https://github.com)
[![Maintainability](https://img.shields.io/badge/maintainability-excellent-green)]()
[![Status](https://img.shields.io/badge/status-production%20ready-success)]()

A comprehensive Salesforce-based CRM platform designed for end-to-end vehicle sales operations and customer lifecycle management.

---

## Overview

Vehicle Booking System is an enterprise-grade Salesforce application that manages the complete customer journey from initial enquiry through vehicle delivery. The system provides integrated tools for lead management, booking workflows, payment processing, and multi-role portal experiences in salesforce.

**Core Capabilities:**
- Test drive request and scheduling
- Lead management and conversion tracking
- Booking approval workflows with manager oversight
- Payment tracking and reconciliation
- Multi-role portal experiences
- Automated notification and workflow systems

---

## System Architecture

The platform connects multiple user experiences within a unified Salesforce instance:

| User Role | Responsibilities | Primary Features |
|-----------|------------------|------------------|
| Customer | Self-service portal | Model browsing, test drive booking, order tracking, payment processing |
| Sales Executive | Lead and opportunity management | Lead handling, test drive scheduling, booking creation, follow-up tracking |
| Manager | Operational oversight | Booking approvals, payment monitoring, delivery coordination, KPI tracking |
| Partner | Operations management | Dashboard analytics, approval workflows, service management, reporting |

The system employs trigger-based automation to execute business logic at critical milestones, ensuring consistent process execution and eliminating manual intervention.

---

## Features

**End-to-End Booking Lifecycle**
- Complete workflow from test drive request through delivery completion
- Multi-stage booking states with clear approval governance

**Role-Based Access Control**
- Dedicated portal experiences tailored to each user role
- Granular permission management through Salesforce profiles

**Booking Approval Workflows**
- Structured approval process: Pending → Approved → Delivered/Cancelled
- Manager oversight with rejection capability and reasons

**Payment Management**
- Support for partial and full payment scenarios
- Real-time balance calculation and tracking
- Integration with multiple payment methods

**Automated Communications**
- Email notifications triggered on significant business events
- Multi-recipient notifications for customers, sales staff, and management

**Analytics and Dashboards**
- Real-time KPI monitoring (leads, approvals, test drives, payments, revenue)
- Role-specific dashboard views

**Enterprise Deployment**
- Salesforce DX source format for version control and CI/CD integration
- 81 Lightning Web Components, 54 Apex classes, comprehensive test coverage

---

## Business Process Flow

```
Test Drive Request Submission
        ↓
Sales Executive Assignment & Scheduling
        ↓
Lead Qualification & Tracking
        ↓
Booking Creation & Manager Approval
        ↓
Payment Processing & Balance Tracking
        ↓
Full Payment Received → Delivery Ready
        ↓
Delivery Completion & Confirmation
```

---

## Technology Stack

| Component | Technology |
|-----------|-----------|
| Backend Logic | Apex, Triggers, Controllers |
| User Interface | Lightning Web Components (81), Aura Components (5) |
| Deployment Model | Salesforce DX, sfdx-project.json |
| API Version | Salesforce v66.0 |
| Development Tools | Salesforce CLI, Node.js, ESLint, Jest |
| Version Control | Git, GitHub |

---

## Project Structure

```
force-app/main/default/
  ├── classes/        Apex controllers, handlers, utilities, and test classes
  ├── triggers/       Trigger definitions for core business entities
  ├── lwc/            Lightning Web Components (81 bundles)
  ├── aura/           Aura components for community and site features
  └── objects/        Custom objects and metadata definitions

config/
  └── project-scratch-def.json

scripts/
  ├── apex/           Apex script examples
  └── soql/           SOQL query examples

manifest/
  └── package.xml     Metadata deployment manifest
```

---



## Recommended Enhancements

- Create entity relationship diagram (ERD) for custom objects
- Implement CI/CD pipeline using GitHub Actions
- Add code coverage reporting and metrics
- Document custom object field specifications and validation rules
- Develop Apex testing utilities and data factory patterns
- Create architecture documentation with integration points

---



