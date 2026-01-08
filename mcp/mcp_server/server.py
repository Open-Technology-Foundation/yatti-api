#!/usr/bin/env python3
"""YaTTi API MCP Server - RAG queries for specialized knowledgebases.

Provides MCP tools to query YaTTi knowledgebases using the yatti-api CLI.
"""

import asyncio
from typing import Optional
from mcp.server.fastmcp import FastMCP
from pydantic import Field

# Initialize MCP server
mcp = FastMCP("yatti")

# ============================================================================
# Knowledgebase Metadata
# ============================================================================

KB_INFO = {
    "appliedanthropology": {
        "short": "Applied anthropology research",
        "long": "Search applied anthropology knowledge covering human evolution, cultural development, and secular dharma."
    },
    "seculardharma": {
        "short": "Secular Buddhist philosophy",
        "long": "Search secular dharma philosophy, ethical living, and modern interpretations of dharma."
    },
    "jakartapost": {
        "short": "Indonesian news archives (1994-2005)",
        "long": "Search Jakarta Post archive for Indonesian politics, society, and historical events."
    },
    "peraturan": {
        "short": "Indonesian laws and regulations",
        "long": "Search Indonesian laws and regulations from peraturan.go.id for legal and compliance research."
    },
    "okusiassociates": {
        "short": "Indonesian business operations",
        "long": "Search Indonesian PMA company setup, corporate law, taxation, and business compliance knowledge."
    },
    "prosocial": {
        "short": "Social evolution research",
        "long": "Search psychology-philosophy insights into human motivations and behavior."
    },
    "wayang": {
        "short": "Indonesian wayang culture",
        "long": "Search Indonesian wayang culture, traditional puppet theater, and cultural anthropology."
    },
    "okusimail": {
        "short": "Email correspondence",
        "long": "Search Okusi Associates email correspondence for business inquiry patterns and responses."
    },
    "okusiresearch": {
        "short": "Investment research",
        "long": "Search Indonesian direct investment research, corporate law, and PMA management knowledge."
    },
    "ollama": {
        "short": "Ollama documentation",
        "long": "Search Ollama configuration, operation, and AI systems engineering knowledge."
    },
    "uv": {
        "short": "Full-stack programming",
        "long": "Search full-stack programming, AI systems engineering, and technical solutions."
    },
    "openai_docs": {
        "short": "OpenAI API documentation",
        "long": "Search OpenAI API documentation, models, and integration patterns."
    },
    "smi": {
        "short": "SMI domain research",
        "long": "Search SMI knowledgebase for specialized domain research."
    },
}

# ============================================================================
# Helper Functions
# ============================================================================

async def run_yatti_command(args: list[str], timeout: int = 120) -> str:
    """Execute yatti-api command and return output.

    Args:
        args: Command arguments to pass to yatti-api
        timeout: Command timeout in seconds (default: 120)

    Returns:
        Command output (stdout) or error message
    """
    try:
        proc = await asyncio.create_subprocess_exec(
            "yatti-api", *args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await asyncio.wait_for(
            proc.communicate(),
            timeout=timeout
        )

        if proc.returncode != 0:
            error_msg = stderr.decode().strip()
            if error_msg:
                return f"Error: {error_msg}"
            return f"Error: Command failed with exit code {proc.returncode}"

        return stdout.decode()

    except asyncio.TimeoutError:
        return f"Error: Command timed out after {timeout} seconds"
    except FileNotFoundError:
        return "Error: yatti-api command not found. Ensure it is installed and in PATH."
    except Exception as e:
        return f"Error: {str(e)}"


def format_kb_table() -> str:
    """Format knowledgebase list as markdown table."""
    lines = ["# Available Knowledgebases\n"]
    lines.append("| Name | Description |")
    lines.append("|------|-------------|")
    for name, info in sorted(KB_INFO.items()):
        lines.append(f"| {name} | {info['short']} |")
    return "\n".join(lines)


# ============================================================================
# Utility Tools
# ============================================================================

@mcp.tool(
    name="yatti_list_knowledgebases",
    annotations={
        "title": "List YaTTi Knowledgebases",
        "readOnlyHint": True,
        "idempotentHint": True
    }
)
async def yatti_list_knowledgebases() -> str:
    """List all available YaTTi knowledgebases with descriptions.

    Returns a table of knowledgebase names and descriptions to help
    identify which KB to query for a given topic.
    """
    return format_kb_table()


@mcp.tool(
    name="yatti_kb_info",
    annotations={
        "title": "Get Knowledgebase Info",
        "readOnlyHint": True,
        "idempotentHint": True
    }
)
async def yatti_kb_info(
    knowledgebase: str = Field(..., description="Name of the knowledgebase")
) -> str:
    """Get detailed information about a specific YaTTi knowledgebase.

    Returns the full description and metadata for the specified KB.
    """
    if knowledgebase not in KB_INFO:
        available = ", ".join(sorted(KB_INFO.keys()))
        return f"Error: Unknown knowledgebase '{knowledgebase}'. Available: {available}"

    # Get live info from API
    result = await run_yatti_command(["kb", "get", knowledgebase])

    info = KB_INFO[knowledgebase]
    return f"# {knowledgebase}\n\n{info['long']}\n\n## API Details\n\n{result}"


@mcp.tool(
    name="yatti_status",
    annotations={
        "title": "Check YaTTi API Status",
        "readOnlyHint": True,
        "idempotentHint": True
    }
)
async def yatti_status() -> str:
    """Check the health and status of the YaTTi API server.

    Returns server health information and availability status.
    """
    return await run_yatti_command(["status", "health"])


# ============================================================================
# Query Tools
# ============================================================================

@mcp.tool(
    name="yatti_query",
    annotations={
        "title": "Query YaTTi Knowledgebase",
        "readOnlyHint": True,
        "idempotentHint": True
    }
)
async def yatti_query(
    knowledgebase: str = Field(..., description="Knowledgebase to query (e.g., seculardharma, jakartapost)"),
    query: str = Field(..., description="Question or search query"),
    top_k: int = Field(5, description="Number of context sources to retrieve (1-50)", ge=1, le=50),
    temperature: float = Field(0.0, description="LLM temperature for response creativity (0.0-2.0)", ge=0.0, le=2.0),
    prompt_template: Optional[str] = Field(None, description="Response style: default, scholarly, technical, concise, analytical, conversational, instructive")
) -> str:
    """Query a YaTTi knowledgebase using RAG (Retrieval Augmented Generation).

    Searches the specified knowledgebase and returns an AI-generated response
    backed by relevant source material from the KB.

    Available knowledgebases:
    - appliedanthropology: Applied anthropology research
    - seculardharma: Secular Buddhist philosophy
    - jakartapost: Indonesian news archives (1994-2005)
    - peraturan: Indonesian laws and regulations
    - okusiassociates: Indonesian business operations
    - prosocial: Social evolution research
    - wayang: Indonesian wayang culture
    - okusimail: Email correspondence
    - okusiresearch: Investment research
    - ollama: Ollama documentation
    - uv: Full-stack programming
    - openai_docs: OpenAI API documentation
    - smi: SMI domain research
    """
    if knowledgebase not in KB_INFO:
        available = ", ".join(sorted(KB_INFO.keys()))
        return f"Error: Unknown knowledgebase '{knowledgebase}'. Available: {available}"

    args = [
        "query",
        "-K", knowledgebase,
        "-q", query,
        "--top-k", str(top_k),
        "--temperature", str(temperature),
    ]

    if prompt_template:
        args.extend(["--prompt-template", prompt_template])

    return await run_yatti_command(args, timeout=180)


@mcp.tool(
    name="yatti_query_context_only",
    annotations={
        "title": "Get KB Context Only",
        "readOnlyHint": True,
        "idempotentHint": True
    }
)
async def yatti_query_context_only(
    knowledgebase: str = Field(..., description="Knowledgebase to search"),
    query: str = Field(..., description="Search query"),
    top_k: int = Field(10, description="Number of context sources to retrieve (1-50)", ge=1, le=50)
) -> str:
    """Retrieve context sources from a knowledgebase without AI generation.

    Returns only the relevant source documents/excerpts without generating
    an AI response. Useful for seeing raw source material.
    """
    if knowledgebase not in KB_INFO:
        available = ", ".join(sorted(KB_INFO.keys()))
        return f"Error: Unknown knowledgebase '{knowledgebase}'. Available: {available}"

    args = [
        "query",
        "-K", knowledgebase,
        "-q", query,
        "--top-k", str(top_k),
        "--context-only"
    ]

    return await run_yatti_command(args, timeout=60)


@mcp.tool(
    name="yatti_history",
    annotations={
        "title": "View Query History",
        "readOnlyHint": True,
        "idempotentHint": True
    }
)
async def yatti_history(
    limit: int = Field(10, description="Number of recent queries to show", ge=1, le=100),
    knowledgebase: Optional[str] = Field(None, description="Filter by knowledgebase name")
) -> str:
    """View recent YaTTi query history.

    Shows past queries and their results. Optionally filter by knowledgebase.
    """
    args = ["history", str(limit)]

    if knowledgebase:
        if knowledgebase not in KB_INFO:
            available = ", ".join(sorted(KB_INFO.keys()))
            return f"Error: Unknown knowledgebase '{knowledgebase}'. Available: {available}"
        args.append(knowledgebase)

    return await run_yatti_command(args)


# ============================================================================
# Main Entry Point
# ============================================================================

if __name__ == "__main__":
    mcp.run()
