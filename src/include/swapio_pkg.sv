package swapio_pkg;

 ////////////////////////////////////////////////
 //    ___         ____          _             //
 //   / _ \ _ __  / ___|___   __| | ___  ___   //
 //  | | | | '_ \| |   / _ \ / _` |/ _ \/ __|  //
 //  | |_| | |_) | |__| (_) | (_| |  __/\__ \  //
 //   \___/| .__/ \____\___/ \__,_|\___||___/  //
 //        |_|                                 //
 ////////////////////////////////////////////////

 parameter OPCODE_SYS = 4'b0000;
 parameter OPCODE_BRANCH = 4'b0001;
 parameter OPCODE_SET = 4'b0010;
 parameter OPCODE_MOV = 4'b0011;
 parameter OPCODE_SHIFT_REG = 4'b0100;
 parameter OPCODE_FIFO = 4'b0101;
 parameter OPCODE_WAIT = 4'b0110;
 parameter OPCODE_PIN = 4'b0111;
 parameter OPCODE_WAIT_CYCLES = 4'b1000;
 parameter OPCODE_ALU = 4'b1001;
 parameter OPCODE_ALU_IMM = 4'b1010;
 parameter OPCODE_CSR_RW = 4'b1011;
 parameter OPCODE_LDST = 4'b1100;

endpackage
