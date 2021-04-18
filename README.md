
# Term Project for OS Spring 2021

###Contributions

Anthony Monteagudo fleshed out the alias functionality to handle unalias name, alias, alias name word, and alias error handling including loop prevention through recursion. Anthony was also responsible for PATH implementation, including PATH's special conventions such as the interpretations of paths as colon-seperated words that are then stored as tokens for easy accessibility such as being parsed to access nonbuiltin commands, and other such functionality. Anthony contributed to specific PATH handling to setenv commands. Furthermore tilde expansion such as the expansion that occurs at the beginning of each path word was handled by Anthony. Lastly, Anthony handled many of the special conventions regarding directories such as the aforementioned tilde, but also including cwd.

Jaxson Jerger's Contributions:
  - Built-in-Cmds Completed
      setenv/printenv/unsetenv/cd/bye
  - Non-built-in-cmds (No piping, but commands work as they should)
  - I/O Redirection 
      <, >, >>, 2>, 2>&1    (work in specified combination)
  - Attempted piping, does not work, will cause seg fault
  - Environment variable expansions (separate word or withing quotes/strings)
  - Helped make alias expansion infinite-loop detection
      
## The Nutshell
A command interpreter for a Korn shell-like command language in C using Lex and Yacc running under Unix  consisting of simple commands, ~~pipes~~, I/O redirection, environment vars, aliases, pathname searching, and ~~wild-carding~~ , parses command lines and executes appropriate commands

    

## Built-in commands

 
    1. *setenv* \[variable] \[word] - sets an environment variable, usage ${variable}
    2. *printenv* - prints the environment variables,
    3. *unsetenv* \[variable] - removes an enviroment variable, HOME and PATH cannot be removed.
    4. *HOME* - mandatory environment variable set at runtime
    5. *PATH* - mandatory environment variable set at runtime, used to find commands at the respective locations
    6. Specific conventions regarding the PATH environment var - tilde expands at the beginning of each word that is separated by colons
    7. *cd* \[word] - allows the user to change directory absolutely or relatively to the current working directory. No [word] argument is the same as cd ~ 
    8. *alias* \[name] \[word] - string substitution that creates a shorthand for a corresponding comand or action that is then stored for later use.
    9. *unalias* \[name] - removes alias substitution from storage, preventing from future use.
    10. *alias* - prints all aliases in storage.
    11. *bye* - when used alone will exit the shell gracefully

 

## Other Commands

    - cmd \[arg]\* \[|cmd \[arg]\*]\* \[< fn1] \[ >[>] fn2 ] \[ 2>fn3 || 2>&1 ] \[&]
      Implemented: I/O redirection works for all built-in commands as well as the non-built-in commands 'alias' and 'printenv'. Redirections can be used in combination with one another except those with exclusive or must be one or the other

        \<      accept input from file

        \>      truncate to zero and write
        XOR
        \>\>     append to file
        
        2\>     stderr to file "filename"
        XOR
        2\>\&1   redirects stderr to stdout
        
      Not Implemented: Piping commands

### Aliases

### Environment Variable Expansion ${variable}

      - The shell will expand environment variables within ${}, no whitespace between, to their matching word/value, including while within quotations.

### Wildcard Matching
	- not implemented
### Tilde Expansion
      - Expansion at the beginning of paths in which tilde is replaced with the home directory is implemented.
   
