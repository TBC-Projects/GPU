# ALU (Arithmetic Logic Unit)

## What is an ALU?

The ALU (Arithmetic Logic Unit) is the part of a processor that does arithmetic and logical operations on data. It basically takes in input operands and produces computed results based on a control signal. This ALU is a 32-bit combinational unit that supports basic arithmetic and bitwise logical operations. It is implemented with separate components for arithmetic, logic, and result selection.

## Supported Operations

The ALU currently supports the following operations:

| Operation | Description | Select (`sel`) |
| --------- | ----------- | -------------- |
| ADD       | a + b       | 00             |
| AND       | a & b       | 01             |
| OR        | a | b       | 10             |
| XOR       | a ^ b       | 11             |

## Architecture

The ALU is composed of three main modules:

### 1. Adder

* Performs 32-bit unsigned addition
* Implemented as combinational logic

### 2. Logic Operations Unit

* Computes bitwise AND, OR, and XOR in parallel

### 3. ALU Multiplexer

* Selects the final output based on the control signal (`sel`)
* Ensures only one operation result is forwarded

## Data Width

* All inputs and outputs are 32 bits wide
