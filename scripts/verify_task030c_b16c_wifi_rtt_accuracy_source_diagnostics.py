#!/usr/bin/env python3
"""Compatibility alias for Task-030c Post-b15 Localization Completion Plan v1.2 b16-C naming.

The implemented b16-C verifier is named
`verify_task030c_b16c_location_accuracy_source_diagnostics.py` because the code records passive
CoreLocation accuracy-source diagnostics and does not claim confirmed Wi-Fi RTT. This alias preserves
the v1.2 plan's requested verifier entry point.
"""

from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
runpy.run_path(str(ROOT / "scripts" / "verify_task030c_b16c_location_accuracy_source_diagnostics.py"), run_name="__main__")
