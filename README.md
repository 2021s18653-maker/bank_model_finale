# Agent-Based Modeling of Bank Queue Management
This project implements an **Agent-Based Model (ABM)** in NetLogo to simulate **bank queue management**.
The model investigates how customers (people) interact with employees (service counters), how queues form and move, and how **positive and negative influences** affect customer flow and service efficiency.
---
## Features
- **Customers (people)** arrive according to a **Poisson distribution** and decide whether to join a queue.
- **Employees (counters)** serve customers while balancing stress and efficiency.
- **Queue dynamics**: people move forward as others are served.
- **Influence effects**:
- Positive influence encourages others to join.
- Negative influence discourages or removes others from the system.
- **Satisfaction & efficiency tracking**:
- Customers lose satisfaction when waiting.
- Employees’ stress increases while serving, lowering efficiency.
- **Plots over time**:
- People leaving due to negative influence.
- Average customer satisfaction.
- Average employee efficiency.
---
## Entities
### People (Customers)
- `patience-threshold`: maximum wait tolerance
- `wait-time`: time spent in queue
- `satisfaction`: happiness level (0–100)
- `being-served?`: whether currently at the counter
- `arrival-delay`: time before entering a queue (Poisson-distributed)
- `ready-to-join?`: whether they want to join a queue
- `service-duration`: time left to complete service
- `queue-index`: which queue they are in
- `moving-to-queue?`: whether moving to a counter
- `position-in-queue`: index in the queue
### Employees (Counters)
- `efficiency`: service quality (100 − stress)
- `stress`: increases when serving, decreases when idle
- `serving?`: whether serving a customer
- `service-timer`: countdown for service duration
---
## How the Model Works
1. **Setup**:
- Creates a fixed number of employees positioned at counters.
- Spawns an initial population of people in a "population area".
- Initializes global tracking variables and queues.
2. **Arrival**:
- People wait according to a **Poisson arrival delay** before attempting to join a queue.
- Customers choose the **shortest available queue** (max 6 per queue).
3. **Queueing**:
- Customers move toward their target employee’s queue.
- The first in line gets served; others wait behind.
4. **Service & Influence**:
- Served customers may exert **positive or negative influence** on others:
- Positive → encourage joining the system.
- Negative → discourage or cause others to leave.
- People leaving are tracked over time.
5. **Satisfaction & Efficiency**:
- Waiting reduces customer satisfaction.
- Successful service increases satisfaction.
- Employee stress grows while serving, reducing efficiency.
---
## Outputs (Plots)
- **People Left**: number of people leaving the system due to negative influence.
- **Average Satisfaction**: mean satisfaction across all customers.
- **Average Efficiency**: mean efficiency across all employees.
---
## Running the Model
1. Open the `.nlogo` file in **NetLogo** (version 6.x recommended).
2. Click **Setup** to initialize the world.
3. Click **Go** to run the simulation.
4. Observe queues forming, service happening, and plots updating.
---
## Parameters to Experiment With
- `num-employees`: number of service counters.
- `lambda`: Poisson arrival rate (affects how frequently customers join).
- Queue capacity (currently max 6 per queue).
- Service duration randomness.
- Influence type distribution (positive vs negative).
---
## Applications
- Studying **customer flow** in banks and service centers.
- Testing **queue management policies**.
- Exploring **human influence dynamics** in waiting systems.
- Evaluating trade-offs between **customer satisfaction** and **employee stress**.
---
## Authors
- Developed as part of **Agent-Based Modeling coursework**.
- Focus: *Optimizing Customer Flow and Service Efficiency in Banking Systems*.
