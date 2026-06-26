# GoPrepared

## Product Specification & Development Roadmap

### Tagline

Be Ready Anywhere

### Product Vision

GoPrepared is an AI-powered Preparation Intelligence Platform that helps users prepare for trips, events, procedures, exams, activities, life milestones, and experiences.

Instead of answering questions like a chatbot, GoPrepared generates structured Preparation Journeys consisting of preparation cards, checklists, knowledge topics, community insights, and warnings.

Examples:

* Vacation to Bali
* Vizag 10K Run
* Angiogram Procedure
* GRE Exam
* First International Flight
* Schengen Visa Interview

The system continuously builds a Preparation Knowledge Graph from user journeys and community contributions.

---

# Core Concepts

## Journey

A Journey is the primary object.

Examples:

* Bali Vacation
* Angiogram
* Vizag 10K

Every journey contains:

* Classification
* Cards
* Checklist
* Topics
* Community Contributions
* Progress

---

## Journey Type

Examples:

* Travel
* Health
* Sports
* Education
* Career
* Government
* Events
* Finance
* Personal

---

## Journey Subtype

Examples:

Travel:

* Vacation
* Business Travel
* Pilgrimage

Health:

* Medical Procedure
* Surgery
* Diagnostic Test

Sports:

* Marathon
* 10K Run
* Cycling

---

## Card

A high-level preparation topic.

Examples:

* Visa Requirements
* Packing Checklist
* Safety Tips
* Weather
* Recovery Instructions

---

## Knowledge Node

Reusable concepts extracted from journeys.

Examples:

* Bali
* Visa
* Weather
* Angiogram
* Running

---

## Community Insight

User-generated contribution.

Types:

* Tip
* Warning
* Experience
* Update

---

# Technical Architecture

Frontend:

* Flutter
* Android
* iOS
* PWA

Backend:

* Spring Boot 3.x
* Java 21

Database:

* PostgreSQL

AI Layer:

* Spring AI
* OpenAI initially
* Ollama optional later

Vector Search:

* pgvector

Authentication:

* Google OAuth

Storage:

* PostgreSQL
* Object storage later

---

# MVP 1

## AI Preparation Journey Generator

Goal:
Validate user demand.

### Features

#### Authentication

Google Login

User Profile

#### Discover Screen

Input:

"What are you preparing for?"

Examples:

* Vacation to Bali
* Angiogram
* Vizag 10K

Generate Journey Button

#### Journey Creation

User enters free text.

AI extracts:

* Journey Type
* Journey Subtype
* Activity
* Location

Example:

Input:
Vacation to Bali

Output:

Travel
Vacation
Vacation
Bali

#### Preparation Deck

Generate 8-15 cards.

Examples:

* Visa
* Weather
* Packing
* Safety
* Transportation

Each card contains:

* Title
* Summary
* Icon
* Category

#### Card Expansion

Click card.

Generate detailed content.

#### Journey Persistence

Store:

* Query
* Classification
* Cards
* Expanded content

#### My Journeys

List all journeys.

Resume previous journeys.

---

# MVP 2

## Preparation Dashboard & Checklists

Goal:
Increase retention.

### Journey Dashboard

Example:

Bali Vacation

Progress:
40%

Cards Completed:
5/12

Checklist:
8/20

Tips:
12

Warnings:
3

---

### Checklist Engine

Generate checklist automatically.

Examples:

Packing
Documents
Health

Each item:

* Title
* Description
* Completion Status

---

### Saved Cards

Users bookmark cards.

---

### Journey Progress

Track:

* Viewed Cards
* Completed Checklist Items
* Saved Items

---

### Reminder System

Optional notifications.

Examples:

"Passport checklist incomplete"

"Race day in 3 days"

---

# MVP 3

## Knowledge Graph & Semantic Intelligence

Goal:
Create defensible IP.

### Knowledge Graph Extraction

Every journey generates:

Nodes:

* Journey Type
* Activity
* Location
* Topics

Relationships:

Travel
-> Vacation

Vacation
-> Bali

Bali
-> Visa

Bali
-> Weather

---

### Knowledge Explorer

Knowledge Tab

Browse:

Travel
Health
Sports
Education

Drill down.

---

### Similar Journey Search

User enters:

Trip to Phuket

System retrieves:

Bali Vacation
Thailand Travel

before AI generation.

---

### Embeddings

Store vectors for:

Journey
Card
Knowledge Node

Use pgvector.

---

### Knowledge Recommendations

Examples:

Users preparing for Bali also viewed:

* Thailand Travel
* First International Flight

---

# MVP 4

## Community Intelligence Platform

Goal:
Network effects.

### Community Screen

Contribution Types:

Tip
Warning
Experience
Update

---

### Add Contribution

Examples:

Tip:
Buy SIM card outside airport.

Warning:
Temple dress code enforced.

---

### Voting

Helpful

Not Helpful

---

### Verification

Community Confirmation

Examples:

Verified by 12 travelers

Confirmed by 8 participants

---

### Reputation

User earns:

Contribution Score

Impact Score

Verified Contributor Status

---

### Community Insights in Journeys

Show:

Top Tips

Top Warnings

Recent Experiences

---

# Database Design

## users

id
google_id
name
email
profile_picture
created_at

---

## journey_types

id
name

---

## journey_subtypes

id
journey_type_id
name

---

## activities

id
name

---

## locations

id
name
country
type

---

## journeys

id
user_id
title
original_query
journey_type_id
journey_subtype_id
activity_id
location_id
status
created_at

---

## cards

id
journey_id
title
summary
category
display_order

---

## card_details

id
card_id
content

---

## checklist_items

id
journey_id
title
description
completed

---

## knowledge_nodes

id
node_type
name
description
metadata

---

## knowledge_edges

id
source_node_id
target_node_id
relationship_type

---

## community_insights

id
journey_id
user_id
insight_type
title
content
votes
status

---

# AI Workflows

## Workflow 1

Journey Classification

Input:
Vacation to Bali

Output:

Journey Type
Journey Subtype
Activity
Location

---

## Workflow 2

Card Generation

Input:
Classified Journey

Output:
Preparation Cards

---

## Workflow 3

Card Expansion

Input:
Card

Output:
Detailed Content

---

## Workflow 4

Checklist Generation

Input:
Journey

Output:
Checklist

---

## Workflow 5

Knowledge Graph Extraction

Input:
Journey + Cards

Output:

Nodes
Relationships

---

# REST APIs

POST /journeys

POST /journeys/{id}/generate

GET /journeys

GET /journeys/{id}

GET /journeys/{id}/cards

GET /cards/{id}

GET /journeys/{id}/checklist

POST /checklist/{id}/complete

GET /knowledge/categories

GET /knowledge/nodes

GET /knowledge/relationships

GET /community

POST /community/contribute

POST /community/vote

---

# Success Metrics

MVP1:

* Journey Creation Rate
* Card Expansion Rate

MVP2:

* Journey Completion Rate
* Checklist Usage

MVP3:

* Knowledge Reuse Rate
* Similar Journey Usage

MVP4:

* Community Contribution Rate
* Helpful Vote Ratio

---

# Long-Term Vision

GoPrepared evolves from:

AI Journey Generator

to

Preparation Intelligence Platform

to

Preparation Knowledge Graph

to

Preparation API Platform

Any external application can eventually send:

"Vacation to Bali"

and receive:

* Preparation Cards
* Checklists
* Knowledge Topics
* Community Insights
* Warnings
* Recommendations
* Structured Graph Data
