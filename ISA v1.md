# ISA v1

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
      <td>-</td>
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

## Instruction Set

### Control

| Type | OP_CODE | OP_FUNC | Instruction | Operands | Operation | Description |
|------|---------|---------|-------------|----------|-----------|-------------|
| C | `00000` | `00000` | EXIT | | Exit | Terminates program execution. |
| C | `00000` | `00001` | NOP | | No operation | Does nothing; execution continues with the next instruction. |
| C | `00000` | `00010` | BRA | imm16 | `PC = imm16` | Unconditional branch: jumps to the address given by the immediate. |
| C | `00000` | `00011` | BRP | Ra, imm16 | `PC = Ra ? imm16 : PC + 1` | Conditional branch: jumps to the immediate address if `Ra` is non-zero, otherwise continues sequentially. |

### Arithmetic

| Type | OP_CODE | OP_FUNC | Instruction | Operands | Operation | Description |
|------|---------|---------|-------------|----------|-----------|-------------|
| A | `00001` | `00000` | ADD | Rd, Ra, Rb | `Rd = Ra + Rb` | Adds two registers. |
| A | `00001` | `00001` | SUB | Rd, Ra, Rb | `Rd = Ra - Rb` | Subtracts `Rb` from `Ra`. |
| A | `00001` | `00010` | MUL | Rd, Ra, Rb | `Rd = lower16{Ra*Rb}` | Multiplies two registers and keeps the lower 16 bits of the product. |
| A | `00001` | `00011` | MULH | Rd, Ra, Rb | `Rd = higher16{Ra*Rb}` (signed) | Signed multiply that keeps the upper 16 bits of the product. |
| A | `00001` | `00100` | AND | Rd, Ra, Rb | `Rd = Ra & Rb` | Bitwise AND of two registers. |
| A | `00001` | `00101` | OR | Rd, Ra, Rb | `Rd = Ra \| Rb` | Bitwise OR of two registers. |
| A | `00001` | `00110` | XOR | Rd, Ra, Rb | `Rd = Ra ^ Rb` | Bitwise XOR of two registers. |
| A | `00001` | `00111` | NOT | Rd, Ra | `Rd = ~Ra` | Bitwise inversion of `Ra`. |
| A | `00001` | `01000` | SHL | Rd, Ra, Rb | `Rd = Ra << lower4{Rb}` | Logical left shift of `Ra` by the low 4 bits of `Rb`. |
| A | `00001` | `01001` | SHR | Rd, Ra, Rb | `Rd = Ra >> lower4{Rb}` | Logical right shift of `Ra` by the low 4 bits of `Rb` (zero-fill). |
| A | `00001` | `01010` | SRA | Rd, Ra, Rb | `Rd = Ra >>> lower4{Rb}` | Arithmetic right shift of `Ra` by the low 4 bits of `Rb` (sign-extend). |

### Comparison (Set Predicate)

Each `SETP` instruction compares `Ra` and `Rb` and writes the boolean result to `Rd`.

| Type | OP_CODE | OP_FUNC | Instruction | Operands | Operation | Description |
|------|---------|---------|-------------|----------|-----------|-------------|
| A | `00001` | `10000` | SETP.eq | Rd, Ra, Rb | `Rd = (Ra == Rb)` | Sets `Rd` if `Ra` equals `Rb`. |
| A | `00001` | `10001` | SETP.neq | Rd, Ra, Rb | `Rd = (Ra != Rb)` | Sets `Rd` if `Ra` does not equal `Rb`. |
| A | `00001` | `10010` | SETP.lt | Rd, Ra, Rb | `Rd = (Ra < Rb)` (signed) | Sets `Rd` if `Ra` is less than `Rb` (signed). |
| A | `00001` | `10011` | SETP.le | Rd, Ra, Rb | `Rd = (Ra <= Rb)` (signed) | Sets `Rd` if `Ra` is less than or equal to `Rb` (signed). |
| A | `00001` | `10100` | SETP.gt | Rd, Ra, Rb | `Rd = (Ra > Rb)` (signed) | Sets `Rd` if `Ra` is greater than `Rb` (signed). |
| A | `00001` | `10101` | SETP.ge | Rd, Ra, Rb | `Rd = (Ra >= Rb)` (signed) | Sets `Rd` if `Ra` is greater than or equal to `Rb` (signed). |

### Memory

| Type | OP_CODE | OP_FUNC | Instruction | Operands | Operation | Description |
|------|---------|---------|-------------|----------|-----------|-------------|
| M | `00100` | `00000` | LDR | Rd, Ra, imm16 | `Rd = GM[Ra + imm16]` | Loads a value from global memory at address `Ra + imm16` into `Rd`. |
| M | `00100` | `00001` | STR | Rd, Ra, imm16 | `GM[Ra + imm16] = Rd` | Stores `Rd` to global memory at address `Ra + imm16`. |

### Immediate

| Type | OP_CODE | OP_FUNC | Instruction | Operands | Operation | Description |
|------|---------|---------|-------------|----------|-----------|-------------|
| I | `00010` | `00000` | ADDI | Rd, Ra, imm16 | `Rd = Ra + imm16` | Adds a 16-bit immediate to `Ra`. |
| I | `00010` | `11000` | MOV | Rd, Ra | `Rd = Ra` | Copies one register into another. |
| I | `00010` | `11001` | MOVI | Rd, imm16 | `Rd = imm16` | Loads a 16-bit immediate into `Rd`. |