# CONTRIBUTORS.md

This file provides guidance for contributors and AI agents working with code in this repository.

## Project Overview

This is an unofficial Elixir SDK for Langfuse, an open-source LLM observability platform. The SDK provides tracing capabilities for LLM applications, allowing developers to create traces, events, spans, generations, and scores.

## Development Commands

### Dependencies and Setup
```bash
mix deps.get              # Install dependencies
```

### Testing
```bash
mix test                  # Run all tests
mix test test/specific_test.exs  # Run specific test file
```

### OpenAPI Code Generation
```bash
mix sdk.build            # Regenerate API client from OpenAPI spec
mix spec.sync            # Download latest OpenAPI spec from Langfuse
mix api.gen default openapi.yml  # Generate client code from spec
```

### Documentation
```bash
mix docs                 # Generate documentation
```

## Architecture

### Core Structure
- `LangfuseSdk` - Main module providing `create/1`, `update/1`, `create_many/1` functions
- `LangfuseSdk.Ingestor` - Handles API payload transformation and ingestion
- `LangfuseSdk.Tracing.*` - Domain models (Trace, Event, Span, Generation, Score)
- `LangfuseSdk.Support.*` - Utilities for auth, client, media handling, value translation
- `LangfuseSdk.Generated.*` - Auto-generated API client code from OpenAPI spec

### Generated Code
The `lib/langfuse_sdk/generated/` directory contains auto-generated code from the Langfuse OpenAPI specification. This includes:
- `operations/` - API endpoint functions
- `schemas/` - Data structure definitions

**Important**: Only regenerate this code when updating to a new API version, as it may introduce breaking changes.

### Tracing Models
The SDK supports five main tracing entities:
- **Trace** - Top-level container for LLM application execution
- **Event** - Point-in-time occurrences within a trace
- **Span** - Time-bounded operations within a trace
- **Generation** - LLM API calls (supports image inputs via media handling)
- **Score** - Evaluation metrics for traces or observations

### Media Support
Generations support image inputs through automatic URL replacement handled by `LangfuseSdk.Support.Media`.

### Configuration
Set environment variables or config:
```elixir
config :langfuse_sdk,
  host: System.get_env("LANGFUSE_HOST"),
  secret_key: System.get_env("LANGFUSE_SECRET_KEY"),
  public_key: System.get_env("LANGFUSE_PUBLIC_KEY")
```

## Code Generation Workflow

When updating the SDK to match a new Langfuse API version:
1. Run `mix spec.sync` to download latest OpenAPI spec
2. Run `mix api.gen default openapi.yml` to regenerate client code
3. Test thoroughly as this may introduce breaking changes
4. Update any custom code that depends on generated schemas/operations

---

## Instructions for AI Agents

This section provides specific guidance for AI agents (Claude Code, etc.) working in this repository.

### Agent Guidelines
- Always use the TodoWrite tool to plan and track multi-step tasks
- Follow the existing code conventions and patterns in the codebase
- Check dependencies in `mix.exs` before introducing new libraries
- Use `mix test` to verify changes work correctly
- For OpenAPI regeneration, use `mix sdk.build` - but only when updating API versions

### Important Notes for Agents
- The `lib/langfuse_sdk/generated/` directory is auto-generated from OpenAPI specs
- Do not manually edit files in the `generated/` directory
- Generations support image inputs via automatic URL replacement (see `LangfuseSdk.Support.Media`)
- The main API entry points are `LangfuseSdk.create/1`, `LangfuseSdk.update/1`, and `LangfuseSdk.create_many/1`
- Configuration requires `LANGFUSE_HOST`, `LANGFUSE_SECRET_KEY`, and `LANGFUSE_PUBLIC_KEY` environment variables

### Testing Approach
- Run `mix test` for all tests
- Use `mix test test/specific_test.exs` for individual test files
- Test files are located in `test/` with support files in `test/support/`

### When Making Changes
1. Understand the tracing model hierarchy: Trace → Event/Span/Generation → Score
2. Check `LangfuseSdk.Ingestor` for payload transformation logic
3. Verify changes don't break the OpenAPI-generated client interface
4. Test with real Langfuse instances when possible