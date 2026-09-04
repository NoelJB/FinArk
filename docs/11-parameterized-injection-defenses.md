# FinArk Lesson: Parameterized Queries & Injection Boundary Defenses

## 🧠 The Core Security Concept (OWASP A03:2021)
SQL Injection is one of the oldest and most destructive vulnerabilities in enterprise software. It occurs whenever a software developer constructs a database query by directly gluing or concatenating user-provided text input strings into an executable SQL string pattern.

If an application accepts input from an input box and joins it directly like this:
"SELECT * FROM advisor WHERE name = '" + user_input + "';"

A malicious user can craft an input containing raw SQL punctuation markers, such as quotes, dashes, and semicolons (e.g., "Alice'; DROP TABLE client; --"). When the relational query parser evaluates this single text block, it treats the string not as a name, but as distinct command code instructions, allowing the attacker to execute destructive database actions or bypass security checks.

---

## 🏗️ The Defensive Architecture: Prepared Statements

To permanently neutralize input injection vulnerabilities, the FinArk Platform mandates a zero-concatenation policy. External microservices must interact with our relational schema using **Prepared Statements** (parameter binding).

Our validation test demonstrates this mechanism directly at the SQL engine tier using a two-step compile process:

1. Structural Lock Down (PREPARE)
The system instructs the database engine optimizer to pre-compile the query blueprint upfront before accepting any user inputs:
PREPARE advisor_secure_lookup (VARCHAR) AS SELECT COUNT(*) FROM advisor WHERE name = $1;

The database engine parses the text commands and locks down the physical query execution tree structure. The variable marker `$1` is established strictly as a placeholder for data values.

2. Execution Isolation (EXECUTE)
When the payload string arrives, it is injected into the variable slot explicitly:
EXECUTE advisor_secure_lookup(''' OR ''1''=''1');

Because the query structure was already pre-compiled and frozen during the PREPARE stage, the relational parser **never reads the input payload string as executable command tokens**. The database engine treats the entire attacking string strictly as a literal text value—looking for an advisor whose literal name is physically composed of quotes and equal signs. 

Since no record matches that string, the boundary wall neutralizes the attack completely, returning zero rows and protecting system records.
