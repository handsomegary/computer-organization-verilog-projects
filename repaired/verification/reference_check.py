"""Independent MIPS ISA oracle and reproducible A/B/C simulation checks.

Run with Python 3 and Icarus Verilog. No external Python packages are required.
Each directed case and seeded random case compares all 32 architectural
registers and all 1,024 data words, including untouched words. Level B receives
four NOPs after every source instruction, with branch/jump labels relocated.
Level C receives the original dependency-rich stream, without inserted NOPs.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import random
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MASK = 0xFFFFFFFF
FUNCTIONS = {"add": 0x20, "sub": 0x22, "and": 0x24, "or": 0x25, "slt": 0x2A}
OPCODES = {"addi": 8, "lw": 35, "sw": 43, "beq": 4, "j": 2}


def signed(value: int) -> int:
    return value - 0x100000000 if value & 0x80000000 else value


def assemble(source: list[tuple], padding: int = 0) -> tuple[list[int], int]:
    """Resolve symbolic labels after scheduling, then encode standard MIPS."""
    labels, instructions = {}, []
    for instruction in source + [("addi", 29, 0, 0x5A5A), ("label", "__halt"), ("j", "__halt")]:
        if instruction[0] == "label":
            if instruction[1] in labels:
                raise ValueError("Duplicate label: " + instruction[1])
            labels[instruction[1]] = len(instructions)
        else:
            instructions.append(instruction)
            instructions.extend([("nop",)] * padding)
    words = []
    for pc, instruction in enumerate(instructions):
        op, *args = instruction
        if op == "nop":
            word = 0
        elif op in FUNCTIONS:
            rd, rs, rt = args
            word = (rs << 21) | (rt << 16) | (rd << 11) | FUNCTIONS[op]
        elif op in ("addi", "lw", "sw"):
            rt, rs, immediate = args
            word = (OPCODES[op] << 26) | (rs << 21) | (rt << 16) | (immediate & 0xFFFF)
        elif op == "beq":
            rs, rt, label = args
            displacement = labels[label] - (pc + 1)
            if not -32768 <= displacement <= 32767:
                raise ValueError("Branch offset is outside 16-bit range")
            word = (4 << 26) | (rs << 21) | (rt << 16) | (displacement & 0xFFFF)
        elif op == "j":
            word = (2 << 26) | labels[args[0]]
        else:
            raise ValueError(f"Unknown source opcode: {op}")
        words.append(word)
    if len(words) > 1024:
        raise ValueError("Program exceeds instruction memory")
    return words, labels["__halt"] * 4


def interpret(words: list[int], registers: list[int], memory: list[int], finish_pc: int) -> tuple[list[int], list[int], int]:
    """Execute encoded instructions; intentionally independent of RTL decoding."""
    registers, memory = registers.copy(), memory.copy()
    registers[0] = 0
    pc, steps = 0, 0
    while pc != finish_pc:
        if steps >= 10000:
            raise ValueError("Oracle program does not terminate")
        if pc % 4 or not 0 <= pc // 4 < len(words):
            raise ValueError(f"Oracle invalid instruction PC: {pc:#x}")
        instruction = words[pc // 4]
        opcode, rs, rt, rd = instruction >> 26, (instruction >> 21) & 31, (instruction >> 16) & 31, (instruction >> 11) & 31
        immediate = instruction & 0xFFFF
        if immediate & 0x8000:
            immediate -= 65536
        left, right = registers[rs], registers[rt]
        next_pc = (pc + 4) & MASK
        destination, value = 0, 0
        if instruction == 0:
            pass
        elif opcode == 0:
            function = instruction & 63
            if function == 0x20:
                value = left + right
            elif function == 0x22:
                value = left - right
            elif function == 0x24:
                value = left & right
            elif function == 0x25:
                value = left | right
            elif function == 0x2A:
                value = int(signed(left) < signed(right))
            else:
                raise ValueError(f"Unsupported oracle function: {function:#x}")
            destination = rd
        elif opcode == 8:
            destination, value = rt, left + immediate
        elif opcode in (35, 43):
            address = (left + immediate) & MASK
            if address % 4 or not 0 <= address // 4 < len(memory):
                raise ValueError(f"Oracle invalid data address: {address:#x}")
            if opcode == 35:
                destination, value = rt, memory[address // 4]
            else:
                memory[address // 4] = right
        elif opcode == 4:
            if left == right:
                next_pc = (next_pc + (immediate << 2)) & MASK
        elif opcode == 2:
            next_pc = (next_pc & 0xF0000000) | ((instruction & 0x03FFFFFF) << 2)
        else:
            raise ValueError(f"Unsupported oracle opcode: {opcode:#x}")
        if destination:
            registers[destination] = value & MASK
        registers[0] = 0
        pc, steps = next_pc, steps + 1
    return registers, memory, steps


def case(name, program, initial_regs=None, initial_data=None, stalls=None, tags=None):
    registers = [0] * 32
    # Distinct deterministic sentinels expose stale/unintended memory writes.
    memory = [((index * 0x9E3779B9) ^ 0xA5C35A3C) & MASK for index in range(1024)]
    for index, value in (initial_regs or {}).items():
        registers[index] = value & MASK
    for index, value in (initial_data or {}).items():
        memory[index] = value & MASK
    return {"name": name, "program": program, "registers": registers, "memory": memory,
            "stalls": stalls, "tags": tags or []}


def directed_cases():
    return [
        case("isa_and_signed_boundaries", [
            ("addi", 1, 0, -7), ("addi", 2, 0, 5), ("add", 3, 1, 2), ("sub", 4, 2, 1),
            ("and", 5, 1, 2), ("or", 6, 1, 2), ("slt", 7, 1, 2), ("slt", 8, 2, 1),
            ("sw", 4, 0, 12), ("lw", 9, 0, 12), ("addi", 10, 0, 16),
            ("sw", 9, 10, -4), ("lw", 11, 10, -4), ("addi", 12, 0, -32768),
            ("addi", 13, 12, 32767), ("slt", 14, 20, 21), ("slt", 15, 21, 20),
            ("add", 16, 21, 21), ("sub", 17, 20, 21),
            ("addi", 0, 0, 99), ("add", 0, 1, 2), ("lw", 0, 0, 4),
            ("add", 18, 0, 0), ("sw", 0, 0, 28),
        ], {20: 0x80000000, 21: 0x7FFFFFFF}, tags=["all_data_ISA", "signed_slt", "negative_immediate", "zero", "byte_addressing"]),
        case("forward_backward_branches_and_jump", [
            ("addi", 1, 0, 4), ("addi", 2, 0, 0), ("label", "loop"),
            ("addi", 2, 2, 3), ("addi", 1, 1, -1), ("beq", 1, 0, "done"),
            ("beq", 0, 0, "loop"), ("sw", 20, 0, 100),
            ("label", "done"), ("beq", 2, 0, "wrong"), ("addi", 3, 0, 7),
            ("addi", 4, 0, 7), ("beq", 3, 4, "equal"), ("sw", 20, 0, 104),
            ("addi", 5, 0, -1), ("label", "equal"), ("j", "far_target"),
            ("sw", 20, 0, 108), ("addi", 6, 0, -1),
            *[("addi", 7, 0, -1)] * 25,
            ("label", "wrong"), ("sw", 20, 0, 112),
            ("label", "far_target"), ("addi", 8, 0, 42),
        ], {20: 0xDEADBEEF}, tags=["taken_branch", "untaken_branch", "backward_branch", "jump", "flush", "branch_dual_forward"]),
        case("slide8_exact_hazard_program", [
            ("sub", 2, 1, 3), ("and", 12, 2, 5), ("or", 13, 6, 2),
            ("add", 14, 2, 2), ("sw", 15, 2, 100),
        ], {1: 31, 2: 0x100, 3: 7, 5: 21, 6: 0x40, 15: 0x1234ABCD},
             stalls=(0, 0), tags=["exact_slide8", "RAW_rs", "RAW_rt", "RAW_both", "store_base"]),
        case("load_use_rs", [("lw", 1, 0, 0), ("sub", 2, 1, 3)], {3: 9}, {0: 42},
             stalls=(1, 1), tags=["load_use_rs"]),
        case("load_use_rt", [("lw", 1, 0, 0), ("sub", 2, 3, 1)], {3: 9}, {0: 42},
             stalls=(1, 1), tags=["load_use_rt"]),
        case("load_use_both", [("lw", 1, 0, 0), ("add", 2, 1, 1)], initial_data={0: 42},
             stalls=(1, 1), tags=["load_use_both"]),
        case("load_to_store_data", [("lw", 1, 0, 0), ("sw", 1, 0, 12)], initial_data={0: 0x89ABCDEF},
             stalls=(1, 1), tags=["load_store_data"]),
        case("load_to_store_base", [("lw", 1, 0, 0), ("sw", 2, 1, -4)], {2: 0x12345678}, {0: 128},
             stalls=(1, 1), tags=["load_store_base", "negative_store_offset"]),
        case("load_to_branch", [
            ("lw", 1, 0, 0), ("beq", 1, 2, "taken"), ("sw", 3, 0, 16),
            ("addi", 4, 0, -1), ("label", "taken"), ("addi", 5, 0, 12),
        ], {2: 42, 3: 99}, {0: 42}, stalls=(1, 1), tags=["load_branch", "flush"]),
        case("newest_producer_priority", [
            ("addi", 1, 0, 3), ("addi", 1, 0, 4), ("add", 2, 1, 1),
            ("addi", 3, 0, 8), ("lw", 3, 0, 0), ("or", 4, 3, 3),
            ("addi", 5, 0, 1), ("add", 5, 5, 5), ("add", 5, 5, 5), ("sw", 5, 0, 12),
        ], initial_data={0: 0x89ABCDEF}, stalls=(1, 1), tags=["EX_MEM_priority", "MEM_WB", "load_priority", "store_data_forward"]),
        case("no_false_stalls_or_zero_forwarding", [
            ("lw", 1, 0, 0), ("addi", 1, 0, 7), ("add", 2, 1, 1),
            ("lw", 3, 0, 4), ("lw", 3, 0, 8), ("nop",),
            ("lw", 0, 0, 0), ("add", 4, 0, 0),
        ], initial_data={0: 19, 1: 23, 2: 29}, stalls=(0, 0), tags=["decoded_sources", "zero_hazard_exclusion"]),
        case("writeback_decode_and_dual_forward", [
            ("addi", 1, 0, 41), ("nop",), ("nop",), ("add", 2, 1, 1),
            ("addi", 3, 0, 9), ("addi", 4, 0, 5), ("sub", 5, 3, 4),
            ("addi", 6, 0, 128), ("addi", 7, 0, 77), ("sw", 7, 6, 0),
            ("lw", 8, 6, 0), ("nop",), ("sw", 8, 6, 4),
        ], tags=["WB_ID_visibility", "dual_forward", "store_both_operands"]),
    ]


def randomized_case(seed: int):
    rng = random.Random(seed)
    registers = {index: rng.getrandbits(32) for index in range(1, 29)}
    registers.update({30: 128, 31: 512})
    program = []
    last_destination = 1
    count = 100
    for index in range(count):
        program.append(("label", f"i{index}"))
        source = last_destination if rng.random() < 0.72 else rng.randrange(0, 26)
        other = source if rng.random() < 0.3 else rng.randrange(0, 26)
        destination = rng.randrange(0, 26)
        kind = rng.randrange(12)
        if kind < 5:
            program.append((list(FUNCTIONS)[kind], destination, source, other))
        elif kind < 7:
            program.append(("addi", destination, source, rng.choice([-32768, -128, -7, -1, 0, 1, 9, 32767])))
        elif kind < 9:
            base = rng.choice([0, 30, 31])
            displacement = 4 * rng.randrange(0, 16) if base == 0 else 4 * rng.randrange(-8, 9)
            program.append(("lw", destination, base, displacement))
        elif kind == 9:
            base = rng.choice([0, 30, 31])
            displacement = 4 * rng.randrange(0, 16) if base == 0 else 4 * rng.randrange(-8, 9)
            program.append(("sw", source, base, displacement))
        elif kind == 10:
            target = min(count, index + rng.randrange(1, 5))
            program.append(("beq", source, other, f"i{target}"))
        else:
            target = min(count, index + rng.randrange(1, 5))
            program.append(("j", f"i{target}"))
        if kind < 9 and destination:
            last_destination = destination
    program.append(("label", f"i{count}"))
    memory = {index: rng.getrandbits(32) for index in range(160)}
    return case(f"random_{seed:04d}", program, registers, memory, tags=["seeded_random", "dependencies", "mixed_control"])


def run_command(arguments, timeout=30):
    # File handles avoid Windows Icarus driver pipe inheritance hangs.
    with tempfile.TemporaryFile() as stdout, tempfile.TemporaryFile() as stderr:
        process = subprocess.Popen([str(arg) for arg in arguments], cwd=ROOT, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr)
        timed_out = False
        try:
            returncode = process.wait(timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            process.kill()
            process.wait()
            returncode = None
        stdout.seek(0)
        stderr.seek(0)
        return {"command": [str(arg) for arg in arguments], "returncode": returncode, "timeout": timed_out,
                "stdout": stdout.read().decode("utf-8", errors="replace"), "stderr": stderr.read().decode("utf-8", errors="replace")}


def write_hex(path: Path, values: list[int]):
    path.write_text("".join(f"{value & MASK:08x}\n" for value in values), encoding="ascii")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--iverilog", default="iverilog")
    parser.add_argument("--vvp", default="vvp")
    parser.add_argument("--iverilog-base", type=Path, help="lib/ivl directory for a portable Icarus distribution")
    parser.add_argument("--output-dir", type=Path, default=ROOT / ".reference-build")
    parser.add_argument("--mode", action="append", choices=["single", "pipeline", "hazard"], help="Repeat to select modes; default all three")
    parser.add_argument("--case", action="append", help="Repeat to select exact case names")
    parser.add_argument("--random-cases", type=int, default=20)
    parser.add_argument("--vcd", action="store_true", help="Write a waveform for every selected simulation")
    parser.add_argument("--skip-default-rom", action="store_true", help="Skip the additional three-mode built-in ROM/reset smoke test")
    args = parser.parse_args()
    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)
    compiler = Path(shutil.which(args.iverilog) or args.iverilog).resolve()
    simulator = Path(shutil.which(args.vvp) or args.vvp).resolve()
    os.environ["PATH"] = str(compiler.parent) + os.pathsep + os.environ.get("PATH", "")
    cases = directed_cases() + [randomized_case(seed) for seed in range(args.random_cases)]
    if args.case:
        missing = set(args.case) - {item["name"] for item in cases}
        if missing:
            parser.error("Unknown cases: " + ", ".join(sorted(missing)))
        cases = [item for item in cases if item["name"] in args.case]
    results = {"checker": "independent_encoded_MIPS_oracle", "random_seeds": list(range(args.random_cases)), "compilation": {}, "cases": []}
    for mode in args.mode or ["single", "pipeline", "hazard"]:
        executable = output / f"reference_{mode}.vvp"
        command = [compiler]
        if args.iverilog_base:
            command += ["-B", args.iverilog_base.resolve()]
        command += ["-g2012", "-Wall", "-s", "reference_tb", "-o", executable]
        if mode == "single":
            command += ["-DREFERENCE_SINGLE"]
            rtl = ROOT / "reference/rtl/mips_single_cycle.v"
        else:
            if mode == "pipeline":
                command += ["-DREFERENCE_NO_HAZARDS"]
            rtl = ROOT / "reference/rtl/mips_pipeline.v"
        command += [ROOT / "verification/reference_tb.v", rtl]
        compilation = run_command(command)
        results["compilation"][mode] = compilation
        if compilation["returncode"] != 0:
            print(f"FAIL {mode}: compilation")
            continue
        for item in cases:
            case_dir = output / mode / item["name"]
            case_dir.mkdir(parents=True, exist_ok=True)
            words, finish_pc = assemble(item["program"], padding=4 if mode == "pipeline" else 0)
            expected_regs, expected_data, oracle_steps = interpret(words, item["registers"], item["memory"], finish_pc)
            files = {name: case_dir / f"{name.lower()}.hex" for name in ["PROGRAM", "REGS", "DATA", "EXPECTED_REGS", "EXPECTED_DATA"]}
            for name, values in zip(files, [words + [0] * (1024 - len(words)), item["registers"], item["memory"], expected_regs, expected_data]):
                write_hex(files[name], values)
            min_stalls, max_stalls = item["stalls"] or (0, 2147483647)
            if mode != "hazard":
                min_stalls, max_stalls = 0, 0
            cycles = max(80, len(words) * 4 + 40)
            command = [simulator, executable] + [f"+{name}={path.as_posix()}" for name, path in files.items()]
            command += [f"+CYCLES={cycles}", f"+FINISH_PC={finish_pc}", f"+MIN_STALLS={min_stalls}", f"+MAX_STALLS={max_stalls}"]
            if args.vcd:
                command += [f"+VCD={(case_dir / 'wave.vcd').as_posix()}"]
            simulation = run_command(command)
            passed = simulation["returncode"] == 0 and "REFERENCE PASS" in simulation["stdout"] and "FAIL" not in simulation["stdout"]
            stall_match = re.search(r"REFERENCE PASS cycles=\d+ stalls=(\d+)", simulation["stdout"])
            result = {"mode": mode, "case": item["name"], "passed": passed, "tags": item["tags"],
                      "oracle_steps": oracle_steps, "cycles": cycles, "program_words": len(words),
                      "program_sha256": hashlib.sha256(files["PROGRAM"].read_bytes()).hexdigest(),
                      "stall_count": int(stall_match.group(1)) if stall_match else None,
                      "expected_stall_range": [min_stalls, max_stalls], "simulation": simulation}
            results["cases"].append(result)
            print(f"{'PASS' if passed else 'FAIL'} {mode:8} {item['name']}")
    if not args.skip_default_rom:
        executable = output / "reference_default_rom.vvp"
        command = [compiler]
        if args.iverilog_base:
            command += ["-B", args.iverilog_base.resolve()]
        command += ["-g2012", "-Wall", "-s", "reference_demo_tb", "-o", executable,
                    ROOT / "verification/reference_demo_tb.v", ROOT / "reference/rtl/mips_single_cycle.v", ROOT / "reference/rtl/mips_pipeline.v"]
        compilation = run_command(command)
        results["compilation"]["default_rom"] = compilation
        if compilation["returncode"] == 0:
            simulation = run_command([simulator, executable])
            passed = simulation["returncode"] == 0 and "REFERENCE DEFAULT ROM PASS" in simulation["stdout"]
            results["cases"].append({"mode": "all_three", "case": "default_rom_and_reset", "passed": passed,
                                      "tags": ["built_in_ROM", "all_data_ISA", "branch_jump", "reset", "memory_preservation"], "simulation": simulation})
            print(f"{'PASS' if passed else 'FAIL'} all_three default_rom_and_reset")
        else:
            print("FAIL all_three: default ROM compilation")
    results["summary"] = {"passed": sum(item["passed"] for item in results["cases"]), "total": len(results["cases"]),
                          "compilation_failures": sum(item["returncode"] != 0 for item in results["compilation"].values())}
    (output / "results.json").write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(results["summary"]))
    return int(results["summary"]["passed"] != results["summary"]["total"] or results["summary"]["compilation_failures"] != 0)


if __name__ == "__main__":
    raise SystemExit(main())
