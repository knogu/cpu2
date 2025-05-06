import dataclasses
import os
import subprocess


def collect_status(result: list):
    all_states = []
    cur_state: dict = {}
    for line in result:
        if "===" in line:
            all_states.append(cur_state)
            cur_state = {}
            continue
        if ":" in line and not "cpu.v" in line:
            label, val = line.split(":")
            try:
                cur_state[label] = int(val)
            except:
                cur_state[label] = val # maybe better to warn
    return all_states


insts0 = [
    "`MM[0]=32'b00000000000100000000000010010011;" # addi x1, x0, 1
    "`MM[1]=32'b00000000001000000000000100010011;" # addi x2, x0, 2
    "`MM[2]=32'b00000000001000001000000110110011;" # add  x3, x1, x2
]

assertions0 = [
    {"pc": 0},
    {"pc": 0, "imm": 1, "second_operand": 1, "alu_res": 1},
    {"pc": 4},
    {"pc": 4, "imm": 2, "second_operand": 2, "alu_res": 2},
]

insts2 = [
    "`MM[0]={12'd7,5'd0,3'd0,5'd1,7'h13};     // addi x1,x0,7",
    "`MM[1]={7'd0,5'd1,5'd0,3'h2,5'd8,7'h23}; // sw x1, 8(x0)",
    "`MM[2]={12'd8,5'd0,3'b010,5'd2,7'h3};    // lw x2, 8(x0)",
]

assertions2 = [
    {"pc": 0},
    {"pc": 0, "rd": 1, "rs1": 0, "imm": 7, "alu_res": 7, "result": 7},
    {"pc": 4, "x1": 7},
    {"pc": 4, "rs2": 1, "rs1": 0, "imm": 8, "alu_res": 8, "result": 8},
    {"pc": 8},
    {"pc": 8, "rd": 2, "imm": 8, "second_operand": 8, "rs1": 0, "alu_res": 8, "result": 7},
    {"pc": 12, "x2": 7}
]

insts3 = [
    "`MM[0]={1'b0,10'b0000000100,1'b0,8'b00000000,5'd1,7'b1101111};     // jal 8",
    "`MM[1]={12'd7,5'd0,3'd0,5'd1,7'h13};     // addi x1,x0,7",
    "`MM[2]={12'd7,5'd0,3'd0,5'd1,7'h13};     // addi x1,x0,7",
]

assertions3 = [
    {"pc": 0},
    {"pc": 0, "result_src": 10, "result": 4},
    {"pc": 8, "x1": 4}
]

insts4 = [
    "`MM[0]=32'b00000000010100000000000010010011;   // addi x1, x0, 5",
    "`MM[1]=32'b00000000000100000000000100010011;   // L: addi x2, x0, 1",
    "`MM[2]={~7'd0,5'd2,5'd1,3'h0,5'h1d,7'h63};     // beq x1, x2, L", # not eq. so expected not to branch
    "`MM[3]=32'b00000000000000000000000000110011;   // add x0, x0, x0",
]

assertions4 = [
    {"pc": 0},
    {"pc": 0, "second_operand": 5, "result": 5},
    {"pc": 4, "x1": 5},
    {"pc": 4, "second_operand": 1, "result": 1},
    {"pc": 8, "x2": 1},
    {"pc": 8, "imm": -4, "next_pc": 12},
    {"pc": 12}
]

insts5 = [
    "`MM[0]=32'b00000000010100000000000010010011;   // addi x1, x0, 5",
    "`MM[1]=32'b00000000010100000000000100010011;   // L: addi x2, x0, 5",
    "`MM[2]={~7'd0,5'd2,5'd1,3'h0,5'h1d,7'h63};     // beq x1, x2, L", # eq. so expected to branch
    "`MM[3]=32'b00000000000000000000000000110011;   // add x0, x0, x0",
]

assertions5 = [
    {"pc": 0},
    {"pc": 0, "second_operand": 5, "result": 5},
    {"pc": 4, "x1": 5},
    {"pc": 4, "rd": 2, "second_operand": 5, "result": 5},
    {"pc": 8, "x2": 5},
    {"pc": 8, "imm": -4, "next_pc": 4},
    {"pc": 4}
]

insts6 = [
    "`MM[0]=32'b00000000010100000000000010010011;   // addi x1, x0, 5",
    "`MM[1]=32'b00000000000100000000000100010011;   // L: addi x2, x0, 1",
    "`MM[2]={~7'd0,5'd2,5'd1,3'h1,5'h1d,7'h63};     // bne x1, x2, L", # not eq. so expected to branch
    "`MM[3]=32'b00000000000000000000000000110011;   // add x0, x0, x0",
]

assertions6 = [
    {"pc": 0},
    {"pc": 0, "second_operand": 5, "result": 5},
    {"pc": 4, "x1": 5},
    {"pc": 4, "second_operand": 1, "result": 1},
    {"pc": 8, "x2": 1},
    {"pc": 8, "imm": -4, "next_pc": 4},
    {"pc": 4}
]

insts7 = [
    "`MM[0]=32'b00000000010100000000000010010011;   // addi x1, x0, 5",
    "`MM[1]=32'b00000000010100000000000100010011;   // L: addi x2, x0, 5",
    "`MM[2]={~7'd0,5'd2,5'd1,3'h1,5'h1d,7'h63};     // bne x1, x2, L", # eq. so expected not to branch
    "`MM[3]=32'b00000000000000000000000000110011;   // add x0, x0, x0",
]

assertions7 = [
    {"pc": 0},
    {"pc": 0, "second_operand": 5, "result": 5},
    {"pc": 4, "x1": 5},
    {"pc": 4, "rd": 2, "second_operand": 5, "result": 5},
    {"pc": 8, "x2": 5},
    {"pc": 8, "imm": -4, "next_pc": 12},
    {"pc": 12}
]

# insts4 = [
#     "`MM[0]={12'd7,5'd0,3'd0,5'd1,7'h13};     // addi x1, x0, 7",
#     "`MM[1]={7'd0,5'd0,5'd1,3'b110,5'b00010,7'b0110011}; // or   x2, x1, x0",
#     "`MM[2]={7'd0,5'd0,5'd1,3'b111,5'b00010,7'b0110011}; // and  x2, x1, x0",
#     "`MM[3]={12'b000000000111, 5'b00001, 3'b111, 5'b00010, 7'b0010011}; // andi  x2, x1, 7",
#     "`MM[4]={12'b000000000111, 5'b00001, 3'b110, 5'b00010, 7'b0010011}; // ori  x2, x0, 7",
# ]

# assertions4 = [
#     {"pc": 0},
#     {"pc": 4, "x1": 7},
#     {"pc": 8, "x2": 7, "x1": 7},
#     {"pc": 12, "x2": 0},
#     {"pc": 16, "x2": 7},
#     {"pc": 20, "x2": 7},
# ]

# insts5 = [
#     "`MM[0]={20'b11111111111111111111,5'd1,7'b0110111}; // lui x1, 1048575",
# ]

# assertions5 = [
#     {"pc": 0, "w_is_u": 1, "imm": 4294963200},
#     {"pc": 4, "x1": 4294963200}
# ]

# insts6 = [
#     "`MM[0]={20'b11111111111111111111,5'd1,7'b0010111}; // auipc x1, 1048575",
#     "`MM[1]={20'b11111111111111111111,5'd1,7'b0010111}; // auipc x1, 1048575",
# ]

# assertions6 = [
#     {"pc": 0, "w_is_u": 1},
#     {"pc": 4, "x1": 4294963200},
#     {"pc": 8, "x1": 4294963204},
# ]

scenarios = [(insts0, assertions0), (insts2, assertions2), (insts3, assertions3), (insts4, assertions4), (insts5, assertions5), (insts6, assertions6), (insts7, assertions7)]

for ith, (insts, assertions) in enumerate(scenarios, start=0):
    for j, inst in enumerate(insts):
        if not "[" + str(j) + "]" in inst:
            print("check " + str(ith) + "-th inst: " + inst)
            exit(2)
    # Prepare instructions
    with open(os.path.expanduser('asm.txt'), 'w', encoding='utf-8') as f:
        for inst in insts:
            f.write(inst + '\n')
    # Execute simulation
    result = subprocess.run(['iverilog cpu.v simulation_imem.v && vvp a.out'], shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    # Check result
    status = collect_status(result.stdout.splitlines())

    for i, assertion in enumerate(assertions):
        for label, val in assertion.items():
            if (len(status) <= i):
                print("index " + str(i) + " is too big.")
                print(status)
                exit(3)
            if status[i][label] != val:
                print("Assertion failed in " + str(ith) + "-th scenario")
                print("actual PC: " + str(status[i]["pc"]))
                print("assertion index: " + str(i))
                print(label)
                print("expected: ", val)
                print("actual: ", status[i][label])
                exit(1)

    print(str(ith) + "-th scenario succeeded")
