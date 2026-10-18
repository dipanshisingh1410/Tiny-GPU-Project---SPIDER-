# ISA v2

## Architecture Overview

- All instructions are 32 bits wide.
- Registers and the datapath are **32 bits** wide.
- 8 general-purpose registers (`R0`-`R7`, 3-bit fields).
- Global memory (`GM`) is **word-addressed**: each address holds one 32-bit word, so array element `i` is at `base + i`.
- The PC counts instructions. Branch targets are absolute instruction addresses, so a program can be at most 65,536 instructions long.
- `imm16` is always sign-extended to 32 bits (for `ADDI`, `LDR`/`STR` offsets and `LUI`'s source bits). Branch targets are treated as unsigned instruction addresses.
- Unused instruction bits are "must be zero". Hardware ignores them, but software must not rely on them.

## Registers

`R0` is hardwired to zero. `R1`, `R2` and `R7` are reserved for per-thread values that hardware initializes at thread launch, for easier access. Hardware re-initializes them every time a thread is assigned to a core, so they always reflect the thread currently running.

| Register | Role | Notes |
|----------|------|-------|
| `R0` | Zero | Reads return 0, writes are ignored. |
| `R1` | `src_addr + global_thread_id` | Per-thread source pointer. `LDR Rd, R1, 0` loads this thread's element. |
| `R2` | `dst_addr + global_thread_id` | Per-thread destination pointer. `STR Rd, R2, 0` stores this thread's result. |
| `R3`-`R6` | General purpose | Free for software use. |
| `R7` | `global_thread_id` | The thread's global index. |

Because `GM` is word-addressed, `R1` and `R2` need no scaling: they already point at this thread's element. `R1`, `R2` and `R7` are ordinary writable registers whose initial values are set by hardware at launch. 

## Instruction Formats

All instructions are 32 bits wide.

<table>
  <thead>
    <tr>
      <th>Type</th>
      <th></th>
      <th>31-27</th>
      <th>26-22</th>
      <th>21-19</th>
      <th>18-16</th>
      <th>15-13</th>
      <th>12-10</th>
      <th>9-0</th>
    </tr>
  </thead>
  <tbody>
    <tr align="center">
      <td>Control</td>
      <td>C</td>
      <td>OP_CODE</td>
      <td>OP_FUNC</td>
      <td>-</td>
      <td>Ra</td>
      <td colspan="3">imm16</td>
    </tr>
    <tr align="center">
      <td>Arithmetic</td>
      <td>A</td>
      <td>OP_CODE</td>
      <td>OP_FUNC</td>
      <td>Rd</td>
      <td>Ra</td>
      <td>Rb</td>
      <td>Rc</td>
      <td>-</td>
    </tr>
    <tr align="center">
      <td>Memory</td>
      <td>M</td>
      <td>OP_CODE</td>
      <td>OP_FUNC</td>
      <td>Rd</td>
      <td>Ra</td>
      <td colspan="3">imm16</td>
    </tr>
    <tr align="center">
      <td>Immediate</td>
      <td>I</td>
      <td>OP_CODE</td>
      <td>OP_FUNC</td>
      <td>Rd</td>
      <td>Ra</td>
      <td colspan="3">imm16</td>
    </tr>
  </tbody>
</table>

`Rc` (bits 12-10) is used only by `MAC`. For all other A-type instructions it must be zero. `NOT` ignores `Rb`. `LUI` ignores `Ra`, which must be zero.

## Instruction Set

### Control

| Type | OP_CODE | OP_FUNC | Instruction | Operands | Operation | Description |
|------|---------|---------|-------------|----------|-----------|-------------|
| C | `00000` | `00000` | EXIT | | Exit | Terminates program execution. |
| C | `00000` | `00001` | NOP | | No operation | Does nothing: no register write, no ALU operation, no memory access. Execution continues with the next instruction. |
| C | `00000` | `00011` | BRZ | Ra, imm16 | `PC = (Ra == 0) ? imm16 : PC + 1` | Conditional branch: jumps to the immediate address if `Ra` is zero, otherwise continues sequentially. |

### Arithmetic

| Type | OP_CODE | OP_FUNC | Instruction | Operands | Operation | Description |
|------|---------|---------|-------------|----------|-----------|-------------|
| A | `00001` | `00000` | ADD | Rd, Ra, Rb | `Rd = Ra + Rb` | Adds two registers. |
| A | `00001` | `00001` | SUB | Rd, Ra, Rb | `Rd = Ra - Rb` | Subtracts `Rb` from `Ra`. |
| A | `00001` | `00010` | MUL | Rd, Ra, Rb | `Rd = lower32{Ra*Rb}` | Multiplies two registers and keeps the lower 32 bits of the product. |
| A | `00001` | `00011` | MULH | Rd, Ra, Rb | `Rd = higher32{Ra*Rb}` (signed) | Signed multiply that keeps the upper 32 bits of the 64-bit product. |
| A | `00001` | `00100` | AND | Rd, Ra, Rb | `Rd = Ra & Rb` | Bitwise AND of two registers. |
| A | `00001` | `00101` | OR | Rd, Ra, Rb | `Rd = Ra \| Rb` | Bitwise OR of two registers. |
| A | `00001` | `00110` | XOR | Rd, Ra, Rb | `Rd = Ra ^ Rb` | Bitwise XOR of two registers. |
| A | `00001` | `00111` | NOT | Rd, Ra | `Rd = ~Ra` | Bitwise inversion of `Ra`. |
| A | `00001` | `01000` | SHL | Rd, Ra, Rb | `Rd = Ra << lower5{Rb}` | Logical left shift of `Ra` by the low 5 bits of `Rb`. |
| A | `00001` | `01001` | SHR | Rd, Ra, Rb | `Rd = Ra >> lower5{Rb}` | Logical right shift of `Ra` by the low 5 bits of `Rb` (zero-fill). |
| A | `00001` | `01010` | SRA | Rd, Ra, Rb | `Rd = Ra >>> lower5{Rb}` | Arithmetic right shift of `Ra` by the low 5 bits of `Rb` (sign-extend). |
| A | `00001` | `01011` | MAC | Rd, Ra, Rb, Rc | `Rd = Rc + lower32{Ra*Rb}` | Multiply-accumulate. Requires three register read ports (`Ra`, `Rb`, `Rc`). |

### Comparison (Set Predicate)

Each `SETP` instruction compares `Ra` and `Rb` and writes the boolean result (`0` or `1`) to `Rd`. All compare func codes have bit 4 set (`1xxxx`), so the decoder can identify a compare with a single bit.

| Type | OP_CODE | OP_FUNC | Instruction | Operands | Operation | Description |
|------|---------|---------|-------------|----------|-----------|-------------|
| A | `00001` | `10010` | SETP.lt | Rd, Ra, Rb | `Rd = (Ra < Rb)` (signed) | Sets `Rd` if `Ra` is less than `Rb` (signed). |
| A | `00001` | `10011` | SETP.le | Rd, Ra, Rb | `Rd = (Ra <= Rb)` (signed) | Sets `Rd` if `Ra` is less than or equal to `Rb` (signed). |
| A | `00001` | `10100` | SETP.ltu | Rd, Ra, Rb | `Rd = (Ra < Rb)` (unsigned) | Sets `Rd` if `Ra` is less than `Rb` (unsigned). |

### Memory

| Type | OP_CODE | OP_FUNC | Instruction | Operands | Operation | Description |
|------|---------|---------|-------------|----------|-----------|-------------|
| M | `00100` | `00000` | LDR | Rd, Ra, imm16 | `Rd = GM[Ra + imm16]` | Loads a word from global memory at address `Ra + sext(imm16)` into `Rd`. |
| M | `00100` | `00001` | STR | Rd, Ra, imm16 | `GM[Ra + imm16] = Rd` | Stores `Rd` to global memory at address `Ra + sext(imm16)`. |

### Immediate

| Type | OP_CODE | OP_FUNC | Instruction | Operands | Operation | Description |
|------|---------|---------|-------------|----------|-----------|-------------|
| I | `00010` | `00000` | ADDI | Rd, Ra, imm16 | `Rd = Ra + sext(imm16)` | Adds a sign-extended 16-bit immediate to `Ra`. |
| I | `00010` | `00010` | LUI | Rd, imm16 | `Rd = imm16 << 16` | Loads the 16-bit immediate into the upper half of `Rd` and clears the lower half. `Ra` must be zero. |

## Pseudo-Instructions (assembler only)

These have no encoding of their own. The assembler expands them into the instructions above.

| Pseudo-instruction | Expansion | Notes |
|--------------------|-----------|-------|
| `BRA imm16` | `BRZ R0, imm16` | `R0` is always zero, so the branch is always taken. |
| `MOV Rd, Ra` | `ADDI Rd, Ra, 0` | |
| `MOVI Rd, imm16` | `ADDI Rd, R0, imm16` | Signed 16-bit constant. |
| `MOVI Rd, imm32` | `LUI Rd, hi16` / `ADDI Rd, Rd, lo16` | Full 32-bit constant. The assembler adjusts `hi16` as described above. |
| `SETP.gt Rd, Ra, Rb` | `SETP.lt Rd, Rb, Ra` | Swap operands. |
| `SETP.ge Rd, Ra, Rb` | `SETP.le Rd, Rb, Ra` | Swap operands. |
| `SETP.gtu Rd, Ra, Rb` | `SETP.ltu Rd, Rb, Ra` | Swap operands. |
| Branch if `Ra == Rb` | `XOR t, Ra, Rb` then `BRZ t, target` | 2 instructions. |
| Branch if `Ra != Rb` | `XOR t, Ra, Rb` / `BRZ t, skip` / `BRA target` / `skip:` | 3 instructions. |
| `SETP.eq Rd, Ra, Rb` | `SETP.le t1, Ra, Rb` / `SETP.le t2, Rb, Ra` / `AND Rd, t1, t2` | 3 instructions, 2 temporaries. |
| `SETP.neq Rd, Ra, Rb` | `SETP.lt t1, Ra, Rb` / `SETP.lt t2, Rb, Ra` / `OR Rd, t1, t2` | 3 instructions, 2 temporaries. |

Temporaries (`t`, `t1`, `t2`) must come from the free registers `R3`-`R6`.

## Changes from v1

### Architecture
- Registers and datapath widened from 16 to **32 bits**.

### Registers
- **Added** hardwired zero register `R0`.

### Format
- A-type now has an `Rc` field (bits 12-10), used by `MAC`. Only bits 9-0 are unused.

### Control
- **Removed** `BRA`. It is now the pseudo-instruction `BRZ R0, imm16`.
- **Replaced** `BRP` (branch if `Ra != 0`) with **`BRZ`** (branch if `Ra == 0`) at the same encoding `00000 / 00011`. The polarity is inverted.

### Arithmetic
- `MUL` now returns `lower32{Ra*Rb}` (was `lower16`).
- `MULH` now returns `higher32{Ra*Rb}` (was `higher16`).
- `SHL`, `SHR`, `SRA` use `lower5{Rb}` (was `lower4`), covering shifts of 0-31.
- **Added** `MAC Rd, Ra, Rb, Rc` (`Rd = Rc + Ra*Rb`) at `00001 / 01011`.

### Comparison
- **Removed** `SETP.eq`, `SETP.neq`, `SETP.gt`, `SETP.ge`. `gt` and `ge` are operand-swapped aliases of `lt` and `le`. `eq` and `neq` are expanded as shown in the pseudo-instruction table.
- **Added** `SETP.ltu` (unsigned less-than) at `00001 / 10100`, the slot formerly used by `SETP.gt`.
- `SETP.lt` (`10010`) and `SETP.le` (`10011`) keep their encodings.

### Immediate
- **Removed** `MOV` and `MOVI`. Both are now pseudo-instructions built on `ADDI` with `R0`.
- **Added** `LUI Rd, imm16` (`Rd = imm16 << 16`) at `00010 / 00010`. Together with `ADDI` it loads any 32-bit constant in two instructions.
- `ADDI` is unchanged in encoding. Its immediate is now explicitly sign-extended to 32 bits.

### Unchanged
- `EXIT`, `NOP`, `ADD`, `SUB`, `AND`, `OR`, `XOR`, `NOT`, `LDR`, `STR` and all of their encodings.
