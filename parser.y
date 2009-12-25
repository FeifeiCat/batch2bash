/*
 * Parser part for batch to bash translator
*/

%{

#include <stdio.h>
#include "defs.h"
#include <unistd.h>
#include "semantic.h"
#include <stack>


int yyparse(void);
int yylex(void);
int yyerror(char *s);    
void print_symbol(const char *string);
std::stack<command*> parents;
program progrm;
extern int line;
extern int debug;
extern int error;

%}

%error-verbose
%expect 1

/* keyword tokens */

%token ECHO 
%token REM
%token LABEL
%token PARAMETER
%token CALL
%token CHOICE
%token CONSOLE 
%token ELSE
%token ERRORLEVEL
%token EXIST
%token IF
%token FOR 
%token IN
%token DO
%token GOTO
%token NOT
%token NUL
%token OFF
%token ON
%token PAUSE
%token SET
%token SHIFT
%token SIGN
%token RELOP
%token REDIRECT
%token STROP
%token PIPE
%token NOECHO
%token WILDCARD
%token PERCENT
%token LPAREN
%token RPAREN
%token DOT
%token ASSIGN_OP
%token PATH_LINE

/* ms-dos command tokens */
%token ASSIGN
%token ATTRIB
%token CD
%token CLS
%token COMP
%token COPY
%token DEL
%token DELTR
%token DIR
%token EXIT
%token FC
%token FIND 
%token DATE
%token MKDIR
%token MORE
%token MOVE 
%token PATH
%token REN
%token RD
%token RMDIR
%token SORT 
%token TIME 
%token TYPE 
%token XCOPY

/* other tokens  */

%token BACKSLASH
%token COLON
%token NUMBER
%token NEWLINE
%token ID
%token SLASH
%token STRING
%token DRIVE_ROOT

%%

program : NEWLINE command_list
        | command_list NEWLINE
        | NEWLINE command_list NEWLINE
        | command_list
        ;

command_list : command {
                   parents.top()->add_child((command*)($1));
                   $$ = $1;
               }
             | redir_command {
                   parents.top()->add_child((command*)($1));
                   $$ = $1;
               }
             | command_list NEWLINE command {
                   parents.top()->add_child((command*)($3));
                   $$ = long(parents.top());
               }
	         | command_list NEWLINE redir_command {
                   parents.top()->add_child((command*)($3));
                   $$ = long(parents.top());
               }
             ;

command : normal_command { $$ = $1; }
        | silent_command { $$ = $1; }
        ;

silent_command : NOECHO normal_command { $$ = $2; }
               ;

normal_command : compound_command { $$ = $1; }
               | echo_command { $$ = $1; }
               | rem_command { $$ = $1; }
               | choice_command { $$ = $1; }
               | if_command { $$ = $1; }
               | for_command { $$ = $1; }
               | goto_command { $$ = $1; }
               | cls_command { $$ = $1; }
               | shift_command { $$ = $1; }
               | label { $$ = $1; }
               | del_command { $$ = $1; }
               | call_command { $$ = $1; }
               | set_command { $$ = $1; }
               | cd_command { $$ = $1; }
               | pause_command { $$ = $1; }
               | dir_command { $$ = $1; }
               | exit_command { $$ = $1; }
               | find_command { $$ = $1; }
               | mkdir_command { $$ = $1; }
               | more_command { $$ = $1; }
               | drive_command { $$ = $1; }
               | fc_command { $$ = $1; }
               | date_command { $$ = $1; }
               | time_command { $$ = $1; }
               ;


redir_command : command REDIRECT path {
	                print_symbol("redirect command");
	            }
	          ;

newline_list : command_list { $$ = $1; }
             | NEWLINE command_list { $$ = $2; }
             | command_list NEWLINE { $$ = $1; }
             | NEWLINE command_list NEWLINE { $$ = $2; }
             ;

compound_command : LPAREN {
                       $$ = long(new command("compound", line));
                       parents.push((command*)($$));
                   }
                   newline_list RPAREN {  
                       print_symbol("compound_command"); 
                       parents.pop();
                       $$ = $2;
                   }
                 ;

echo_command : ECHO {
                   print_symbol("echo_command"); 
                   $$ = long(new command("echo", line));
               }
             ;
pause_command : PAUSE {
                    print_symbol("pause_command"); 
                    $$ = long(new command("pause", line));
                }
              ;
    
rem_command : REM {
                  print_symbol("rem_command");      
                  $$ = long(new command("rem", line));
              }
            ;

del_command : DEL path {
                  print_symbol("del_command");
                  $$ = long(new command("del", line));
              }
            | DEL parameter_list  path {
                   print_symbol("del_commandi parameter_list");
                   $$ = long(new command("del", line));
              }
            ;
dir_command : DIR {
                  print_symbol("dir_command");
                  $$ = long(new command("dir", line));
              }
            | DIR parameter_list {
                  print_symbol("dir_command paramter_list");
                  $$ = long(new command("dir", line));
              }
            | DIR path {
                  print_symbol("dir_command path");
                  $$ = long(new command("dir", line));
              }
            | DIR parameter_list path {
                  print_symbol("dir_command parameter_list path");
                  $$ = long(new command("dir", line));
              }
            ;
            
exit_command : EXIT {
                  print_symbol("exit_command");
                  $$ = long(new command("exit", line));
               }
             ;
     
find_command : FIND string path {
                   print_symbol("find_command path");
                   $$ = long(new command("find", line));
               }
             | FIND parameter_list string path {
                   print_symbol("find_command parameter_list path");
                   $$ = long(new command("find", line));
               }
             ;
             
mkdir_command : MKDIR path {
                   print_symbol("mkdir_command path");
                   $$ = long(new command("mkdir", line));
                }
              ; 
             
more_command : MORE filename {
                   print_symbol("more_command filename");
                   $$ = long(new command("more", line));
               }
             | MORE parameter_list filename {
                   print_symbol("more_command parameter_list filename");
                   $$ = long(new command("more", line));
               }
             ;
//choice [/c [<Choice1><Choice2><…>]] [/n] [/cs] [/t <Timeout> /d <Choice>] [/m <"Text">]
// reference http://technet.microsoft.com/en-us/library/cc732504%28WS.10%29.aspx 

choice_command : CHOICE {/*default Y/N choice */
                     print_symbol("choce_command");
                     $$ = long(new command("choice", line));
                 }
               | CHOICE parameter_list {
                     print_symbol("choce_command parameter_list");
                     $$ = long(new command("choice", line));
                 }
               ;
                
for_command : FOR PERCENT variable IN LPAREN command RPAREN DO command {
                  print_symbol("for_command");
                  $$ = long(new command("for", line));
              }
            ;

if_command : if_part ELSE {
                 $$ = long(new command("else", line));
                 parents.push((command*)($$));
             } command {
                 print_symbol("if_command + else");
                 command* else_comm = (command *)($3);
                 else_comm->add_child((command*)($4));
                 parents.pop();
                 command* if_else = new command("if_else", line); //group if and else under one command
                 if_else->add_child((command*)($1));
                 if_else->add_child(else_comm);
                 $$ = long(if_else); 
             }
           | if_part {
                 print_symbol("if_command");
                 $$ = $1;
             }
           ;

if_part : IF NOT if_body {
              $$ = long(new command("if", line));
              parents.push((command*)($$));
          } command {
              print_symbol("if_part");
              command* if_comm = (command *)($4);
              if_comm->add_child((command*)($5));
              parents.pop();
              $$ = long(if_comm);
          }
        | IF if_body {
              $$ = long(new command("if", line));
              parents.push((command*)($$));
          } command {
              print_symbol("if_part");
              command* if_comm = (command *)($3);
              if_comm->add_child((command*)($4));
              parents.pop();
              $$ = long(if_comm);
          }
        ;

if_body : ERRORLEVEL NUMBER
        | string STROP string 
        | EXIST filename  
        ;

goto_command : GOTO variable {
                   print_symbol("goto_command");
                   $$ = long(new command("goto", line));
               }
             | GOTO ID {
                   print_symbol("goto_command");
                   $$ = long(new command("goto", line));
               }
             ;

cls_command : CLS {
                  print_symbol("cls_command");
                  $$ = long(new command("cls", line));
              }
            ;

shift_command : SHIFT {
                    print_symbol("shift_command");
                    $$ = long(new command("shift", line));
                }
              | SHIFT PARAMETER {
                    print_symbol("shift_command");
                    $$ = long(new command("shift", line));
                }
              ;
call_command : CALL path {
                   print_symbol("call_command path");
                   $$ = long(new command("call", line));
               }
             ;
        
set_command : SET {
                  print_symbol("set_command");
                  $$ = long(new command("set", line));
              }
            | SET parameter_list {
                  print_symbol("set_command parameter_list");
                  $$ = long(new command("set", line));
              }
            | SET ID ASSIGN_OP string {
                  print_symbol("set_command id = string");
                  $$ = long(new command("set", line));
              }
            | SET parameter_list ID ASSIGN_OP string{
                  print_symbol("set_command parameter_list id = string");
                  $$ = long(new command("set", line));
              }
            ;

cd_command : CD {
                 print_symbol("cd_command path");
                 $$ = long(new command("cd", line));
             }
           | CD path {
                 print_symbol("cd_command path");
                 $$ = long(new command("cd", line));
             }
    	   | CD DRIVE_ROOT BACKSLASH { //exception , doesn't do anything 
                 print_symbol("cd_command drive_root\\");
                 $$ = long(new command("cd", line));
             }
           | CD DRIVE_ROOT {
                 print_symbol("cd_command drive_root");
                 $$ = long(new command("cd", line));
             }
           ;

fc_command : FC path path {
                 print_symbol("fc path path");
                 $$ = long(new command("fc", line));
    	     } 
	       | FC parameter_list path path {
	   	         print_symbol("fc parameter_list path path");
                 $$ = long(new command("fc", line));
    	     }
	       ;

date_command : DATE {
	               print_symbol("date_command");
                   $$ = long(new command("date", line));
    	       }
	         | DATE parameter_list {
		           print_symbol("date_command parameters");
                   $$ = long(new command("date", line));
               }
	         ; 
    
time_command : TIME {
		           print_symbol("time_command");
                   $$ = long(new command("time", line));
    	       }
	         | TIME parameter_list {
		           print_symbol("time_command parameters");
                   $$ = long(new command("time", line));
    	       }
	         ;

drive_command : DRIVE_ROOT {
                    print_symbol("drive_command");
                    $$ = long(new command("drive", line));
                }
              ;
               
label : COLON ID {
            print_symbol("label");
            $$ = long(new command("label", line));
        }
      ;

variable : PERCENT ID PERCENT
         ;

parameter_list : PARAMETER
               | parameter_list PARAMETER
               ; 
               
filename : ID 
         | ID DOT ID
         ;


path : PATH_LINE
     | DRIVE_ROOT BACKSLASH PATH_LINE
     | DRIVE_ROOT BACKSLASH filename 
     | filename		
     ;   

string : STRING 
       | ID
       ;
	      

%%

int yyerror(char *s) {
    fprintf(stderr, "\nerror: (%d): %s\n", line, s);
    error = 1;
    return 0;
}

int main(int argc, char *argv[]) {
    int opt;
    while ((opt = getopt(argc, argv, "d")) != -1) {
        switch (opt) {
            case 'd':
                debug = 1;
                break;
        }
    }
    command* begin = new command("root", -1);
    parents.push(begin);
    progrm.root = begin;
    yyparse();
    if (debug != 0 && !error) {
        progrm.print_program_tree();
    }
    return error;
}


void print_symbol(const char *string) {
    if (debug) {
        fprintf(stdout, "\t%s %d\n", string,line);
    }
}
