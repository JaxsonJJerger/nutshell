# nutshell
## Term Project for OS Spring 2021
* creating a command interpreter for a Korn shell-like command language in C using Lex and Yacc running under Unix
  * consists of simple commands, pipes, I/O redirection, environment vars, aliases, pathname searching, and wild-carding
  * parses command lines and executes appropriate commands
    ### Built-in commands
    1. *setenv* \[variable] \[word] - 
    2. *printenv*
    3. *unsetenv* \[variable]
    4. *HOME*
    5. *PATH*
    6. Specific conventions regarding the PATH environment var
    7. *cd* \[word]
    8. *alias* \[name] \[word]
    9. *unalias* \[name]
    10. *alias*
    11. *bye*

    #### Other Commands
    - cmd \[arg]\* \[|cmd \[arg]\*]\* \[< fn1] \[ >[>] fn2 ] \[ 2>fn3 || 2>&1 ] \[&]

    #### Aliases
    #### Environment Variable Expansion ${variable}
    #### Wildcard Matching
    
