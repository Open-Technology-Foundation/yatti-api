"""Tests for run_yatti_command subprocess hygiene and query validation.

A fake `yatti-api` script is placed first on PATH so no real CLI or network
is involved. Under MCP stdio transport the server's stdin is the protocol
pipe; a child inheriting it can consume protocol bytes and corrupt the
session, so the subprocess must get /dev/null as stdin.

Note: the tool functions are called with ALL parameters explicit — calling
them outside FastMCP leaves defaulted params as pydantic FieldInfo objects,
which is not how the framework invokes them.
"""

import os
import stat
import sys

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from mcp_server.server import run_yatti_command, yatti_query, yatti_query_context_only


@pytest.fixture
def fake_yatti(tmp_path, monkeypatch):
    """PATH-shim yatti-api: reports the child's stdin target, marks invocation."""
    marker = tmp_path / "invoked"
    script = tmp_path / "yatti-api"
    script.write_text(
        "#!/bin/bash\n"
        f"touch '{marker}'\n"
        "readlink /proc/self/fd/0\n"
    )
    script.chmod(script.stat().st_mode | stat.S_IXUSR)
    monkeypatch.setenv("PATH", f"{tmp_path}:{os.environ['PATH']}")
    return marker


@pytest.fixture
def pipe_stdin():
    """Replace fd 0 with a pipe so stdin inheritance is observable.

    Under pytest the parent's stdin is already /dev/null, which makes
    inheritance indistinguishable from an explicit DEVNULL.
    """
    read_end, write_end = os.pipe()
    saved = os.dup(0)
    os.dup2(read_end, 0)
    try:
        yield
    finally:
        os.dup2(saved, 0)
        for fd in (saved, read_end, write_end):
            os.close(fd)


@pytest.mark.asyncio
async def test_subprocess_stdin_is_devnull(fake_yatti, pipe_stdin):
    out = await run_yatti_command(["status"], timeout=10)
    assert "/dev/null" in out, f"child stdin was {out.strip()!r}, not /dev/null"


@pytest.mark.asyncio
async def test_empty_query_rejected_without_spawning(fake_yatti):
    out = await yatti_query(
        knowledgebase="uv", query="", top_k=5, temperature=0.0, prompt_template=None
    )
    assert out.startswith("Error:")
    assert not fake_yatti.exists(), "CLI must not be invoked for an empty query"


@pytest.mark.asyncio
async def test_dash_query_rejected_without_spawning(fake_yatti):
    # "-" tells the CLI to read the query from stdin — meaningless under MCP
    out = await yatti_query(
        knowledgebase="uv", query="-", top_k=5, temperature=0.0, prompt_template=None
    )
    assert out.startswith("Error:")
    assert not fake_yatti.exists()


@pytest.mark.asyncio
async def test_whitespace_query_rejected_without_spawning(fake_yatti):
    out = await yatti_query_context_only(knowledgebase="uv", query="   ", top_k=10)
    assert out.startswith("Error:")
    assert not fake_yatti.exists()


@pytest.mark.asyncio
async def test_valid_query_still_invokes_cli(fake_yatti):
    out = await yatti_query(
        knowledgebase="uv", query="what is uv?", top_k=5, temperature=0.0,
        prompt_template=None,
    )
    assert fake_yatti.exists()
    assert not out.startswith("Error:")
