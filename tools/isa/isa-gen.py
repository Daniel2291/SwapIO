from collections import defaultdict
from pathlib import Path
from textwrap import indent

import yaml

DECODER_FILE_NAME = "swapio_decode"
PKG_FILE_NAME = "swapio_pkg"

ROOT = Path(__file__).resolve().parent
# When the generator lives in tools/isa/, these paths point at the project folders.
PROJECT_ROOT = ROOT.parent.parent if ROOT.parent.name == "tools" else ROOT
ISA_PATH = PROJECT_ROOT / "isa" / "isa.yaml"
SRC_PATH = PROJECT_ROOT / "src"


def function_enum_name(family: str, name: str) -> str:
    family = family.upper()
    name = name.upper()
    return name if name.startswith(f"{family}_") else f"{family}_{name}"


def read_meta(isa_dict: dict) -> dict:
    meta = isa_dict["meta"]
    for key, expected in (("word_bits", 16), ("pc_bits", 9), ("csr", 10), ("registers", 8)):
        if meta[key] != expected:
            raise ValueError(f"meta.{key} must be {expected}, got {meta[key]}")
    return meta


def read_fields(isa_dict: dict) -> dict:
    return {symbol: field["verilog_field"] for symbol, field in isa_dict["fields"].items()}


def parse_instructions(isa_dict: dict, parsed_fields: dict):
    families = defaultdict(list)
    opcodes = {}
    seen_names = set()
    seen_func_codes = set()
    seen_fmt = []

    for item in isa_dict["instructions"]:
        name = item["name"]
        fmt = item["fmt"]
        family = item["opcode_family"].upper()
        func_width = int(item["func"])
        if name in seen_names:
            raise ValueError(f"Duplicate instruction: {name}")
        seen_names.add(name)
        if len(fmt) != 16:
            raise ValueError(f"{name}: format must be 16 bits, got {len(fmt)}")
        if not 0 <= func_width <= 4:
            raise ValueError(f"{name}: invalid function width {func_width}")
        opcode = fmt[:4]
        code = fmt[4:4 + func_width]
        if any(bit not in "01" for bit in opcode + code):
            raise ValueError(f"{name}: opcode/function must contain literal binary digits")
        if family in opcodes and opcodes[family] != opcode:
            raise ValueError(f"{family}: multiple primary opcodes")
        opcodes[family] = opcode
        if (family, code) in seen_func_codes:
            raise ValueError(f"{family}: duplicate function code {code!r}")
        seen_func_codes.add((family, code))
        for prev_name, prev_fmt in seen_fmt:
            if all(a == b or a not in "01" or b not in "01" for a, b in zip(fmt, prev_fmt)):
                raise ValueError(f"Overlapping encodings: {prev_name} and {name}")
        seen_fmt.append((name, fmt))

        positions = defaultdict(list)
        for i, char in enumerate(fmt):
            if char not in "01-":
                if char not in parsed_fields:
                    raise ValueError(f"{name}: unknown field {char!r}")
                positions[char].append(i)

        operands = []
        for symbol, indices in positions.items():
            if indices != list(range(indices[0], indices[0] + len(indices))):
                raise ValueError(f"{name}: field {symbol} is non-contiguous")
            operands.append((parsed_fields[symbol], 15 - indices[0], len(indices)))

        families[family].append({
            "name": name,
            "fmt": fmt,
            "opcode": opcode,
            "func_width": func_width,
            "func_code": code,
            "operands": operands,
        })

    opcode_seen = {}
    for family, opcode in opcodes.items():
        if opcode in opcode_seen:
            raise ValueError(f"Opcode {opcode} shared by {opcode_seen[opcode]} and {family}")
        opcode_seen[opcode] = family
        widths = {item["func_width"] for item in families[family]}
        if len(widths) != 1:
            raise ValueError(f"{family}: inconsistent function widths")
        if next(iter(widths)) == 0 and len(families[family]) != 1:
            raise ValueError(f"{family}: function-free family has multiple instructions")
    return families, opcodes


def generate_function_enums(families: dict) -> list[str]:
    lines = []
    for family, instructions in families.items():
        width = instructions[0]["func_width"]
        if width == 0:
            continue
        logic_width = "logic" if width == 1 else f"logic [{width - 1}:0]"
        lines.append(f"    typedef enum {logic_width} {{")
        entries = [
            f"        {function_enum_name(family, instr['name'])} = {width}'b{instr['func_code']}"
            for instr in instructions
        ]
        lines.append(",\n".join(entries))
        lines.append(f"    }} {family.lower()}_func_t;")
        lines.append("")
    return lines

def generate_csr_field_params(isa_dict: dict) -> list[str]:
    lines = ["    // CSR field positions and widths"]

    for csr in isa_dict["csr"]:
        csr_name = csr["name"].upper()

        for field_name, field in csr.get("fields", {}).items():
            prefix = f"{csr_name}_{field_name.upper()}"

            lines.append(
                f"    localparam int unsigned {prefix}_LSB = {field['lsb']};"
            )
            lines.append(
                f"    localparam int unsigned {prefix}_WIDTH = {field['width']};"
            )

        lines.append("")

    return lines

def generate_pkg(isa_dict: dict, families: dict, opcodes: dict) -> str:
    lines = [f"package {PKG_FILE_NAME};", "", "    // Primary opcode families"]

    lines = [
        f"package {PKG_FILE_NAME};",
        "",
        r" ////////////////////////////////////////////////",
        r" //    ___         ____          _             //",
        r" //   / _ \ _ __  / ___|___   __| | ___  ___   //",
        r" //  | | | | '_ \| |   / _ \ / _` |/ _ \/ __|  //",
        r" //  | |_| | |_) | |__| (_) | (_| |  __/\__ \  //",
        r" //   \___/| .__/ \____\___/ \__,_|\___||___/  //",
        r" //        |_|                                 //",
        r" ////////////////////////////////////////////////",
        ""
    ]

    for family, code in opcodes.items():
        lines.append(f"    localparam logic [3:0] OPCODE_{family} = 4'b{code};")
    lines.extend(["", "    // Function codes"])
    lines.extend(generate_function_enums(families))

    lines.append("    //NOTE: we might not use this depending on how we implement execute")
    lines.append("    // Unique instruction IDs (independent of raw opcode/function)")

    entries = []
    instruction_number = 0
    for instructions in families.values():
        for instr in instructions:
            entries.append(f"        INSTR_{instr['name'].upper()} = 6'd{instruction_number}")
            instruction_number += 1
    if instruction_number > 64:
        raise ValueError("More than 64 instructions: increase operation ID width")

    lines.append("    typedef enum logic [5:0] {")
    lines.append(",\n".join(entries))
    lines.append("    } operation_t;")

    lines.extend([
        "",
        r"/////////////////////////////////////////////////////////",
        r"//    ____ ____    ____            _     _             //",
        r"//   / ___/ ___|  |  _ \ ___  __ _(_)___| |_ ___ _ __  //",
        r"//  | |   \___ \  | |_) / _ \/ _` | / __| __/ _ \ '__| //",
        r"//  | |___ ___) | |  _ <  __/ (_| | \__ \ ||  __/ |    //",
        r"//   \____|____/  |_| \_\___|\__, |_|___/\__\___|_|    //",
        r"//                           |___/                     //",
        r"/////////////////////////////////////////////////////////",
        ""
    ])

    lines.extend(["", "    // CSR addresses"])
    csr_entries = [
        f"        CSR_{csr['name']} = 5'h{csr['addr']:02X}"
        for csr in isa_dict["csr"]
    ]
    lines.append("    typedef enum logic [4:0] {")
    lines.append(",\n".join(csr_entries))
    lines.append("    } csr_addr_t;")

    lines.append("")
    lines.extend(generate_csr_field_params(isa_dict))

    lines.extend(["", "endpackage", ""])
    return "\n".join(lines)

def generate_decoder(families: dict) -> str:
    decoder_outputs = {
        "src": 3,
        "dst": 3,
        "pin": 3,
        "imm": 16,
        "addr": 16,
        "mask": 8,
        "clr": 1,
        "wait": 1,
        "block": 1,
        "operation": 6,
        "valid": 1,
    }

    case_blocks = []

    for family, instructions in families.items():
        func_width = instructions[0]["func_width"]
        branches = []

        for instr in instructions:
            stmts = [
                "valid_o = 1'b1;",
                f"operation_o = INSTR_{instr['name'].upper()};",
            ]

            for field, msb, width in instr["operands"]:
                output_width = decoder_outputs[field]
                remaining = output_width - width

                if remaining < 0:
                    raise ValueError(
                        f"Operand {field} is {width} bits, "
                        f"but {field}_o is only {output_width} bits"
                    )

                value = f"instr_i[{msb} -: {width}]"

                if remaining > 0:
                    value = f"{{{remaining}'b0, {value}}}"

                stmts.append(f"{field}_o = {value};")

            body = "\n".join(stmts)

            if func_width:
                label = function_enum_name(family, instr["name"])
                branches.append(
                    f"{label}: begin\n{indent(body, '    ')}\nend"
                )
            else:
                branches.append(body)

        family_body = "\n\n".join(branches)

        if func_width:
            family_body = (
                f"case (func{func_width})\n"
                f"{indent(family_body, '    ')}\n"
                "    default: ;\n"
                "endcase"
            )

        case_blocks.append(
            f"OPCODE_{family}: begin\n"
            f"{indent(family_body, '    ')}\n"
            "end"
        )

    lines = [
        f"module {DECODER_FILE_NAME} import {PKG_FILE_NAME}::*; (",
        "    input logic [15:0] instr_i,",
    ]

    # Generate output ports from their declared widths.
    output_items = list(decoder_outputs.items())

    for index, (name, width) in enumerate(output_items):
        bits = f"[{width - 1}:0] " if width > 1 else ""
        comma = "," if index < len(output_items) - 1 else ""

        lines.append(
            f"    output logic {bits}{name}_o{comma}"
        )

    lines.extend([
        ");",
        "",
        "    logic [3:0] opcode;",
        "    assign opcode = instr_i[15:12];",
        "",
    ])

    for width in (1, 2, 3, 4):
        width_text = "" if width == 1 else f"[{width - 1}:0] "
        end_bit = 12 - width
        slc = "[11]" if width == 1 else f"[11:{end_bit}]"

        lines.extend([
            f"    logic {width_text}func{width};",
            f"    assign func{width} = instr_i{slc};",
            "",
        ])

    lines.extend([
        "    always_comb begin",
    ])

    # Generate default assignments for every output.
    for name in decoder_outputs:
        if name == "operation":
            lines.append(
                "        operation_o = '0; // Only meaningful when valid_o is high"
            )
        else:
            lines.append(f"        {name}_o = '0;")

    lines.extend([
        "",
        "        case (opcode)",
        indent("\n\n".join(case_blocks), " " * 12),
        "            default: ;",
        "        endcase",
        "    end",
        "endmodule",
        "",
    ])

    return "\n".join(lines)

def generate(isa_dict: dict) -> None:
    read_meta(isa_dict)
    parsed_fields = read_fields(isa_dict)
    families, opcodes = parse_instructions(isa_dict, parsed_fields)
    (SRC_PATH / "include").mkdir(parents=True, exist_ok=True)
    (SRC_PATH / "include" / f"{PKG_FILE_NAME}.sv").write_text(
        generate_pkg(isa_dict, families, opcodes), encoding="utf-8"
    )
    (SRC_PATH / f"{DECODER_FILE_NAME}.sv").write_text(
        generate_decoder(families), encoding="utf-8"
    )
    print(f"Generated {SRC_PATH / 'include' / (PKG_FILE_NAME + '.sv')}")
    print(f"Generated {SRC_PATH / (DECODER_FILE_NAME + '.sv')}")


if __name__ == "__main__":
    with ISA_PATH.open("r", encoding="utf-8") as file:
        isa_dict = yaml.safe_load(file)
    generate(isa_dict)
