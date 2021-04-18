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
    8. *alias* \[name] \[word] - string substitution that creates a shorthand for a corresponding comand or action that is then stored for later use.
    9. *unalias* \[name] - removes alias substitution from storage, preventing from future use.
    10. *alias* - prints all aliases in storage.
    11. *bye*

    #### Other Commands
    - cmd \[arg]\* \[|cmd \[arg]\*]\* \[< fn1] \[ >[>] fn2 ] \[ 2>fn3 || 2>&1 ] \[&]

    #### Aliases
    #### Environment Variable Expansion ${variable}
    #### Wildcard Matching
    
Anthony Monteagudo fleshed out the alias functionality to handle unalias name, alias, alias name word, and alias error handling including loop prevention through recursion. Anthony was also responsible for PATH implementation, including PATH's special conventions such as the interpretations of paths as colon-seperated words that are then stored as tokens for easy accessibility such as being parsed to access nonbuiltin commands, and other such functionality. Anthony contributed to specific PATH handling to setenv commands. Furthermore tilde expansion such as the expansion that occurs at the beginning of each path word was handled by Anthony. Lastly, Anthony handled many of the special conventions regarding directories such as the aforementioned tilde, but also including cwd.
