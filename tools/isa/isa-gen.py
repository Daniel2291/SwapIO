import sys
import yaml

def read_meta(isa_dict):
    cur_dict = isa_dict["meta"]

    parsed_meta = dict()

    assert (cur_dict["word_bits"] == 16)
    parsed_meta["word_bits"] = cur_dict["word_bits"];

    assert (cur_dict["pc_bits"] == 9)
    parsed_meta["pc_bits"] = cur_dict["pc_bits"];

    assert (cur_dict["csr"] == 10)
    parsed_meta["csr_count"] = cur_dict["csr"];

    assert (cur_dict["registers"] == 8)
    parsed_meta["registers"] = cur_dict["registers"];

    return parsed_meta

def read_fields(isa_dict: dict):
    cur_dict = isa_dict["fields"]
    parsed_fields = dict();

    for key, val in cur_dict.items():
        name = val["name"]
        verilog_field = val["verilog_field"]

        parsed_fields[name] = verilog_field;

    return parsed_fields

def read_instructions(isa_dict: dict, parsed_fields: dict):
    cur_dict = isa_dict["instructions"]
    all_instructions = list()

    for item in cur_dict:
        name = item["name"]
        format = item["fmt"]
        func_type = item["func"]

        positions = dict()
        to_parse = list()
        opcode = format[0:3]


        for index, char in enumerate(format):
            positions[char].append(index)

        for key, val in format.items():
            if key in ["0", "1", "-"]:
                continue

            cnt = len(val)
            assert (len(val) > 0)

            first_pos = val[0]
            to_parse.append((parsed_fields[key], first_pos, cnt))
            
        all_instructions.append((name, to_parse))

    return all_instructions

def generate_verilog(all_instructions: list):
    instruction_cases = ""

    for instruction_name, to_parse in all_instructions:
        #instruction_to_add = format(4'b)
        ...

    fin_str = format("""module swapio_decode(
        input wire         clk_i,
        input wire         rst_n,
        input wire[15:0]   instr_i
    );

     wire [3:0] opcode;
     assign opcode = instr_i[15:12];

     wire [1:0] func1;
     assign func1 = instr_i[11:11];

     wire [1:0] func2;
     assign func2 = instr_i[11:10];

     wire [2:0] func3;
     assign func3 = instr_i[11:9];

     wire [3:0] func4;
     assign func4 = instr_i[11:8];

     reg [2: 0]  src;
     reg [2: 0]  dst;
     reg [2: 0]  pin;
     reg [15:0]  imm;
     reg [15:0]  addr;
     reg [7: 0]  mask;
     reg         clr;
     reg         wait;
     reg         block;


     always @(posedge clk_i or negedge rst_n) begin
        if (!rst_n) begin
         src  <= 'd0;
         dst  <= 'd0;
         pin  <= 'd0;
         imm  <= 'd0;
         addr <= 'd0;
         clr  <= 'd0;
         wait <= 'd0;
         mask <= 'd0;
        end

        case (opcode) begin
         {}
        endcase
     end
    """, instruction_cases)

def generate(isa_dict):
    parsed_meta = read_meta(isa_dict)
    parsed_fields = read_fields(isa_dict)

    read_instructions(isa_dict, parsed_fields)


if __name__ == "__main__":
    file_path = "../../isa/isa.yaml"

    with open(file_path, "r", encoding="utf-8") as file:
        isa_dict = yaml.safe_load(file)

        generate(isa_dict)

