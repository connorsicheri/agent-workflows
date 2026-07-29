#!/usr/bin/env python3
"""Run and summarize reproducible Compass benchmark tasks."""

from __future__ import annotations

import argparse
import csv
import fnmatch
import json
import os
from pathlib import Path
import random
import shutil
import signal
import statistics
import subprocess
import sys
import tempfile
import time
import uuid
from collections import defaultdict
from datetime import datetime, timezone
from typing import Any


BENCHMARK_ROOT = Path(__file__).resolve().parent
REPOSITORY_ROOT = BENCHMARK_ROOT.parent
PROFILES_PATH = BENCHMARK_ROOT / "profiles.json"
TASKS_PATH = BENCHMARK_ROOT / "tasks"
DEFAULT_RESULTS_PATH = BENCHMARK_ROOT / "results"


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def load_profiles() -> dict[str, dict[str, Any]]:
    profiles = read_json(PROFILES_PATH)
    return {profile["id"]: profile for profile in profiles}


def load_tasks() -> dict[str, dict[str, Any]]:
    tasks: dict[str, dict[str, Any]] = {}
    for path in sorted(TASKS_PATH.glob("*.json")):
        task = read_json(path)
        task["manifest_path"] = str(path)
        tasks[task["id"]] = task
    return tasks


def select_items(
    requested: str,
    available: dict[str, dict[str, Any]],
    *,
    allow_core: bool = False,
) -> list[dict[str, Any]]:
    if requested == "all":
        return list(available.values())
    if allow_core and requested == "core":
        return [item for item in available.values() if item.get("core")]

    identifiers = [item.strip() for item in requested.split(",") if item.strip()]
    missing = [identifier for identifier in identifiers if identifier not in available]
    if missing:
        raise ValueError(f"unknown identifiers: {', '.join(missing)}")
    return [available[identifier] for identifier in identifiers]


def command_text(command: list[str]) -> str:
    return " ".join(json.dumps(part) if any(char.isspace() for char in part) else part for part in command)


def task_prompt(task: dict[str, Any], mode: str) -> str:
    validation = "\n".join(
        f"- {command_text(command)}" for command in task["agent_validation"]
    )
    prompt = (
        f"{task['prompt']}\n\n"
        "Work only in the current repository. Do not use network access. "
        "Do not modify tests, create unrelated files, or commit changes.\n\n"
        f"Public validation:\n{validation}"
    )
    if mode == "single":
        return (
            "Complete this task as one agent. Do not spawn or delegate to subagents. "
            "Inspect, implement, validate, and report the result directly.\n\n"
            + prompt
        )
    return prompt


def build_command(
    profile: dict[str, Any],
    workspace: Path,
    prompt: str,
    max_budget_usd: float | None,
) -> list[str]:
    if profile["provider"] == "codex":
        if profile["mode"] == "compass":
            prompt = "Use $compass-codex:compass to complete this task.\n\n" + prompt
        return [
            "codex",
            "-C",
            str(workspace),
            "-m",
            profile["model"],
            "-s",
            "workspace-write",
            "-a",
            "on-request",
            "-c",
            f'model_reasoning_effort="{profile["effort"]}"',
            "-c",
            "sandbox_workspace_write.network_access=false",
            "exec",
            "--ephemeral",
            "--json",
            prompt,
        ]

    command = [
        "claude",
        "-p",
        "--output-format",
        "json",
        "--no-session-persistence",
        "--permission-mode",
        "acceptEdits",
        "--disallowedTools",
        "WebFetch,WebSearch",
    ]
    if profile["mode"] == "compass":
        command.extend(
            [
                "--plugin-dir",
                str(REPOSITORY_ROOT / "compass-claude"),
                "--agent",
                "compass:compass-orchestrator",
                "--allowedTools",
                "Bash,Edit,Read,Glob,Grep,Write,Agent",
            ]
        )
    else:
        command.extend(
            [
                "--model",
                profile["model"],
                "--effort",
                profile["effort"],
                "--allowedTools",
                "Bash,Edit,Read,Glob,Grep,Write",
            ]
        )
    if max_budget_usd is not None:
        command.extend(["--max-budget-usd", str(max_budget_usd)])
    # Both tool-list flags are variadic in the Claude CLI. Separate the
    # positional prompt so it is not consumed as another allowed tool.
    command.extend(["--", prompt])
    return command


def run_process(
    command: list[str],
    *,
    cwd: Path,
    timeout_seconds: int,
) -> tuple[int, str, str, bool, float]:
    started = time.monotonic()
    environment = os.environ.copy()
    for variable in (
        "CODEX_CI",
        "CODEX_INTERNAL_ORIGINATOR_OVERRIDE",
        "CODEX_PERMISSION_PROFILE",
        "CODEX_THREAD_ID",
    ):
        environment.pop(variable, None)
    process = subprocess.Popen(
        command,
        cwd=cwd,
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        start_new_session=True,
    )
    timed_out = False
    try:
        stdout, stderr = process.communicate(timeout=timeout_seconds)
    except subprocess.TimeoutExpired:
        timed_out = True
        if os.name == "posix":
            os.killpg(process.pid, signal.SIGTERM)
        else:
            process.terminate()
        try:
            stdout, stderr = process.communicate(timeout=10)
        except subprocess.TimeoutExpired:
            if os.name == "posix":
                os.killpg(process.pid, signal.SIGKILL)
            else:
                process.kill()
            stdout, stderr = process.communicate()
    elapsed = time.monotonic() - started
    return process.returncode, stdout, stderr, timed_out, elapsed


def empty_usage() -> dict[str, Any]:
    return {
        "input_tokens": 0,
        "cached_input_tokens": 0,
        "cache_creation_input_tokens": 0,
        "output_tokens": 0,
        "reasoning_output_tokens": 0,
        "total_tokens": 0,
        "cost_usd": None,
        "usage_event_count": 0,
        "model_usage": {},
    }


def token_value(source: dict[str, Any], snake: str, camel: str) -> int:
    value = source.get(snake, source.get(camel, 0))
    return int(value or 0)


def parse_codex_usage(stdout: str, profile: dict[str, Any]) -> dict[str, Any]:
    result = empty_usage()
    model_usage: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))

    for line in stdout.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("type") != "turn.completed" or not isinstance(event.get("usage"), dict):
            continue

        usage = event["usage"]
        normalized = {
            "input_tokens": token_value(usage, "input_tokens", "inputTokens"),
            "cached_input_tokens": token_value(
                usage, "cached_input_tokens", "cachedInputTokens"
            ),
            "output_tokens": token_value(usage, "output_tokens", "outputTokens"),
            "reasoning_output_tokens": token_value(
                usage, "reasoning_output_tokens", "reasoningOutputTokens"
            ),
        }
        for key, value in normalized.items():
            result[key] += value

        model = event.get("model")
        if not model and profile["mode"] == "single":
            model = profile["model"]
        model = model or "unattributed"
        for key, value in normalized.items():
            model_usage[model][key] += value
        result["usage_event_count"] += 1

    result["total_tokens"] = result["input_tokens"] + result["output_tokens"]
    result["model_usage"] = {
        model: dict(values) for model, values in sorted(model_usage.items())
    }
    return result


def parse_json_object(stdout: str) -> dict[str, Any]:
    try:
        value = json.loads(stdout)
        return value if isinstance(value, dict) else {}
    except json.JSONDecodeError:
        pass

    for line in reversed(stdout.splitlines()):
        try:
            value = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict):
            return value
    return {}


def normalize_claude_usage(source: dict[str, Any]) -> dict[str, int]:
    return {
        "input_tokens": token_value(source, "input_tokens", "inputTokens"),
        "cache_creation_input_tokens": token_value(
            source, "cache_creation_input_tokens", "cacheCreationInputTokens"
        ),
        "cached_input_tokens": token_value(
            source, "cache_read_input_tokens", "cacheReadInputTokens"
        ),
        "output_tokens": token_value(source, "output_tokens", "outputTokens"),
    }


def parse_claude_usage(stdout: str) -> dict[str, Any]:
    payload = parse_json_object(stdout)
    result = empty_usage()
    normalized = normalize_claude_usage(payload.get("usage", {}))
    result.update(normalized)
    result["total_tokens"] = sum(normalized.values())
    result["cost_usd"] = payload.get("total_cost_usd", payload.get("totalCostUsd"))
    result["usage_event_count"] = 1 if payload else 0

    raw_model_usage = payload.get("modelUsage", payload.get("model_usage", {}))
    model_usage: dict[str, Any] = {}
    if isinstance(raw_model_usage, dict):
        for model, usage in raw_model_usage.items():
            if not isinstance(usage, dict):
                continue
            model_result = normalize_claude_usage(usage)
            model_result["total_tokens"] = sum(model_result.values())
            model_result["cost_usd"] = usage.get("costUSD", usage.get("cost_usd"))
            model_usage[model] = model_result
    result["model_usage"] = model_usage
    return result


def prepare_workspace(task: dict[str, Any]) -> tuple[Path, Path]:
    temp_root = Path(
        tempfile.mkdtemp(
            prefix=f".workspace-{task['id']}-",
            dir=BENCHMARK_ROOT / "results",
        )
    ).resolve()
    workspace = temp_root / "repo"
    shutil.copytree(BENCHMARK_ROOT / task["fixture"], workspace)

    git_commands = [
        ["git", "init", "-q"],
        ["git", "config", "user.name", "Compass Benchmark"],
        ["git", "config", "user.email", "benchmark@example.invalid"],
        ["git", "add", "."],
        ["git", "commit", "-qm", "benchmark baseline"],
    ]
    for command in git_commands:
        subprocess.run(command, cwd=workspace, check=True, capture_output=True, text=True)
    return temp_root, workspace


def changed_files(workspace: Path) -> list[str]:
    result = subprocess.run(
        ["git", "status", "--short"],
        cwd=workspace,
        check=True,
        capture_output=True,
        text=True,
    )
    files: list[str] = []
    for line in result.stdout.splitlines():
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        files.append(path)
    return sorted(files)


def matches_any(path: str, patterns: list[str]) -> bool:
    return any(fnmatch.fnmatch(path, pattern) for pattern in patterns)


def validate_result(task: dict[str, Any], workspace: Path) -> tuple[list[dict[str, Any]], float]:
    commands = list(task["agent_validation"])
    commands.append([sys.executable, str(BENCHMARK_ROOT / task["grader"]), str(workspace)])

    started = time.monotonic()
    results: list[dict[str, Any]] = []
    for command in commands:
        completed = subprocess.run(
            command,
            cwd=workspace,
            capture_output=True,
            text=True,
            timeout=120,
        )
        results.append(
            {
                "command": command,
                "exit_code": completed.returncode,
                "stdout": completed.stdout,
                "stderr": completed.stderr,
                "passed": completed.returncode == 0,
            }
        )
    return results, time.monotonic() - started


def tool_version(provider: str) -> str:
    completed = subprocess.run(
        [provider, "--version"], capture_output=True, text=True, timeout=20
    )
    return (completed.stdout or completed.stderr).strip()


def run_one(
    task: dict[str, Any],
    profile: dict[str, Any],
    repetition: int,
    *,
    results_root: Path,
    timeout_seconds: int,
    max_budget_usd: float | None,
    keep_workspace: bool,
) -> dict[str, Any]:
    temp_root, workspace = prepare_workspace(task)
    prompt = task_prompt(task, profile["mode"])
    command = build_command(profile, workspace, prompt, max_budget_usd)
    started_at = datetime.now(timezone.utc)

    run_name = (
        f"{started_at.strftime('%Y%m%dT%H%M%SZ')}-"
        f"{task['id']}-{profile['id']}-r{repetition}-{uuid.uuid4().hex[:8]}"
    )
    run_dir = results_root / run_name
    run_dir.mkdir(parents=True, exist_ok=False)
    (run_dir / "prompt.txt").write_text(prompt, encoding="utf-8")
    (run_dir / "command.json").write_text(
        json.dumps(command, indent=2) + "\n", encoding="utf-8"
    )

    exit_code, stdout, stderr, timed_out, agent_seconds = run_process(
        command, cwd=workspace, timeout_seconds=timeout_seconds
    )
    (run_dir / "stdout.log").write_text(stdout, encoding="utf-8")
    (run_dir / "stderr.log").write_text(stderr, encoding="utf-8")

    validations, grading_seconds = validate_result(task, workspace)
    changed = changed_files(workspace)
    allowed = all(matches_any(path, task["allowed_changed_files"]) for path in changed)
    required = all(
        any(fnmatch.fnmatch(path, pattern) for path in changed)
        for pattern in task["required_changed_files"]
    )
    validation_passed = all(item["passed"] for item in validations)
    usage = (
        parse_codex_usage(stdout, profile)
        if profile["provider"] == "codex"
        else parse_claude_usage(stdout)
    )

    diff = subprocess.run(
        ["git", "diff", "--no-ext-diff", "HEAD"],
        cwd=workspace,
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    (run_dir / "changes.diff").write_text(diff, encoding="utf-8")
    (run_dir / "validation.json").write_text(
        json.dumps(validations, indent=2) + "\n", encoding="utf-8"
    )

    correct = (
        exit_code == 0
        and not timed_out
        and validation_passed
        and allowed
        and required
    )
    result = {
        "run_id": run_name,
        "task_id": task["id"],
        "task_title": task["title"],
        "task_category": task["category"],
        "profile_id": profile["id"],
        "provider": profile["provider"],
        "mode": profile["mode"],
        "configured_model": profile["model"],
        "configured_effort": profile["effort"],
        "tool_version": tool_version(profile["provider"]),
        "started_at": started_at.isoformat(),
        "agent_wall_seconds": round(agent_seconds, 6),
        "grading_seconds": round(grading_seconds, 6),
        "end_to_end_seconds": round(agent_seconds + grading_seconds, 6),
        "exit_code": exit_code,
        "timed_out": timed_out,
        "usage": usage,
        "changed_files": changed,
        "allowed_files_only": allowed,
        "required_files_changed": required,
        "validation_passed": validation_passed,
        "correct": correct,
        "expected_compass_routing": task["expected_compass_routing"],
        "workspace": str(workspace) if keep_workspace else None,
    }
    (run_dir / "result.json").write_text(
        json.dumps(result, indent=2) + "\n", encoding="utf-8"
    )

    if not keep_workspace:
        shutil.rmtree(temp_root)
    return result


def validate_suite(check_clis: bool) -> int:
    profiles = load_profiles()
    tasks = load_tasks()
    errors: list[str] = []

    for profile in profiles.values():
        if profile["provider"] not in {"codex", "claude"}:
            errors.append(f"{profile['id']}: unsupported provider")
        if profile["mode"] not in {"single", "compass"}:
            errors.append(f"{profile['id']}: unsupported mode")
        baseline = profile.get("baseline_profile")
        if baseline and baseline not in profiles:
            errors.append(f"{profile['id']}: missing baseline profile {baseline}")

    for task in tasks.values():
        fixture = BENCHMARK_ROOT / task["fixture"]
        grader = BENCHMARK_ROOT / task["grader"]
        if not fixture.is_dir():
            errors.append(f"{task['id']}: missing fixture {fixture}")
            continue
        if not grader.is_file():
            errors.append(f"{task['id']}: missing grader {grader}")
        for path in task["required_changed_files"]:
            if not (fixture / path).is_file():
                errors.append(f"{task['id']}: required file missing from fixture: {path}")

        temp_root, workspace = prepare_workspace(task)
        try:
            validations, _ = validate_result(task, workspace)
            if all(item["passed"] for item in validations):
                errors.append(f"{task['id']}: baseline unexpectedly passes every validator")
        finally:
            shutil.rmtree(temp_root)

    if check_clis:
        for provider in ("codex", "claude"):
            if shutil.which(provider) is None:
                errors.append(f"missing CLI: {provider}")

    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        return 1
    print(f"Validated {len(tasks)} tasks and {len(profiles)} profiles.")
    return 0


def result_files(results_root: Path) -> list[Path]:
    return sorted(results_root.glob("*/result.json"))


def median_or_none(values: list[float | int]) -> float | None:
    return float(statistics.median(values)) if values else None


def summarize_results(results_root: Path) -> list[dict[str, Any]]:
    profiles = load_profiles()
    grouped: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for path in result_files(results_root):
        result = read_json(path)
        grouped[(result["task_id"], result["profile_id"])].append(result)

    rows: list[dict[str, Any]] = []
    medians: dict[tuple[str, str], float] = {}
    for (task_id, profile_id), runs in sorted(grouped.items()):
        correct_runs = [run for run in runs if run["correct"]]
        median_seconds = median_or_none(
            [run["agent_wall_seconds"] for run in correct_runs]
        )
        if median_seconds is not None:
            medians[(task_id, profile_id)] = median_seconds
        row = {
            "task_id": task_id,
            "profile_id": profile_id,
            "provider": runs[0]["provider"],
            "mode": runs[0]["mode"],
            "model": runs[0]["configured_model"],
            "effort": runs[0]["configured_effort"],
            "runs": len(runs),
            "correct_runs": len(correct_runs),
            "success_rate": len(correct_runs) / len(runs),
            "median_seconds": median_seconds,
            "median_total_tokens": median_or_none(
                [run["usage"]["total_tokens"] for run in correct_runs]
            ),
            "median_cost_usd": median_or_none(
                [
                    run["usage"]["cost_usd"]
                    for run in correct_runs
                    if run["usage"]["cost_usd"] is not None
                ]
            ),
            "speedup_vs_baseline": None,
        }
        rows.append(row)

    for row in rows:
        baseline = profiles[row["profile_id"]].get("baseline_profile")
        current = row["median_seconds"]
        baseline_seconds = medians.get((row["task_id"], baseline)) if baseline else None
        if current and baseline_seconds:
            row["speedup_vs_baseline"] = baseline_seconds / current
    return rows


def format_value(value: Any, digits: int = 2) -> str:
    if value is None:
        return "-"
    if isinstance(value, float):
        return f"{value:.{digits}f}"
    return str(value)


def print_markdown(rows: list[dict[str, Any]]) -> None:
    headers = [
        "Task",
        "Profile",
        "Model",
        "Effort",
        "Correct",
        "Median s",
        "Median tokens",
        "Median USD",
        "Speedup",
    ]
    print("| " + " | ".join(headers) + " |")
    print("| " + " | ".join(["---"] * len(headers)) + " |")
    for row in rows:
        values = [
            row["task_id"],
            row["profile_id"],
            row["model"],
            row["effort"],
            f"{row['correct_runs']}/{row['runs']}",
            format_value(row["median_seconds"]),
            format_value(row["median_total_tokens"], 0),
            format_value(row["median_cost_usd"], 4),
            (
                f"{row['speedup_vs_baseline']:.2f}x"
                if row["speedup_vs_baseline"] is not None
                else "-"
            ),
        ]
        print("| " + " | ".join(values) + " |")


def write_csv(rows: list[dict[str, Any]], output: Path | None) -> None:
    stream = output.open("w", newline="", encoding="utf-8") if output else sys.stdout
    try:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0].keys()) if rows else [])
        writer.writeheader()
        writer.writerows(rows)
    finally:
        if output:
            stream.close()


def list_suite() -> None:
    print("Tasks:")
    for task in load_tasks().values():
        print(f"  {task['id']}: {task['title']} [{task['category']}]")
    print("\nProfiles:")
    for profile in load_profiles().values():
        core = " core" if profile.get("core") else ""
        print(
            f"  {profile['id']}: {profile['provider']} {profile['mode']} "
            f"{profile['model']} {profile['effort']}{core}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("list", help="List tasks and profiles")

    validate_parser = subparsers.add_parser("validate", help="Validate fixtures and manifests")
    validate_parser.add_argument("--check-clis", action="store_true")

    run_parser = subparsers.add_parser("run", help="Run a benchmark matrix")
    run_parser.add_argument("--tasks", default="all", help="all or comma-separated task IDs")
    run_parser.add_argument(
        "--profiles", default="core", help="core, all, or comma-separated profile IDs"
    )
    run_parser.add_argument("--repetitions", type=int, default=1)
    run_parser.add_argument("--timeout-seconds", type=int, default=900)
    run_parser.add_argument("--max-budget-usd", type=float)
    run_parser.add_argument("--results-dir", type=Path, default=DEFAULT_RESULTS_PATH)
    run_parser.add_argument("--keep-workspaces", action="store_true")
    run_parser.add_argument("--ordered", action="store_true", help="Do not shuffle run order")
    run_parser.add_argument("--seed", type=int, default=20260717)
    run_parser.add_argument("--dry-run", action="store_true")

    summary_parser = subparsers.add_parser("summarize", help="Summarize completed runs")
    summary_parser.add_argument("--results-dir", type=Path, default=DEFAULT_RESULTS_PATH)
    summary_parser.add_argument("--format", choices=("markdown", "csv", "json"), default="markdown")
    summary_parser.add_argument("--output", type=Path)

    args = parser.parse_args()
    if args.command == "list":
        list_suite()
        return 0
    if args.command == "validate":
        return validate_suite(args.check_clis)
    if args.command == "summarize":
        rows = summarize_results(args.results_dir)
        if args.format == "markdown":
            if args.output:
                original_stdout = sys.stdout
                with args.output.open("w", encoding="utf-8") as stream:
                    sys.stdout = stream
                    print_markdown(rows)
                sys.stdout = original_stdout
            else:
                print_markdown(rows)
        elif args.format == "csv":
            write_csv(rows, args.output)
        else:
            content = json.dumps(rows, indent=2) + "\n"
            if args.output:
                args.output.write_text(content, encoding="utf-8")
            else:
                print(content, end="")
        return 0

    profiles = select_items(args.profiles, load_profiles(), allow_core=True)
    tasks = select_items(args.tasks, load_tasks())
    jobs = [
        (task, profile, repetition)
        for repetition in range(1, args.repetitions + 1)
        for task in tasks
        for profile in profiles
    ]
    if not args.ordered:
        random.Random(args.seed).shuffle(jobs)

    args.results_dir.mkdir(parents=True, exist_ok=True)
    if args.dry_run:
        example_workspace = Path("/tmp/compass-benchmark-workspace")
        for task, profile, repetition in jobs:
            prompt = task_prompt(task, profile["mode"])
            command = build_command(profile, example_workspace, prompt, args.max_budget_usd)
            print(f"[{task['id']} | {profile['id']} | repetition {repetition}]")
            print(command_text(command))
        return 0

    for index, (task, profile, repetition) in enumerate(jobs, start=1):
        print(
            f"[{index}/{len(jobs)}] {task['id']} × {profile['id']} "
            f"(repetition {repetition})",
            flush=True,
        )
        result = run_one(
            task,
            profile,
            repetition,
            results_root=args.results_dir,
            timeout_seconds=args.timeout_seconds,
            max_budget_usd=args.max_budget_usd,
            keep_workspace=args.keep_workspaces,
        )
        print(
            f"  correct={result['correct']} time={result['agent_wall_seconds']:.2f}s "
            f"tokens={result['usage']['total_tokens']}",
            flush=True,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
