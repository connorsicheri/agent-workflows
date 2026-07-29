import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch


BENCHMARK_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BENCHMARK_ROOT))

import run as benchmark  # noqa: E402


class CodexUsageTests(unittest.TestCase):
    def test_sums_turns_without_double_counting_cached_or_reasoning_tokens(self) -> None:
        stdout = "\n".join(
            [
                json.dumps(
                    {
                        "type": "turn.completed",
                        "usage": {
                            "input_tokens": 100,
                            "cached_input_tokens": 80,
                            "output_tokens": 20,
                            "reasoning_output_tokens": 10,
                        },
                    }
                ),
                json.dumps(
                    {
                        "type": "turn.completed",
                        "usage": {
                            "input_tokens": 50,
                            "cached_input_tokens": 0,
                            "output_tokens": 5,
                            "reasoning_output_tokens": 2,
                        },
                    }
                ),
            ]
        )
        profile = {"mode": "single", "model": "gpt-test"}

        usage = benchmark.parse_codex_usage(stdout, profile)

        self.assertEqual(usage["input_tokens"], 150)
        self.assertEqual(usage["cached_input_tokens"], 80)
        self.assertEqual(usage["output_tokens"], 25)
        self.assertEqual(usage["reasoning_output_tokens"], 12)
        self.assertEqual(usage["total_tokens"], 175)
        self.assertEqual(usage["usage_event_count"], 2)
        self.assertEqual(usage["model_usage"]["gpt-test"]["input_tokens"], 150)

    def test_compass_usage_without_model_metadata_stays_unattributed(self) -> None:
        stdout = json.dumps(
            {
                "type": "turn.completed",
                "usage": {"input_tokens": 10, "output_tokens": 2},
            }
        )
        profile = {"mode": "compass", "model": "gpt-root"}

        usage = benchmark.parse_codex_usage(stdout, profile)

        self.assertIn("unattributed", usage["model_usage"])
        self.assertNotIn("gpt-root", usage["model_usage"])


class ClaudeUsageTests(unittest.TestCase):
    def test_parses_total_and_per_model_usage(self) -> None:
        stdout = json.dumps(
            {
                "usage": {
                    "input_tokens": 10,
                    "cache_creation_input_tokens": 20,
                    "cache_read_input_tokens": 30,
                    "output_tokens": 5,
                },
                "total_cost_usd": 0.123,
                "modelUsage": {
                    "claude-test": {
                        "inputTokens": 10,
                        "cacheCreationInputTokens": 20,
                        "cacheReadInputTokens": 30,
                        "outputTokens": 5,
                        "costUSD": 0.123,
                    }
                },
            }
        )

        usage = benchmark.parse_claude_usage(stdout)

        self.assertEqual(usage["total_tokens"], 65)
        self.assertEqual(usage["cost_usd"], 0.123)
        self.assertEqual(usage["model_usage"]["claude-test"]["total_tokens"], 65)


class CommandTests(unittest.TestCase):
    def setUp(self) -> None:
        self.workspace = Path("/tmp/benchmark-workspace")

    def test_codex_single_disables_network_and_subagent_prompting(self) -> None:
        profile = {
            "provider": "codex",
            "mode": "single",
            "model": "gpt-test",
            "effort": "low",
        }
        command = benchmark.build_command(profile, self.workspace, "task", None)

        self.assertIn("sandbox_workspace_write.network_access=false", command)
        self.assertEqual(command[command.index("-a") + 1], "on-request")
        self.assertNotIn("$compass-codex:compass", command[-1])

    def test_codex_compass_activates_the_plugin_skill(self) -> None:
        profile = {
            "provider": "codex",
            "mode": "compass",
            "model": "gpt-test",
            "effort": "medium",
        }
        command = benchmark.build_command(profile, self.workspace, "task", None)

        self.assertIn("Use $compass-codex:compass", command[-1])

    def test_claude_single_and_compass_have_distinct_agent_access(self) -> None:
        single = {
            "provider": "claude",
            "mode": "single",
            "model": "sonnet",
            "effort": "medium",
        }
        compass = {
            "provider": "claude",
            "mode": "compass",
            "model": "configured-by-agent",
            "effort": "max",
        }

        single_command = benchmark.build_command(single, self.workspace, "task", None)
        compass_command = benchmark.build_command(compass, self.workspace, "task", None)

        self.assertNotIn("compass:compass-orchestrator", single_command)
        self.assertIn("compass:compass-orchestrator", compass_command)
        self.assertIn("Bash,Edit,Read,Glob,Grep,Write,Agent", compass_command)
        self.assertEqual(single_command[-2:], ["--", "task"])
        self.assertEqual(compass_command[-2:], ["--", "task"])


class ProcessTests(unittest.TestCase):
    def test_child_process_does_not_inherit_parent_codex_session(self) -> None:
        with (
            patch.dict(
                benchmark.os.environ,
                {
                    "CODEX_PERMISSION_PROFILE": "parent-profile",
                    "CODEX_THREAD_ID": "parent-thread",
                    "PATH": "/bin",
                },
                clear=True,
            ),
            patch.object(benchmark.subprocess, "Popen") as popen,
        ):
            popen.return_value.communicate.return_value = ("", "")
            popen.return_value.returncode = 0

            benchmark.run_process(["codex"], cwd=Path("/tmp"), timeout_seconds=1)

        child_environment = popen.call_args.kwargs["env"]
        self.assertNotIn("CODEX_PERMISSION_PROFILE", child_environment)
        self.assertNotIn("CODEX_THREAD_ID", child_environment)
        self.assertEqual(child_environment["PATH"], "/bin")


if __name__ == "__main__":
    unittest.main()
