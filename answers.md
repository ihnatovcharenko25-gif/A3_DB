1. What is the difference between a function and a procedure in PostgreSQL?
   You can commit/rollback procedures, but not functions; functions must return values (procedures may)
2. Can a trigger be executed manually? Why or why not?
   No, it runs only when event described in its declaration happens, also it needs to "know" OLD and NEW data/state, so it should be linked to a event(change of data)
3. What are the advantages and disadvantages of storing business logic inside the database?
   +: integrity - all logic and operation in one place;
   -: makes it harder to scale, debug, check and change
