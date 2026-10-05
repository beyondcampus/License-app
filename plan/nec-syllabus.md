# NEC Computer Engineering Licence Exam — Syllabus

Source: Nepal Engineering Council syllabus as supplied by the project owner on 2026-09-24.
Wording follows the source; obvious spelling errors were corrected (e.g. "start-delta" → "star-delta",
"Multiplexetures" → "Multiplexers", "Mater-Slave" → "Master-Slave", "Redix" → "Radix",
"Curch Turing" → "Church–Turing"). Section codes are reproduced where the source prints them.

## How this maps to the app

| Syllabus | App |
|---|---|
| Chapter *N* | `chN` in the `chapters` table (Chapter 10 has **no app chapter yet**) |
| Section *N.M* | parent topic `chN_pM` — done for Chapter 1; Chapters 2–9 are still flat topic lists |
| Items inside a section | subtopics (`chN_tM`, `chN_iMx`) |

---

## 1. Concept of Basic Electrical and Electronics Engineering (AExE01) — app `ch1`

Section codes for this chapter are not printed in the source; by the pattern used elsewhere they are AExE0101–AExE0106.

### 1.1 Basic concept — app `ch1_p1`
- Ohm's law
- Electric voltage, current, power and energy
- Conducting and insulating materials
- Series and parallel electric circuits
- Star-delta and delta-star conversion
- Kirchhoff's law
- Linear and non-linear circuits
- Bilateral and unilateral circuits
- Active and passive circuits

### 1.2 Network theorems — app `ch1_p2`
- Concept of superposition theorem
- Thevenin's theorem
- Norton's theorem
- Maximum power transfer theorem
- R-L, R-C, R-L-C circuits
- Resonance in AC series and parallel circuits
- Active and reactive power

### 1.3 Alternating current fundamentals — app `ch1_p3`
- Principle of generation of alternating voltages and currents; their equations and waveforms
- Average, peak and RMS values
- Three-phase system

### 1.4 Semiconductor devices — app `ch1_p4`
- Semiconductor diode and its characteristics
- BJT configuration and biasing
- Small- and large-signal models
- Working principle and applications of MOSFET and CMOS

### 1.5 Signal generator — app `ch1_p5`
- Basic principles of waveform generators
- Oscillators
- RC, LC and crystal oscillator circuits

### 1.6 Amplifiers — app `ch1_p6`
- Classification of output stages
- Class A output stage
- Class B output stage
- Class AB output stage
- Biasing the class AB stage
- Power BJTs
- Transformer-coupled push-pull stages
- Tuned amplifiers
- Op-amps

*(App-only extra: `ch1_p7` Quick Revision — Important Formulas.)*

---

## 2. Digital Logic and Microprocessor (AExE02) — app `ch2`

### 2.1 Digital logic (AExE0201)
- Number systems
- Logic levels
- Logic gates
- Boolean algebra
- Sum-of-products method
- Product-of-sums method
- Truth table to Karnaugh map

### 2.2 Combinational and arithmetic circuits (AExE0202)
- Multiplexers
- Demultiplexers
- Decoder
- Encoder
- Binary addition
- Binary subtraction
- Operations on unsigned and signed binary numbers

### 2.3 Sequential logic circuit (AExE0203)
- RS flip-flops
- Gated flip-flops
- Edge-triggered flip-flops
- Master-slave flip-flops
- Types of registers
- Applications of shift registers
- Asynchronous counters
- Synchronous counters

### 2.4 Microprocessor (AExE0204)
- Internal architecture and features of a microprocessor
- Assembly language programming

### 2.5 Microprocessor system (AExE0205)
- Memory device classification and hierarchy
- Interfacing I/O and memory
- Parallel interface
- Introduction to Programmable Peripheral Interface (PPI)
- Serial interface
- Synchronous and asynchronous transmission
- Serial interface standards
- Introduction to Direct Memory Access (DMA) and DMA controllers

### 2.6 Interrupt operations (AExE0206)
- Interrupt
- Interrupt service routine
- Interrupt processing

---

## 3. Programming Language and Its Applications (ACtE03) — app `ch3`

### 3.1 Introduction to C programming (ACtE0301)
- C tokens
- Operators
- Formatted/unformatted input/output
- Control statements
- Looping
- User-defined functions
- Recursive functions
- Arrays (1-D, 2-D, multi-dimensional)
- String manipulation

### 3.2 Pointers, structures and data files in C (ACtE0302)
- Pointer arithmetic
- Pointers and arrays
- Passing pointers to functions
- Structure vs union
- Array of structures
- Passing structures to functions
- Structures and pointers
- Input/output operations on files
- Sequential and random access to files

### 3.3 C++ language constructs with objects and classes (ACtE0303)¹
- Namespace
- Function overloading
- Inline functions
- Default arguments
- Pass/return by reference
- Introduction to class and object
- Access specifiers
- Objects and member access
- Defining member functions
- Constructors and their types; destructor
- Dynamic memory allocation for objects and object arrays
- `this` pointer
- Static data members and static functions
- Constant member functions and constant objects
- Friend functions and friend classes

¹ The source prints ACtE0301 here (same as 3.1); ACtE0303 is presumably intended.

### 3.4 Features of object-oriented programming (ACtE0304)
- Operator overloading (unary, binary)
- Data conversion
- Inheritance (single, multiple, multilevel, hybrid, multipath)
- Constructors/destructors in single and multilevel inheritance

### 3.5 Pure virtual functions and file handling (ACtE0305)
- Virtual functions
- Dynamic binding
- Defining, opening and closing a file
- Input/output operations on files
- Error handling during input/output operations
- Stream class hierarchy for console input/output
- Unformatted input/output
- Formatted input/output with `ios` member functions and flags
- Formatting with manipulators

### 3.6 Generic programming and exception handling (ACtE0306)
- Function templates
- Overloading function templates
- Class templates
- Function definitions of class templates
- Standard Template Library (containers, algorithms, iterators)
- Exception handling constructs (try, catch, throw)
- Multiple exception handling
- Rethrowing exceptions
- Catching all exceptions
- Exceptions with arguments
- Exception specifications for functions
- Handling uncaught and unexpected exceptions

---

## 4. Computer Organization and Embedded System (ACtE04) — app `ch4`

### 4.1 Control and central processing units (ACtE0401)
- Control memory
- Address sequencing
- Computer configuration
- Microinstruction format
- Design of control unit
- CPU structure and function
- Arithmetic and logic unit
- Instruction formats
- Addressing modes
- Data transfer and manipulation
- RISC and CISC
- Pipelining and parallel processing

### 4.2 Computer arithmetic and memory system (ACtE0402)
- Arithmetic and logical operations
- The memory hierarchy
- Internal and external memory
- Cache memory principles
- Elements of cache design: cache size, mapping function, replacement algorithm, write policy, number of caches
- Memory write ability and storage permanence
- Composing memory

### 4.3 Input-output organization and multiprocessors (ACtE0403)
- Peripheral devices
- I/O modules and input-output interface
- Modes of transfer
- Direct memory access
- Characteristics of multiprocessors
- Interconnection structure
- Inter-processor communication and synchronization

### 4.4 Hardware-software design issues in embedded systems (ACtE0404)
- Embedded systems overview
- Classification of embedded systems
- Custom single-purpose processor design
- Optimizing custom single-purpose processors
- Basic architecture, operation and programmer's view
- Development environment
- Application-specific instruction-set processors

### 4.5 Real-time operating and control systems (ACtE0405)
- Operating system basics
- Task, process and threads
- Multiprocessing and multitasking
- Task scheduling
- Task synchronization
- Device drivers
- Open-loop and closed-loop control system overview
- Control

### 4.6 Hardware description language and IC technology (ACtE0406)
- VHDL overview
- Overflow and data representation using VHDL
- Design of combinational and sequential logic using VHDL
- Pipelining using VHDL

---

## 5. Concept of Computer Network and Network Security System (ACtE05) — app `ch5`

### 5.1 Introduction to computer networks and physical layer (ACtE0501)
- Networking models
- Protocols and standards
- OSI model and TCP/IP model
- Networking devices (hubs, bridges, switches, routers)
- Transmission media

### 5.2 Data link layer (ACtE0502)
- Services
- Error detection and correction
- Flow control
- Data link protocols
- Multiple access protocols
- LAN addressing and ARP (Address Resolution Protocol)
- Ethernet: IEEE 802.3 (Ethernet), 802.4 (Token Bus), 802.5 (Token Ring)
- CSMA/CD
- Wireless LANs
- PPP (Point-to-Point Protocol)
- Wide area protocols

### 5.3 Network layer (ACtE0503)
- Addressing (Internet address, classful address)
- Subnetting
- Routing protocols (RIP, OSPF, BGP; unicast and multicast routing protocols)
- Routing algorithms (shortest path, flooding, distance vector, link state)
- Protocols: ARP, RARP, IP, ICMP
- IPv6: packet formats, extension headers, transition from IPv4 to IPv6, multicasting

### 5.4 Transport layer (ACtE0504)
- The transport service
- Transport protocols
- Ports and sockets
- Connection establishment and connection release
- Flow control and buffering
- Multiplexing and demultiplexing
- Congestion control algorithms

### 5.5 Application layer (ACtE0505)
- Web (HTTP and HTTPS)
- File transfer (FTP, PuTTY, WinSCP)
- Electronic mail
- DNS
- P2P applications
- Socket programming
- Application server concept
- Traffic analysers (MRTG, PRTG, SNMP, Packet Tracer, Wireshark)

### 5.6 Network security (ACtE0506)
- Types of computer security
- Types of security attacks
- Principles of cryptography
- RSA algorithm
- Digital signatures
- Securing e-mail (PGP)
- Securing TCP connections (SSL)
- Network layer security (IPsec, VPN)
- Securing wireless LANs (WEP)
- Firewalls

---

## 6. Theory of Computation and Computer Graphics (ACtE06) — app `ch6`

### 6.1 Introduction to finite automata (ACtE0601)
- Finite automata and finite state machines
- Equivalence of DFA and NDFA
- Minimization of finite state machines
- Regular expressions
- Equivalence of regular expressions and finite automata
- Pumping lemma for regular languages

### 6.2 Introduction to context-free languages (ACtE0602)
- Context-free grammar (CFG)
- Derivation trees (bottom-up and top-down; leftmost and rightmost; language of a grammar)
- Parse trees and their construction
- Ambiguous grammars
- Chomsky Normal Form (CNF)
- Greibach Normal Form (GNF)
- Backus-Naur Form (BNF)
- Pushdown automata
- Equivalence of context-free languages and PDA
- Pumping lemma for context-free languages
- Properties of context-free languages

### 6.3 Turing machines (ACtE0603)
- Introduction and notation of Turing machines (TM)
- Acceptance of a string by a TM
- TM as a language recognizer
- TM as a computing function
- TM as an enumerator of strings of a language
- TM with multiple tracks
- TM with multiple tapes
- Non-deterministic TM
- Church–Turing thesis
- Universal TM and encoding of TMs
- Computational complexity; time and space complexity of a TM
- Intractability
- Reducibility

### 6.4 Introduction to computer graphics (ACtE0604)
- Overview of computer graphics
- Graphics hardware: display technology, raster-scan display architecture, vector displays, display processors, output and input devices
- Graphics software and software standards

### 6.5 Two-dimensional transformations (ACtE0605)
- 2D translation, rotation, scaling, reflection, shear
- 2D composite transformations
- 2D viewing pipeline
- World-to-screen viewing transformation
- Clipping: Cohen–Sutherland line clipping, Liang–Barsky line clipping

### 6.6 Three-dimensional transformations (ACtE0606)
- 3D translation, rotation, scaling, reflection, shear
- 3D composite transformations
- 3D viewing pipeline
- Projection concepts: orthographic, parallel, perspective

---

## 7. Data Structures and Algorithm, Database System and Operating System (ACtE07) — app `ch7`

### 7.1 Data structures, lists, linked lists and trees (ACtE0701)
- Data types, data structures and abstract data types
- Time and space analysis of algorithms (Big-O, Omega and Theta notations)
- Linear data structures: stack and queue implementation
- Stack applications: infix to postfix conversion, evaluation of postfix expressions
- Array implementation of lists; stacks and queues as lists
- Static and dynamic list structures
- Dynamic implementation of linked lists
- Types of linked list: singly, doubly, circular
- Basic operations: creation, insertion at different positions, deletion from different positions
- Doubly linked lists and their applications
- Concept of tree; operations on binary trees
- Tree search; insertion/deletion in binary trees
- Tree traversals (pre-order, post-order, in-order)
- Height, level and depth of a tree
- AVL balanced trees

### 7.2 Sorting, searching and graphs (ACtE0702)
- Types of sorting: internal and external
- Insertion and selection sort
- Exchange sort
- Merge and radix sort
- Shell sort
- Heap sort as a priority queue
- Big-O notation and efficiency of sorting
- Search techniques: sequential search, binary search, tree search
- General search trees
- Hashing: hash functions, hash tables, collision resolution techniques
- Undirected and directed graphs; representation of graphs
- Transitive closure of a graph; Warshall's algorithm
- Depth-first and breadth-first traversal
- Topological sorting (depth-first, breadth-first)
- Minimum spanning trees (Prim's, Kruskal's, round-robin algorithms)
- Shortest-path algorithms (greedy algorithm, Dijkstra's algorithm)

### 7.3 Data models, normalization and SQL (ACtE0703)
- Data abstraction and data independence
- Schema and instances
- E-R model; strong and weak entity sets; attributes and keys; E-R diagrams
- Normal forms (1NF, 2NF, 3NF, BCNF)
- Functional dependencies
- Integrity constraints and domain constraints
- Relations (joined, derived)
- Queries under DDL and DML commands
- Views; assertions and triggers
- Relational algebra
- Query cost estimation; query operations; evaluation of expressions
- Query optimization; query decomposition

### 7.4 Transaction processing, concurrency control and crash recovery (ACtE0704)
- ACID properties
- Concurrent executions
- Serializability
- Lock-based protocols
- Deadlock handling and prevention
- Failure classification
- Recovery and atomicity
- Log-based recovery

### 7.5 Operating systems and process management (ACtE0705)
- Evolution and types of operating systems
- OS components, structure and services
- Process: description, states, control
- Threads; processes and threads
- Types of scheduling
- Principles of concurrency; critical region; race condition; mutual exclusion
- Semaphores and mutex; message passing; monitors
- Classical problems of synchronization

### 7.6 Memory management, file systems and system administration (ACtE0706)
- Memory addresses
- Swapping and managing free memory space
- Virtual memory management; demand paging; performance
- Page replacement algorithms
- Files, directories and file paths
- File system implementation
- Impact of allocation policy on fragmentation
- Mapping file blocks on the disk platter
- File system performance
- Administration tasks; user account management
- Start-up and shutdown procedures

---

## 8. Software Engineering and Object-Oriented Analysis & Design (ACtE08) — app `ch8`

### 8.1 Software process and requirements (ACtE0801)
- Software characteristics; software quality attributes
- Software process models (Agile, V-model, iterative, prototype, big bang)
- Computer-aided software engineering
- Functional and non-functional requirements
- User requirements; system requirements
- Interface specification
- The software requirements document
- Requirements elicitation and analysis
- Requirements validation and management

### 8.2 Software design (ACtE0802)
- Design process; design concepts; design model; design heuristics
- Architectural design decisions
- System organization
- Modular decomposition styles
- Control styles
- Reference architectures
- Multiprocessor architecture
- Client–server architectures
- Distributed object architectures
- Inter-organizational distributed computing
- Real-time software design
- Component-based software engineering

### 8.3 Software testing, cost estimation, quality management and configuration management (ACtE0803)
- Unit, integration, system, component and acceptance testing
- Test case design; test automation; metrics for testing
- Algorithmic cost modelling; project duration and staffing
- Software quality assurance; formal technical reviews; formal approaches to SQA; statistical SQA
- A framework for software metrics; metrics for analysis and design models
- ISO standards; CMMI; SQA plan
- Configuration management planning; change management; version and release management
- CASE tools for configuration management

### 8.4 Object-oriented fundamentals and analysis (ACtE0804)
- Defining models
- Requirement process
- Use cases
- Object-oriented development cycle
- Unified Modeling Language
- Building a conceptual model
- Adding associations and attributes
- Representation of system behaviour

### 8.5 Object-oriented design (ACtE0805)
- Analysis to design
- Describing and elaborating use cases
- Collaboration diagrams
- Objects and patterns
- Determining visibility
- Class diagrams

### 8.6 Object-oriented design implementation (ACtE0806)
- Programming and development process
- Mapping design to code
- Creating class definitions from design class diagrams
- Creating methods from collaboration diagrams
- Updating class definitions
- Classes in code
- Exception and error handling

---

## 9. Artificial Intelligence and Neural Networks (ACtE09) — app `ch9`

### 9.1 Introduction to AI and intelligent agents (ACtE0901)
- Concept of artificial intelligence; AI perspectives; history; applications; foundations
- Introduction to agents; structure and properties of intelligent agents
- PEAS description of agents
- Types of agents: simple reflex, model-based, goal-based, utility-based
- Environment types: deterministic, stochastic, static, dynamic, observable, semi-observable, single agent, multi agent

### 9.2 Problem solving and searching techniques (ACtE0902)
- Definition; problem as a state-space search; problem formulation; well-defined problems
- Constraint satisfaction problems
- Uninformed search: depth-first, breadth-first, depth-limited, iterative deepening, bidirectional
- Informed search: greedy best-first, A*, hill climbing, simulated annealing
- Game playing; adversarial search; minimax; alpha-beta pruning

### 9.3 Knowledge representation (ACtE0903)
- Knowledge representations and mappings; approaches; issues
- Semantic nets; frames
- Propositional logic: syntax, semantics, connectives, tautology, validity, well-formed formulas, inference using resolution
- Predicate logic: FOPL, syntax, semantics, quantification, rules of inference, unification, resolution refutation
- Bayes' rule and its use; Bayesian networks; reasoning in belief networks

### 9.4 Expert systems and natural language processing (ACtE0904)
- Expert systems; architecture of an expert system; knowledge acquisition
- Declarative vs procedural knowledge; development of expert systems
- NLP terminology; natural language understanding and generation; steps of NLP; applications; challenges
- Machine vision concepts and stages
- Robotics

### 9.5 Machine learning (ACtE0905)
- Introduction to machine learning; concepts of learning
- Supervised, unsupervised and reinforcement learning
- Inductive learning (decision trees)
- Statistical learning (naive Bayes model)
- Fuzzy learning; fuzzy inference systems; fuzzy inference methods
- Genetic algorithms: operators, encoding, selection algorithms, fitness function, parameters

### 9.6 Neural networks (ACtE0906)
- Biological vs artificial neural networks
- McCulloch–Pitts neuron; mathematical model of an ANN
- Activation functions; architectures of neural networks
- The perceptron; the learning rate; gradient descent; the delta rule
- Hebbian learning; Adaline network
- Multilayer perceptron; backpropagation algorithm
- Hopfield neural network

---

## 10. Project Planning, Design and Implementation (AALL10) — **no app chapter yet**

### 10.1 Engineering drawings and concepts (AALL1001)
- Standard drawing sheets; dimensions; scale
- Line diagrams
- Orthographic projection; isometric projection/view; pictorial views
- Sectional drawings

### 10.2 Engineering economics (AALL1002)
- Project cash flow
- Discount rate, interest and time value of money
- Basic methodologies: discounted payback period, NPV, IRR, MARR
- Comparison of alternatives
- Depreciation system and taxation system in Nepal

### 10.3 Project planning and scheduling (AALL1003)
- Project classifications; project life-cycle phases
- Project planning process
- Project scheduling: bar chart, CPM, PERT
- Resource levelling and smoothing
- Monitoring, evaluation and controlling

### 10.4 Project management (AALL1004)
- Information systems
- Project risk analysis and management
- Project financing
- Tender and its process
- Contract management

### 10.5 Engineering professional practice (AALL1005)
- Environment and society
- Professional ethics
- Regulatory environment
- Contemporary issues/problems in engineering
- Occupational health and safety
- Roles and responsibilities of Nepal Engineers Association (NEA)

### 10.6 Engineering regulatory body (AALL1006)
- Nepal Engineering Council (Acts and Regulations)

---

## Coverage notes (Chapter 1 vs the app tree, 2026-09-24)

Syllabus items that were missing from the first Chapter 1 tree and have since been added (decision 2026-09-24):
- 1.4 Small- and large-signal models → `ch1_i46`
- 1.6 Op-amps → `ch1_i65` (keeps the content of the old `ch1_t11`)
- 1.6 Power BJTs and transformer-coupled push-pull stages → `ch1_i66`
- 1.6 Tuned amplifiers → `ch1_i67`

App topics **not in the syllabus** (dropped by the migration): Transformers (`ch1_t7`), Electrical Measurements (`ch1_t8`), Rectifiers & Power Supplies (`ch1_t12`).

Chapter 10 (AALL10) has no chapter in the app yet.
