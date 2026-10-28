from collections import defaultdict

import yaml


def read_meta(isa_dict):
    cur_dict = isa_dict["meta"]
    parsed_meta = {}

    assert cur_dict["word_bits"] == 16
    parsed_meta["word_bits"] = cur_dict["word_bits"]

    assert cur_dict["pc_bits"] == 9
    parsed_meta["pc_bits"] = cur_dict["pc_bits"]

    assert cur_dict["csr"] == 10
    parsed_meta["csr_count"] = cur_dict["csr"]

    assert cur_dict["registers"] == 8
    parsed_meta["registers"] = cur_dict["registers"]

    return parsed_meta


def read_fields(isa_dict: dict):
    cur_dict = isa_dict["fields"]
    parsed_fields = {}

    for key, val in cur_dict.items():
        name = val["name"]
        verilog_field = val["verilog_field"]

        parsed_fields[key] = verilog_field

    return parsed_fields


def read_instructions(isa_dict: dict, parsed_fields: dict):
    cur_dict = isa_dict["instructions"]
    all_instructions = defaultdict(list)

    for item in cur_dict:
        name = item["name"]
        fmt = item["fmt"]
        func_type = int(item["func"])

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

        all_instructions[(opcode, func_type)].append(
            (name, to_parse, func_code)
        )

    return all_instructions


from textwrap import indent, dedent

def generate_verilog(all_instructions: dict):
    instruction_cases = []

    for (op_code, func_type), family_instruction_list in all_instructions.items():
        formatted_instructions = []

        for instr_name, fields_to_parse, func_code in family_instruction_list:
            assignments = []

            for verilog_field, first_pos, cnt in fields_to_parse:
                assignments.append(
                    f"{verilog_field} <= instr_i[{first_pos} -: {cnt}];"
                )

            instruction_body = "\n".join(assignments)

            if func_type != 0:
                formatted_instructions.append(
                    f"{func_type}'b{func_code}: begin\n"
                    f"{indent(instruction_body, '    ')}\n"
                    f"end"
                )
            else:
                formatted_instructions.append(instruction_body)

        family_body = "\n".join(formatted_instructions)

        if func_type != 0:
            family_body = (
                f"case (func{func_type})\n"
                f"{indent(family_body, '    ')}\n"
                f"endcase"
            )

        instruction_cases.append(
            f"4'b{op_code}: begin\n"
            f"{indent(family_body, '    ')}\n"
            f"end"
        )

    case_body = indent("\n".join(instruction_cases), " " * 12)

    verilog = dedent("""\
        module swapio_decode(
            input wire        clk_i,
            input wire        rst_n,
            input wire [15:0] instr_i
        );

            wire [3:0] opcode;
            assign opcode = instr_i[15:12];

            wire       func1;
            assign func1 = instr_i[11];

            wire [1:0] func2;
            assign func2 = instr_i[11:10];

            wire [2:0] func3;
            assign func3 = instr_i[11:9];

            wire [3:0] func4;
            assign func4 = instr_i[11:8];

            reg [2:0]  src;
            reg [2:0]  dst;
            reg [2:0]  pin;
            reg [15:0] imm;
            reg [15:0] addr;
            reg [7:0]  mask;
            reg        clr;
            reg        wait;
            reg        block;

            always @(posedge clk_i or negedge rst_n) begin
                if (!rst_n) begin
                    src   <= 'd0;
                    dst   <= 'd0;
                    pin   <= 'd0;
                    imm   <= 'd0;
                    addr  <= 'd0;
                    clr   <= 'd0;
                    wait  <= 'd0;
                    mask  <= 'd0;
                    block <= 'd0;
                end else begin
                    case (opcode)
        """)

    verilog += case_body + "\n"

    verilog += dedent("""\
                    endcase
                end
            end

        endmodule
        """)

    print(verilog)

def generate(isa_dict):
    parsed_meta = read_meta(isa_dict)
    parsed_fields = read_fields(isa_dict)

    all_instructions = read_instructions(isa_dict, parsed_fields)
    generate_verilog(all_instructions)


if __name__ == "__main__":
    file_path = "../../isa/isa.yaml"

    with open(file_path, "r", encoding="utf-8") as file:
        isa_dict = yaml.safe_load(file)

    generate(isa_dict)
