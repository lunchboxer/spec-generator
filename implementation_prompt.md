# Implementation Plan Generation Prompt

You are a senior software architect and technical lead tasked with creating a detailed Implementation Plan based on an existing Software Design Document.

Based on the design document provided below, generate a precise, actionable implementation plan consisting of discrete checklist items. Each item should represent a specific task that a development agent can execute independently.

## Instructions:

1. **Analyze the design document** thoroughly to understand all architectural decisions, components, and technical requirements
2. **Generate a complete implementation plan** that includes:
   - Technology Stack Setup Tasks
   - Environment Configuration Tasks
   - Component/Module Implementation Tasks
   - Database Implementation Tasks
   - API Implementation Tasks
   - User Interface Implementation Tasks
   - Integration Tasks
   - Security Implementation Tasks
   - Testing Implementation Tasks
   - Deployment Preparation Tasks

3. **Format each task** as a discrete, actionable item in a numbered markdown checklist
4. **Ensure each task** is:
   - Specific and actionable
   - Independent when possible
   - Clearly defined with expected outcomes
   - Estimated for complexity (Small/Medium/Large)
5. **Reference relevant sections** from the design when appropriate
6. **Include setup and configuration tasks** for all required tools and frameworks
7. **Break down complex tasks** into smaller sub-tasks when needed
8. **Consider dependencies** between tasks but keep items discrete

## Design Document:

[The design document will be inserted here by the script]

## Output Format:

Generate the implementation plan in Markdown format as a single, comprehensive numbered checklist:

```
# Implementation Plan for [Project Name]

1. [ ] [Task description] (Size: Small/Medium/Large)
2. [ ] [Task description] (Size: Small/Medium/Large)
   1. [ ] [Sub-task if needed]
   2. [ ] [Sub-task if needed]
3. [ ] [Task description] (Size: Small/Medium/Large)
...
```

Each task should follow these guidelines:
- Start with an imperative verb (Create, Implement, Configure, Set up, etc.)
- Be specific about what needs to be done
- Include technology names, file names, or component names when relevant
- Include size estimation in parentheses at the end
- Use sub-numbering only when breaking down complex tasks
- Be atomic enough that a development agent could complete it as a single unit of work

Example format:
```
1. [ ] Set up project repository with boilerplate structure for Node.js/Express application (Size: Small)
2. [ ] Configure ESLint and Prettier with standard rules for code quality enforcement (Size: Small)
3. [ ] Implement User Authentication API endpoints according to security specifications (Size: Large)
   1. [ ] Create login endpoint with JWT token generation
   2. [ ] Create user registration endpoint with password hashing
   3. [ ] Implement token refresh mechanism
4. [ ] Create database schema for User entity based on data model (Size: Medium)
```

Generate a comprehensive, actionable implementation plan now in this exact format.