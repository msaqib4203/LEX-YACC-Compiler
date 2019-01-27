%token ID NUM IF WHILE ELSE SWITCH CASE BREAK DEFAULT FOR DO
%right '='
%left '+' '-'
%left '*' '/'
%%
S : IF '(' C ')' { ifcondition(); } '{' E '}' { ifstatements(); } ELSE '{' E '}'{ elsestatements(); }
  | WHILE { startWhile(); } '(' C ')' '{'{markStart();} E { endWhile();}'}' 
  | SWITCH '('SW')' '{'{startSwitch();} CA '}'{markGotoSwitchEnd(); startCheck();  endSwitch();} 
  | FOR '('E1';'{startFor();}EC';'{markPostOp();}E2{endPostOp();}')''{'E'}'{endFor();}
  | DO'{'{startDoWhile();}E'}'WHILE'('C')'{endDoWhile();}';'
;

E1 :E1',' E1
    |A'='{push();}N{genAssignCode();}
    |
    ;

EC: C
    |
    ;  

E2 :E2','E2
    |'+''+'A{genIncCode();}
    |'-''-'A{genDecCode();}
    |A'+''+'{genIncCode();}
    |A'-''-'{genDecCode();}
    |
    ;      

CA : CASE ' ' NUM{enqueue();}':'{markLabel();} E BR CA
   | DEFAULT{setDefault();}E BR CA
   |
   ;

BR: BREAK ';' {markGotoSwitchEnd();}
  |
  ;


E : E E';'
    | E '+'{ push(); } E{ gencode(); }
    | E '-'{ push(); } E{ gencode(); }
    | E '/'{ push(); } E{ gencode(); }
    | E '*'{ push(); } E{ gencode(); }
	| E '>'{ push(); } E{ gencode(); }
  	| E '<'{ push(); } E{ gencode(); }
	| A '='{ push(); } E{ genAssignCode(); }
	| A
    | NUM{ push(); }
    | ;

SW : ID{ set(); };

A : ID{ push(); }
;

N : NUM{ push(); }
;

C: B1 '&''&'{genAndCode();}C
 | B1'|''|'{genOrCode();}C
 | B1 {genBoolCode();}
 ;

B1: F'>'{pushS(">");}F{combine(3);}
  | F'<'{pushS("<");}F{combine(3);}
  | F'<'{pushS("<");}'='{pushS("=");}F{combine(4);} 
  | F'>'{pushS(">");}'='{pushS("=");}F{combine(4);} 
  | F'='{pushS("=");}'='{pushS("=");}F{combine(4);} 
  | F'!'{pushS("!");}'='{pushS("=");}F{combine(4);} 
  ;

F:NUM{push();}
 | ID{push();}
 ;
%%

#include "lex.yy.c"
char stack[1000][10],queue[1000][10];
int stackTop=-1,tempCounter=-1,labelCounter=-1,queueEnd=-1,defaultSet=0;

char temp[10],label[10],buffer[100],switchVar[10];

int main(int argc, char *argv[1]){

 yyin = fopen(argv[1], "r");
 yyparse();
 return 0;

}

void yyerror(char *s) {
fprintf(stderr, "line %d: %s %s\n", yylineno, s,yytext);
}

void push(){
	//printf("%s",yytext);
 	strcpy(stack[++stackTop],yytext);
}

char *itoa(long i, char* s, int dummy_radix) {
    sprintf(s, "%ld", i);
    return s;
}

char* newLabel(){
 ++labelCounter;
    strcpy(temp,"L");
    itoa(labelCounter,buffer,10);
    strcat(temp,buffer);
return temp;

}

void pushS(char *s){
    //printf("push %s\n",yytext);
 	strcpy(stack[++stackTop],s);
}
void combine(int num){

int i;
//printf("stack %s\n",stack[stackTop-2]);
strcpy(temp,stack[stackTop-num+1]);
for(i=2;i<=num;i++){
    strcat(temp,stack[stackTop-num+i]);
}
stackTop=stackTop-num+1;
strcpy(stack[stackTop],temp);
//printf("stack %s\n",stack[stackTop]);

}

void genAndCode(){

      if(labelCounter<2)
        labelCounter=2;

    printf("%s:\n",newLabel());
    printf("if %s goto L%d\n",stack[stackTop],labelCounter+1);
    printf("goto L1\n");
 

}

void genOrCode(){
    if(labelCounter<2)
        labelCounter=2;

    printf("%s:\n",newLabel());
    printf("if %s goto L0\n",stack[stackTop]);
    printf("goto L%d\n",labelCounter+1);

}


void genBoolCode(){
      if(labelCounter<2)
        labelCounter=2;

    printf("%s:\n",newLabel());
    printf("if %s goto L0\n",stack[stackTop]);
    printf("goto L1\n");
}

void genAssignCode(){

printf("%s = %s\n",stack[stackTop-2],stack[stackTop]);
stackTop-=2;

}

void gencode(){
	//printf("genretin");
	strcpy(temp,"t");
	++tempCounter;
	itoa(tempCounter,buffer, 10);
	strcat(temp,buffer);
	printf("%s = %s %s %s\n",temp,stack[stackTop-2],stack[stackTop-1],stack[stackTop]);
	stackTop-=2;
	strcpy(stack[stackTop],temp);	
}
void ifcondition(){

printf("L0:\n");

}

void ifstatements(){

 printf("goto L2\n");
 printf("L1:\n");

}

void elsestatements(){

printf("L2:\n");
}

void startWhile(){

 printf("X:\n");   
}

void endWhile(){
 printf("goto X\nL1:\n");   
}

void markStart(){
    printf("L0:\n");
}

void startSwitch(){
    
    printf("goto CHECK\n");
}

void markLabel(){
   
   printf("%s:\n",newLabel());
}

void markGotoSwitchEnd(){

    printf("goto NEXT\n");

}

void endSwitch(){
     printf("NEXT:\n");

}

void startCheck(){

    int i;
    printf("CHECK:\n");
    for(i=0;i<=queueEnd;i++){
        printf("if %s equals %s goto L%d\n",switchVar,queue[i],i);        
    }
    if(defaultSet)
        printf("goto LD\n");
        
    queueEnd=-1;
    defaultSet=0; 

}

void set(){

strcpy(switchVar,yytext);
}

void enqueue(){

    int i;
    for(i=0;i<=queueEnd;i++){
    if(!strcmp(yytext,queue[i])){
        printf("\nError: Case already set for %s",yytext);
        exit(0);
    }
}
    strcpy(queue[++queueEnd],yytext);

}

void setDefault(){

    if(defaultSet){
        printf("Error: default already set\n");   
        exit(0); 
    }
    else{
        defaultSet=1;
        printf("LD:\n");    
    }
}

void startFor(){
    printf("XF:\n");

}

void endFor(){
    
    printf("goto LP\n");
    printf("L1:\n");
}


void markPostOp(){
    
    printf("goto LB\n");
    printf("LP:\n");
}

void endPostOp(){
    
    printf("goto XF\n");
    printf("L0:\n");
}

void genIncCode(){
    char temp[10];
    strcpy(temp,stack[stackTop]);
  //  printf("temp is %s end",stack[stackTop]);
    strcpy(stack[++stackTop],"=");
    strcpy(stack[++stackTop],stack[stackTop-1]);
    strcpy(stack[++stackTop],"+");
    strcpy(stack[++stackTop],"1");
    gencode();
    genAssignCode();


}

void genDecCode(){
      char temp[10];
    strcpy(temp,stack[stackTop]);
    strcpy(stack[++stackTop],"=");
    strcpy(stack[++stackTop],stack[stackTop-1]);
    strcpy(stack[++stackTop],"-");
    strcpy(stack[++stackTop],"1");
    gencode();
    genAssignCode();
}

void startDoWhile(){
    printf("L0:\n");
    
}


void endDoWhile(){

printf("L1:\n");
}

