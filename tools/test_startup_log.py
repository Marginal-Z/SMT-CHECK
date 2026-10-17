import subprocess
import sys
import tempfile
from pathlib import Path
import unittest

from check_startup_log import validate

CLAMP = "[ERROR:flutter/lib/ui/window/platform_configuration.cc(475)] Reported frame time is older than the last one; clamping. 100 < 120 ~= 20"


class StartupLogTest(unittest.TestCase):
    def test_corrected_startup_timestamp_is_recorded(self):
        self.assertEqual(validate(CLAMP, allow_startup_frame_clamp=True), ([], 1))

    def test_same_message_in_steady_state_is_a_failure(self):
        self.assertEqual(validate(CLAMP), ([CLAMP], 0))

    def test_real_errors_are_not_hidden_beside_a_clamp(self):
        for error in ["[ERROR:flutter/runtime/dart_vm_initializer.cc(41)] Unhandled Exception: crash",
                      "[ERROR:flutter/shell/common/engine.cc(22)] Failed to start engine",
                      "[FATAL:flutter/runtime.cc(22)] failure", "EXCEPTION CAUGHT BY RENDERING LIBRARY"]:
            self.assertEqual(validate(CLAMP + "\n" + error, allow_startup_frame_clamp=True), ([error], 1))

    def test_other_messages_from_same_engine_file_still_fail(self):
        message = "[ERROR:flutter/lib/ui/window/platform_configuration.cc(475)] Frame number is out of order"
        self.assertEqual(validate(message, allow_startup_frame_clamp=True), ([message], 0))

    def test_inexact_or_invalid_clamp_messages_fail_closed(self):
        for message in [CLAMP + " Unhandled Exception", CLAMP.replace("~= 20", "~= 21"),
                        CLAMP.replace("100 < 120", "120 < 100"), CLAMP.replace("platform_configuration.cc", "application.cc")]:
            self.assertEqual(validate(message, allow_startup_frame_clamp=True), ([message], 0))

    def test_cli_exit_status_preserves_both_startup_and_steady_checks(self):
        with tempfile.TemporaryDirectory(prefix="smt-startup-log-") as directory:
            log = Path(directory) / "startup.log"
            command = [sys.executable, str(Path(__file__).with_name("check_startup_log.py")), str(log)]
            for text, flags, expected in [(CLAMP, [], 1), (CLAMP, ["--allow-startup-frame-clamp"], 0),
                                           (CLAMP + "\nUnhandled Exception: app error", ["--allow-startup-frame-clamp"], 1)]:
                log.write_text(text, encoding="utf-8")
                result = subprocess.run(command + flags, capture_output=True, check=False)
                self.assertEqual(result.returncode, expected, result.stderr)


if __name__ == "__main__":
    unittest.main()
