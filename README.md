# DigitalCircuits-DesigningWorkflow
Repo dedicated to explore different design workflows for digital circuits. It includes HDL 's such as SystemVerilog and VHDL. As well as TCL scripts to automate stimulus definitions and model constraints.
https://systemverilog.dev/3.html

Important Concepts - AI Generated
## 1. Code Abstraction Levels (How Logic is Written)

* Structural Description (Gate-Level): Focuses on how a circuit is physically built. It maps directly to schematic diagrams by explicitly interconnecting basic logic primitives (and, or, not) and sub-modules using wire declarations.
* Behavioral Description: Focuses on what the circuit algorithmically does. It uses high-level constructs (like always blocks, if/else statements, and case statements) to describe logic without manual hardware mapping.
* Dataflow Modeling: A middle-ground approach that describes how data moves through equations using continuous assign statements and bitwise operators.

## 2. Project File Organization (How Code is Saved)

* Single-File Design (Flat File Structure): Placing the top-level entity and all its supporting child sub-modules together inside one single text file (e.g., design.v). It is convenient for small scripts, homework, or quick simulations, but poor for code reuse and teamwork.
* Multi-File Design (Modular File Structure): Giving every distinct module or block its own separate text file, stitched together by a dedicated top-level file. This is the industry standard because it enables block reusability across different projects and prevents Git merge conflicts when multiple engineers cooperate on a codebase.

## 3. File Reference & Compilation (How Tools Read the Project)

* Instantiation Uniformity: The internal Verilog syntax for connecting modules remains identical whether they are written in a single file or spread across multiple files.
* Global Compilation: Tools automatically resolve dependencies by scanning all files loaded into the project workspace to match module declarations with their instantiations.
* The Include Directive (`include): A compilation shortcut used to textually copy-paste separate file blocks into a single top-level file right before compilation begins.

Would you like to write a multi-file template example to practice setting up a project, or should we look at how to manage these files in a specific EDA tool like Vivado or Quartus?

