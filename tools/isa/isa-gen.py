from collections import defaultdict

import yaml

parsed_meta = dict()
parsed_fields = dict()
all_instructions = defaultdict(list)
opcode_pkg_list = list()

DECODER_FILE_NAME = "swapio_decode"
PKG_FILE_NAME = "swapio_pkg"


def read_meta(isa_dict):
    cur_dict = isa_dict["meta"]

    assert cur_dict["word_bits"] == 16
    parsed_meta["word_bits"] = cur_dict["word_bits"]

    assert cur_dict["pc_bits"] == 9
    parsed_meta["pc_bits"] = cur_dict["pc_bits"]

    assert cur_dict["csr"] == 10
    parsed_meta["csr_count"] = cur_dict["csr"]

    assert cur_dict["registers"] == 8
    parsed_meta["registers"] = cur_dict["registers"]


def read_fields(isa_dict: dict):
    cur_dict = isa_dict["fields"]

    for key, val in cur_dict.items():
        name = val["name"]
        verilog_field = val["verilog_field"]

        parsed_fields[key] = verilog_field


def read_instructions(isa_dict: dict):
    cur_dict = isa_dict["instructions"]

    for item in cur_dict:
        name = item["name"]
        fmt = item["fmt"]
        func_type = int(item["func"])
        opcode_family = item["opcode_family"]

        positions = defaultdict(list)
        to_parse = []
        opcode = fmt[0:4]

        func_code = 0

        if func_type != 0:
            func_code = fmt[4:4 + func_type]

        for index, char in enumerate(fmt):
            positions[char].append(index)

        for key, val in positions.items():
            if key in ["0", "1", "-"]:
                continue

            cnt = len(val)
            assert len(val) > 0

            first_pos = val[0]
            to_parse.append((parsed_fields[key], 15 - first_pos, cnt))

            # also add the instruction opcode to the swapio_pkg.v include file

        opcode_pkg_list.append(("OPCODE_"+opcode_family, opcode))
        all_instructions[("OPCODE_"+opcode_family, func_type)].append(
            (name, to_parse, func_code)
        )


from textwrap import indent


def generate_verilog():
    instruction_cases = []

    for (op_code, func_type), family_instruction_list in all_instructions.items():
        formatted_instructions = []

        for instr_name, fields_to_parse, func_code in family_instruction_list:
            assignments = []

            for verilog_field, first_pos, cnt in fields_to_parse:
                assignments.append(
                    f"{verilog_field}_d = instr_i[{first_pos} -: {cnt}];"
                )

            instruction_body = "\n".join(assignments)

            if not instruction_body:
                instruction_body = "// No operand fields"

            if func_type != 0:
                instruction_block = (
                    f"// {instr_name.upper()}\n"
                    f"{func_type}'b{func_code}: begin\n"
                    f"{indent(instruction_body, '    ')}\n"
                    f"end"
                )
            else:
                instruction_block = (
                    f"// {instr_name.upper()}\n"
                    f"{instruction_body}"
                )

            formatted_instructions.append(instruction_block)

        family_body = "\n\n".join(formatted_instructions)

        if func_type != 0:
            family_body = (
                f"case (func{func_type})\n"
                f"{indent(family_body, '    ')}\n"
                f"    default: begin\n"
                f"        // Unsupported function\n"
                f"    end\n"
                f"endcase"
            )

        instruction_cases.append(
            f"{op_code}: begin\n"
            f"{indent(family_body, '    ')}\n"
            f"end"
        )

    opcode_body = "\n\n".join(instruction_cases)

    lines = [
        f"module swapio_decode import {PKG_FILE_NAME}::*; (",
        "    input logic [15:0] instr_i,",
        "",
        "    output logic  [2:0]  src_o,",
        "    output logic  [2:0]  dst_o,",
        "    output logic  [2:0]  pin_o,",
        "    output logic  [15:0] imm_o,",
        "    output logic  [15:0] addr_o,",
        "    output logic  [7:0]  mask_o,",
        "    output logic  [5:0]  operation_o",
        ");",
        "",
        "    logic [3:0] opcode;",
        "    assign opcode = instr_i[15:12];",
        "",
        "    logic       func1;",
        "    assign func1 = instr_i[11];",
        "",
        "    logic [1:0] func2;",
        "    assign func2 = instr_i[11:10];",
        "",
        "    logic [2:0] func3;",
        "    assign func3 = instr_i[11:9];",
        "",
        "    logic [3:0] func4;",
        "    assign func4 = instr_i[11:8];",
        "",
        "    logic [2:0]  src_d;",
        "    logic [2:0]  dst_d;",
        "    logic [2:0]  pin_d;",
        "    logic [15:0] imm_d;",
        "    logic [15:0] addr_d;",
        "    logic [7:0]  mask_d;",
        "    logic        clr_d;",
        "    logic        wait_d;",
        "    logic        block_d;",
        "",
        "    // Combinational instruction decoder",
        "    always_comb begin",
        "        src_d   = 3'd0;",
        "        dst_d   = 3'd0;",
        "        pin_d   = 3'd0;",
        "        imm_d   = 16'd0;",
        "        addr_d  = 16'd0;",
        "        mask_d  = 8'd0;",
        "        clr_d   = 1'b0;",
        "        wait_d  = 1'b0;",
        "        block_d = 1'b0;",
        "",
        "        case (opcode)",
    ]

    lines.append(indent(opcode_body, " " * 12))
    lines.extend([
        "",
        "            default: begin",
        "                // Unsupported opcode",
        "            end",
        "        endcase",
        "    end",
        "",
        "endmodule",
    ])

    verilog = "\n".join(lines) + "\n"

    with open(f"../../src/{DECODER_FILE_NAME}.sv", "w") as f:
        f.write(verilog)

def generate_include_pkg():
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

    added_already = set()
    for (opcode_family, opcode) in opcode_pkg_list: 
        if opcode_family in added_already:
            continue
        added_already.add(opcode_family)
        lines.append(f" parameter {opcode_family} = 4'b{opcode};")

    lines.append("")

    lines.append("endpackage")

    verilog = "\n".join(lines) + "\n"

    with open(f"../../src/include/{PKG_FILE_NAME}.sv", "w") as f:
        f.write(verilog)


def generate(isa_dict):
    read_meta(isa_dict)
    read_fields(isa_dict)

    read_instructions(isa_dict)
    generate_verilog()

    generate_include_pkg()


if __name__ == "__main__":
    file_path = "../../isa/isa.yaml"

    with open(file_path, "r", encoding="utf-8") as file:
        isa_dict = yaml.safe_load(file)

    generate(isa_dict)
