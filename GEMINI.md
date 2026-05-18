# GEMINI.md - fodok-crawler

## Project Overview
`fodok-crawler` is a hybrid Clojure/Ruby tool designed to extract research data from the Johannes Kepler University (JKU) Research Documentation System (FODOK) and convert it into LaTeX snippets. It is primarily used for generating "Aktivitätsberichte" (activity reports).

### Architecture & Data Flow
The project follows a two-stage process:
1.  **Crawling (Clojure):**
    *   Fetches high-level XML data for a specific research unit (FE_ID=348).
    *   Iterates through items (publications, talks, research projects, services) to fetch detailed metadata (DOIs, locations, project leaders) from specific FODOK URLs.
    *   Outputs structured data into CSV files in the `data/` directory.
2.  **LaTeX Generation (Ruby):**
    *   Reads the generated CSV files.
    *   Sanitizes and formats the data for LaTeX.
    *   Partitions data into specific categories (e.g., Working Papers, Press Articles).
    *   Produces `.tex` files in the `data/` directory ready for inclusion in a LaTeX document.

## Building and Running

### Prerequisites
*   [Leiningen](https://leiningen.org/) (Clojure build tool)
*   [Ruby](https://www.ruby-lang.org/)

### Key Commands
*   **Run the entire pipeline:** `lein run`
    *   This executes the Clojure crawler and automatically triggers the Ruby LaTeX generator.
*   **Run tests:** `lein test`
*   **Start a REPL:** `lein repl` (initialized with `fodok-crawler.core`)

## Development Conventions

### Coding Style
*   **Clojure:** Follows standard Clojure idiomatic patterns. Uses `clj-http` for networking and `clojure.data.xml` for parsing. The `fodok-crawler.util` namespace contains generic helpers for XML and CSV handling.
*   **Ruby:** A procedural script (`latextify.rb`) that uses the standard `CSV` library. It includes a `sanitize` method to handle LaTeX special characters.

### Project Structure
*   `src/fodok_crawler/`: Clojure source files.
    *   `core.clj`: Main orchestration logic.
    *   `doi.clj`: Metadata enrichment (DOI, Places, etc.).
    *   `util.clj`: XML parsing and CSV utilities.
*   `src/latextify/`: Ruby scripts for LaTeX processing.
*   `data/`: Directory for intermediate CSVs and final `.tex` outputs.
*   `test/`: Unit tests for Clojure code.

### Dependencies
*   **Clojure:** `clj-http`, `clojure.data.csv`, `tools.namespace`.
*   **Ruby:** No external gems required (uses standard library).

## Key Files
*   `project.clj`: Leiningen project configuration and dependencies.
*   `src/fodok_crawler/core.clj`: Entry point; defines which research unit to crawl.
*   `src/latextify/latextify.rb`: Logic for grouping and formatting LaTeX output.
