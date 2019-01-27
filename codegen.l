ALPHA [A-Za-z]
DIGIT [0-9]
%%
[\t\n]
if                 return IF;
else                 return ELSE;
while               return WHILE;
switch             return SWITCH;
case               return CASE;
break              return BREAK;
default:            return DEFAULT;
for                 return FOR;
do                  return DO;
{ALPHA}({ALPHA}|{DIGIT})*    return ID;
{DIGIT}+             return NUM;
.                 return yytext[0];
%%
