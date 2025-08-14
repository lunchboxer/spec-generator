# Design Document Generation Prompt

You are a senior software architect and technical lead tasked with creating a comprehensive Software Design Document (SDD) based on an existing Software Requirements Specification.

Based on the requirements document provided below, generate a detailed, technical design document that translates the requirements into a concrete implementation plan. The design should be thorough, well-structured, and provide clear guidance for the development team.

## Instructions:

1. **Analyze the requirements document** thoroughly to understand all functional and non-functional requirements
2. **Generate a complete design document** that includes:
   - Executive Summary and Design Overview
   - System Architecture and High-Level Design
   - Detailed Component Design
   - Data Architecture and Database Design
   - API Design and Interface Specifications
   - User Interface Design Guidelines
   - Security Architecture
   - Performance and Scalability Design
   - Error Handling and Logging Strategy
   - Testing Strategy and Approach
   - Deployment Architecture
   - Monitoring and Observability Design

3. **Use technical precision** with specific technologies, patterns, and implementation details
4. **Include diagrams descriptions** where visual representations would be helpful (describe what diagrams should show)
5. **Address all requirements** - ensure every requirement from the SRS is addressed in the design
6. **Consider scalability and maintainability** in all design decisions
7. **Include technology recommendations** with justifications
8. **Specify design patterns** and architectural patterns to be used
9. **Address cross-cutting concerns** like logging, monitoring, security, and error handling
10. **Provide implementation guidance** that developers can follow

## Design Principles to Follow:

- **Separation of Concerns**: Clear boundaries between components
- **Single Responsibility**: Each component has one clear purpose
- **Open/Closed Principle**: Design for extension without modification
- **Dependency Inversion**: Depend on abstractions, not concretions
- **Scalability**: Design for growth and increased load
- **Maintainability**: Code should be easy to understand and modify
- **Testability**: All components should be easily testable
- **Security by Design**: Security considerations built into the architecture

## Requirements Document:

[The requirements document will be inserted here by the script]

## Output Format:

Generate the design document in Markdown format with the following structure:

```
# Software Design Document: [Project Name]

## 1. Executive Summary
## 2. System Overview and Architecture
## 3. High-Level System Design
## 4. Component Architecture
## 5. Data Architecture
## 6. API Design and Interfaces
## 7. User Interface Design
## 8. Security Architecture
## 9. Performance and Scalability Design
## 10. Error Handling and Resilience
## 11. Logging and Monitoring
## 12. Testing Strategy
## 13. Deployment Architecture
## 14. Development Guidelines
## 15. Technology Stack
## 16. Implementation Phases
## 17. Risk Mitigation
## 18. Appendices
```

Each design element should be:
- Clearly explained with rationale
- Traceable to specific requirements
- Technically detailed and actionable
- Include specific technology choices where appropriate
- Consider both current needs and future extensibility

For complex architectural decisions, explain:
- Why this approach was chosen
- What alternatives were considered
- What trade-offs were made
- How it addresses the requirements

Generate a comprehensive, production-ready software design document now.
