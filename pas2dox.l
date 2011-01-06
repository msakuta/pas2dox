/******************************************************************************
 *
 *
 *
 * Copyright (C) 2002-2006 by Darren Bowles.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation under the terms of the GNU General Public License is hereby
 * granted. No representations are made about the suitability of this software
 * for any purpose. It is provided "as is" without express or implied warranty.
 * See the GNU General Public License for more details.
 *
 * Documents produced by Pas2Dox are derivative works derived from the
 * input used in their production; they are not affected by this license.
 *
 */

%{
#include <string>
#include <list>
#include <algorithm>
#include <ctype.h>
#ifdef _WIN32
# include <io.h>
# include <windows.h>
#endif

using namespace std;

const char* version = "0.50rc1";
const char* date = __DATE__;

FILE* OUTPUT = NULL;

//*****************************************************************************
/// Type of function
enum func_type { NORMAL,       ///< Normal
                 CONSTRUCTOR,  ///< Constructor function
                 DESTRUCTOR,   ///< Destructor function
               };

//*****************************************************************************
/// Type Conversion
struct type_conv
{
    char m_pascal_type[15];
    char m_c_type[15];
};

type_conv type_conversion[] = {
  {"boolean", "bool"},
  {"shortint", "signed char"},
  {"byte","char*"},
  {"smallint","short"},
  {"word","unsigned short"},
  {"integer", "int"},
  {"longint","long"},
  {"single","float"},
  {"double","double"},
  {"self", "this"},
};

//*****************************************************************************
/// Operator Conversion
struct op_conv
{
  char m_pascal_op[4];
  char m_c_op[3];
};

/**
*  \note duplicated operators for bitwise and logical operations.
*
*  biwise operators have a higher precedence, than logical, so
*
*  if x > 0 and x < 10 then...  will use bitwise operators
*  if (x > 0) and (x < 10) then...  will use logical operators
*/
op_conv operator_conversion[] = {
  {".","::"},       ///< Scope Resolution
  {"not","~"},      ///< Bitwise negation
  {"@","&"},        ///< Address
  {"^","*"},        ///< De-Reference
  {"/","/"},        ///< Floating point division
  {"div","/"},      ///< Integer Division
  {"mod","^"},      ///< Modulus
  {"shl","<<"},     ///< Left bitwise shift
  {"shr",">>"},     ///< Right bitwise shift
  {"=", "=="},      ///< Equal to
  {"<>","!="},      ///< Not Equal to
  {"and","&"},      ///< Bitwise AND
  {"or","|"},       ///< Bitwise OR
  {"xor","^"},      ///< Bitwise XOR
  {"not","!"},      ///< Logical NOT
  {"and","&&"},     ///< logical AND
  {"or","||"},      ///< Logical OR
  {":=","="},       ///< Simple Assignment
};

//*****************************************************************************
/// Convert from Pascal type to C++ type
void Convert_Type(string& pText)  ///< Type to be converted
{
  type_conv* p;

  string str = pText;
  std::transform (str.begin(),str.end(), str.begin(), tolower);

  int count = sizeof(type_conversion) / sizeof(type_conv);

  for (int i = 0; i < count; i++)
  {
    p = &type_conversion[i];

    // have we found the pascal type in our table?
    if (str == p->m_pascal_type)
    {
      // convert to c++ type
      pText = p->m_c_type;
    }
  }
}

//*****************************************************************************
/// Remove spaces
void RemoveSpaces(string& pText)  ///< String to work on
{
  int pos = string::npos;

  while(true)
  {
    pos = pText.find(" ", 0);

    if (pos == string::npos)
      break;

    pText.replace(pos, 1, "");
  }
}

//*****************************************************************************
/// Class Information
class class_info
{
  public:
    class_info();
    class_info(string name, string parent, string parent2, string var, string type);

    string sName;        /// Class Name
    string sParent;      /// Parent Class
    string sParent2;     /// Second Parent Class

    string sVar;         /// Class Variable
    string sType;        /// Class Type
};

class_info::class_info()
{
  sName = "";
  sParent = "";
  sParent2 = "";
  sVar = "";
  sType = "";
}

class_info::class_info(string name,    ///< Class Name
                       string parent,  ///< Parent Class
            		       string parent2, ///< Second Parent Class
                       string var,     ///< Class Variable
		                   string type)    ///< Class Type
{
  sName = name;
  sParent = parent;
  sParent2 = parent2;
  sVar = var;
  sType = type;
}

//*****************************************************************************
/// Parameter Information
class param_info
{
  public:
  // Copy constructor
  param_info(const param_info& obj)  { *this = obj; }

  // Assignment operator
  param_info& operator=(const param_info& obj);

  param_info();
  param_info(string type, string name, string comment, string def, bool c, bool v, bool o, bool array);

  string sType;        /// Parameter Name
  string sName;        /// Parameter Type
  string sDefault;     /// Default Value
  string sComment;     /// Associated Comment
  bool bConst;         /// Const Parameter
  bool bVar;           /// Var Parameter
  bool bOut;           /// Out Parameter
  bool bArray;         /// Array Parameter
};

param_info& param_info::operator=(const param_info& obj)
{
  sType = obj.sType;
  sName = obj.sName;
  sDefault = obj.sDefault;
  sComment = obj.sComment;

  bConst = obj.bConst;
  bVar = obj.bVar;
  bOut = obj.bOut;
  bArray = obj.bArray;

  return *this;
}

param_info::param_info()
{
  sType = "";
  sName = "";
  sComment = "";
  bConst = false;
  bVar = false;
  bOut = false;
  bArray = false;
}

param_info::param_info(string type, string name, string comment, string def, bool c, bool v, bool o, bool array)
{
  sType = type;
  sName = name;
  sComment = comment;
  sDefault = def;
  bConst = c;
  bVar = v;
  bOut = o;
  bArray = array;
}

//*****************************************************************************
/// Function Information
class func_info
{
  public:
    func_info();
    func_info(string aclass, string name, string ret, func_type ft);

    string sClass;               ///< Associated Class
    string sName;                ///< Function Name
    string sRet;	               ///< Return Type

    func_type eFuncType;         ///< Function type
};

func_info::func_info()
{
  sClass = "";
  sName = "";
  sRet = "";

  eFuncType = NORMAL;
}

func_info::func_info(string aclass, string name, string ret, func_type ft)
{
  sClass = aclass;
  sName = name;
  sRet = ret;

  eFuncType = ft;
}

//*****************************************************************************
/// Property Information
class prop_info
{
  public:
    prop_info();
    prop_info(string name, string type);

    string sName;                /// Property Name
    string sType;                /// Property Type

    string sRead;                /// Read Value
    string sWrite;               /// Write Value
    string sDefault;             /// Default Value

    bool bRead;                  /// Assign read property
};

prop_info::prop_info()
{
  sName = "";
  sType = "";
}

prop_info::prop_info(string name, string type)
{
  sName = name;
  sType = type;
}

//*****************************************************************************
/// Array / Set Information
class array_info
{
  public:
    array_info();
    array_info(string name, string type, int size, string def);

    string sName;           ///< Array Name
    string sType;           ///< Array Type
    int nSize;              ///< Array Size
    string sDefault;        ///< Default Values
};

array_info::array_info()
{
  sName = "";
  sType = "";
  nSize = 0;
  sDefault = "";
}

array_info::array_info(string name, string type, int size, string def)
{
  sName = name;
  sType = type;
  nSize = size;
  sDefault = def;
}

//*****************************************************************************
func_info* pFunc = NULL;
class_info* pClass = NULL;
prop_info* pProperty = NULL;
array_info* pArray = NULL;

list<param_info> lstParams;        /// List Of Parameters
list<string> g_lstComments;        /// List Of Comments
list<param_info> g_lstParams;      /// List Of Parameters
list<int> g_lstSize;               /// List of Integers for multi dimensional arrays
string g_defaultvalue;
string g_processtype;
list<string> g_lParamType;         /// Parameter Type

unsigned int g_nBegins = 0;

// Sections
bool g_bClassBody = false;	       /// In Class Body
bool g_bFuncBody = false;          /// In Function Body
bool g_bType = false;              /// In Type Section
bool g_bImplementation = false;    /// In Implementation Section
bool g_bIgnoreTypeSection = false; /// Ignoring type section
bool g_bConstSec = false;          /// In a Const Section
bool g_bParams = false;            /// Parameter List
bool g_bEnum = false;              /// Enumeration
bool g_bCase = false;              /// Case Statement
bool g_bInterface = false;         /// Interface
bool g_bStructure = false;         /// Structure
bool g_bVars = false;              /// Vars
bool g_bSet = false;               /// Sets
bool g_bIgnore = false;            /// Ignore Section

bool g_bFom = false;               /// Property Field Or Method
bool g_bConst = false;             /// Parameter is const
bool g_bVar = false;               /// Var Parameter
bool g_bOut = false;               /// Out Parameter
bool g_bArray = false;             /// Array parameter

string g_strTypedef = "";          /// array or set
string g_strTypedefType = "";          /// array or set type
string g_strTypedefName = "";          /// array or set name
int g_nSize = 0;                   /// Array size

bool g_bComments = false;	         /// In a Comment Section

bool g_bDebugMode = false;         /// In Debug Mode
bool g_bKeepBody = false;          /// Keep function body
bool g_bJavaDoc = false;           /// JavaDoc Commenting
bool g_bAtEnd = false;             /// At end of function parameters
bool g_bInterfaceOnly = false;     /// Process only 'Interface' section
bool g_bConvertBody = false;       /// Convert function body to c++
bool g_bGenerateSa = true;         /// Generate \sa clauses

int g_nCommentCaller = 0;          /// Inteligent returning from comments
int g_nDirectiveCaller = 0;        /// Inteligent returning from preprocessor directives
int g_nGeneralCaller = 0;          /// Intelligent return
bool g_bCallback = false;          /// In function typedef

#define OutputLog(s) { if(g_bDebugMode) fprintf(OUTPUT, "%s\n", s); }
#define OutputLog2(s, t) { if(g_bDebugMode) fprintf(OUTPUT, "%s '%s'\n", s, t); }
#define OutputLogNum(s, num) { if(g_bDebugMode) fprintf(OUTPUT, "%s %d\n", s, num); }

//*****************************************************************************
/// Convert Operator
void Convert_Op(string& pText,   ///< Operator to be converted
                bool logical)    ///< Are we a logical operator?
{
  op_conv* p;

  // Return if we're not operating in function body conversion mode
  if (!g_bConvertBody)
    return;

  string str = pText;
  std::transform (str.begin(),str.end(), str.begin(), tolower);

  int count = sizeof(operator_conversion) / sizeof(op_conv);

  for (int i = 0; i < count; i++)
  {
    p = &operator_conversion[i];

    // have we found a matching operator in our conversion table?
    if (str == p->m_pascal_op)
    {
      //OutputLog2("// original type = ", pText.c_str());
      //OutputLog2("// new type = ", p->m_c_op);
      // convert to a c++ operator
      pText = p->m_c_op;

      if (!logical)
        break;
    }
  }
}

//*****************************************************************************
/// Display enumerations
void DisplayEnum(void)
{
  list<param_info>::iterator i;

  OutputLog("// DisplayEnum");

  for (i = lstParams.begin(); i != lstParams.end(); ++i)
  {
    string comm;

	fprintf(OUTPUT, "%s%s ",
      i->sName.c_str(),
      distance (i, lstParams.end()) == 1 ? "" : ",");

	while (!g_lstComments.empty())
	{
	  comm = g_lstComments.front();

      OutputLog2("//Got = ", comm.c_str());
	  if (comm == "*/")
	  {
	    fprintf(OUTPUT, "%s\n", comm.c_str());
		g_lstComments.pop_front();
	    break;
	  }

	  fprintf(OUTPUT, "%s", comm.c_str());

	  g_lstComments.pop_front();
	}

	fprintf(OUTPUT, "\n");

  }
}

//*****************************************************************************
/// Remove Parameters From List
void RemoveParams()
{
  OutputLog("// clearing parameters");

  g_lstParams.clear();
  lstParams.clear();
}

//*****************************************************************************
/// Process Parameter Types
void ProcessParameterType(const char* pText)
{
  list<param_info>::iterator i;

  // Loop through the parameters from the last type position
  for (i = lstParams.begin(); i != lstParams.end(); i++)
  {
    // and assign this type to those new parameters
    i->sType = pText;
     param_info p(pText, i->sName, i->sComment, g_defaultvalue, i->bConst, i->bVar, i->bOut, i->bArray);
    g_lstParams.push_back(p);
  }

  g_defaultvalue = "";
  g_processtype = "";

  OutputLog("// Parameters cleared");
  lstParams.clear();
}

//*****************************************************************************
/// Process Comments
void ProcessComment(void)
{
  // If we're not processing parameters at the moment
  // Then just output the text
  if (g_bParams == false)
  {
    OutputLog("// PC1");
    fprintf(OUTPUT, "%s", yytext);
  }
  else
  {
    OutputLog2("// pushing onto comment stack ", yytext);

    g_lstComments.push_back(yytext);
  }
}

//*****************************************************************************
/// Process end;
void ProcessEnd(void)
{
  OutputLog("// processing end\n");

  if (g_bCase)
  {
    fprintf(OUTPUT, "end;\n");
    g_bCase = false;
  }
  else
  {
    fprintf(OUTPUT, "};\n");
  }

  // Tidy up if we're ending a class
  if (pClass)
  {
//    delete pClass;
    pClass = NULL;
    g_bClassBody = false;
  }
}

//*****************************************************************************
/// Output Inherited Class Details
void OutputInheritedClass(int ntype)
{
  OutputLogNum("// Inherited Class, type = ", ntype);
  if (g_bInterface)
  {
  	// Treat interface like a class
    fprintf(OUTPUT, "class ");
    g_bInterface = false;
  }
  else
  {
    fprintf(OUTPUT, "class ");
  }

  if (pClass->sParent != "")
  {
    fprintf(OUTPUT, "%s : public %s", pClass->sName.c_str(), pClass->sParent.c_str());
  }
  else
  {
    fprintf(OUTPUT, "%s", pClass->sName.c_str());
  }

  if (pClass->sParent2 != "")
  {
    fprintf(OUTPUT, ",%s", pClass->sParent2.c_str());
  }

  if (ntype == 0)
  {
    fprintf(OUTPUT, "\n{\n");

    // All members default to public
   	fprintf(OUTPUT, "public:\n");

    g_bClassBody = true;
  }
  else
  {
    fprintf(OUTPUT, ";\n");
  }
}

//*****************************************************************************
/// Process Enumerations
void ProcessEnums(void)
{
  fprintf(OUTPUT, "enum %s\n{\n", pClass->sName.c_str());
  g_bParams = true;

  if (pClass)
  {
    delete pClass;
    pClass = NULL;
  }

  g_bEnum = true;
}

//*****************************************************************************
/// Process Array
void ProcessArrays(void)
{
  fprintf(OUTPUT, "%s %s[%d] = { \n", pArray->sType.c_str(), pArray->sName.c_str(),
    g_nSize);

  g_bParams = true;

  if (pArray)
  {
    delete pArray;
    pClass = NULL;
  }

  g_bEnum = true;
}

//*****************************************************************************
void ProcessFunction(func_type ft)
{
  // Process function or procedure

  if (pFunc)
    delete pFunc;

  pFunc = new func_info;
  pFunc->sRet = "";

  pFunc->eFuncType = ft;
}

//*****************************************************************************
// Display function params
void DisplayParams(void)
{
  list<param_info>::iterator i;

  // Loop through parameter list
  for (i = g_lstParams.begin(); i != g_lstParams.end(); i++)
  {
    string comm;

    if(!g_lstComments.empty())
    {
      comm = g_lstComments.front();
      OutputLog2("// Got comment : ", comm.c_str());
    }

    fprintf(OUTPUT, "%s%s%s %s%s%s%s%s %s%s\n",
        i->bConst ? "const " : "",
        i->bOut   ? "/* out */ " : "",
        i->sType.c_str(),
        i->bVar   ? "&" : "",
        i->bArray ? "*" : "",
        i->sName.c_str(),
        i->sDefault != "" ? " = " : "",
        i->sDefault.c_str(),
        distance (i, g_lstParams.end()) == 1 ? "" : ",",
        comm.c_str()
        );

    if (!g_lstComments.empty())
    {
      g_lstComments.pop_front();
    }
  }

  RemoveParams();
}

//*****************************************************************************
// Display Variables
void DisplayVariables(void)
{
  list<param_info>::iterator i;

  // Loop through parameter list
  for (i = g_lstParams.begin(); i != g_lstParams.end(); i++)
  {
    string comm;

/*
    if(!g_lstComments.empty())
    {
      comm = g_lstComments.front();
    }
	*/

    if (g_bConvertBody)
    {
      Convert_Type(i->sType);
    }

/*
    fprintf(OUTPUT, "%s %s %s;%s\n",
        g_bConstSec ? "const" : "",
        i->sType.c_str(),
        i->sName.c_str(),
        comm.c_str()
        );
		*/

OutputLog2("val = ", i->sDefault.c_str());
    if (i->sDefault != "")
	{
	  
      fprintf(OUTPUT, "%s %s %s = %s; ",
        g_bConstSec ? "const" : "",
        i->sType.c_str(),
        i->sName.c_str(),
		i->sDefault.c_str()
        );

	}
	else
	{
      fprintf(OUTPUT, "%s %s %s; ",
          g_bConstSec ? "const" : "",
          i->sType.c_str(),
          i->sName.c_str()
          );
	}

  	while (!g_lstComments.empty())
	{
	  comm = g_lstComments.front();

	  if (comm == "*/")
	  {
	    fprintf(OUTPUT, "%s\n", comm.c_str());
		g_lstComments.pop_front();
	    break;
	  }

	  fprintf(OUTPUT, "%s", comm.c_str());

	  g_lstComments.pop_front();
	}

	fprintf(OUTPUT, "\n");
  }

  RemoveParams();
}

//*****************************************************************************
/// Change between Delphi and C++ strings
void ChangeStrings(void)
{
  for (int i = 0; i < yyleng; ++i)
  {
    if (yytext[i] == '\'')
    {
      // check for double ''
      if (yytext[i+1] == '\'')
      {
        yytext[i] = '\\';
        ++i;  // safe because of trailing '\0'
      }
      else
      {
        yytext[i] = '\"';
      }
    }
    else
    {
      if (yytext[i] == '\"')
        yytext[i] = '\'';
    }
  }
}

//*****************************************************************************
void PushText(const char* txt);
%}

%{
/// Translate incoming text from Shift-JIS (CP932) to UTF-8.
#define YY_INPUT(buf,result,max_size) \
	 { \
	int c = getc(yyin); \
	if(0x81 <= c && c <= 0x9f || 0xE0 <= c && c <= 0xff){\
		char cs[3];\
		cs[0] = c;\
		cs[1] = getc(yyin);\
		cs[2] = '\0';\
		wchar_t wcs[3] = L"";\
		MultiByteToWideChar(932, MB_PRECOMPOSED, cs, 2, wcs, sizeof wcs);\
		result = WideCharToMultiByte(CP_UTF8, 0, wcs, 1, buf, max_size, NULL, NULL);\
	}\
	else\
	 result = (c == EOF) ? YY_NULL : (buf[0] = c, 1); \
	 }
%}


ID      [a-z_A-Z][a-z_A-Z0-9]*
NUM     [0-9]*
S       [ \t\n\r]
KEYWORD ("abstract"|"cdecl"|"register"|"dynamic"|"virtual"|"export"|"external"|"far"|"forward"|"override"|"overload"|"pascal"|"reintroduce"|"safecall"|"stdcall")
OPER    ("."|"not"|"@"|"^"|"/"|"div"|"mod"|"shl"|"shr"|"="|"<>"|"and"|"xor"|"or"|":=")

%x PROGRAM
%x function
%x func_params
%x DefaultVal
%x param_type
%x func_ret
%x comments
%x ccomments
%x mytype
%x myparent
%x myparent2
%x myparent3
%x callback
%x directive
%x directive_define
%x directive_ifdef
%x directive_ifndef

%x Body
%x Func_Body
%x InClass
%x ClassVar
%x ClassPtrVar
%x vars
%x Uses
%x Struct
%x Property
%x prop_type
%x Constants
%x   ConstAssign1
%x   ConstAssign2
%x   ConstAssign3
%x Constant2
%x Constant3
%x Enum
%x Array
%x Initialisation
%x ProcessVariable
%x   ProcessVariableType
%x   ProcessVariableType2
%x   ProcessVariableType3
%x ProcessArray
%x   ProcessArraySize
%x   ProcessArrayType
%x ProcessSet
%x   ProcessSetType1
%x   ProcessSetType2
%x ProcessEnum
%x   ProcessEnum1

%x IfThen
%x ForLoop

%%

<*>\x0d
<*>^("program"|"unit") {
  OutputLog("// We've got a program or unit");
  BEGIN (PROGRAM);
}

<*>"{$" {
  OutputLog("// Got a compiler directive");

  if (YY_START != directive)
  	g_nDirectiveCaller = YY_START;
  BEGIN(directive);
}

<*>{KEYWORD} {

  OutputLog2("// got keyword ", yytext);

  if(g_bComments || YY_START == function)
  {
    fprintf(OUTPUT, "%s", yytext);
  }
}

<directive>"}" {
  OutputLog("// Finished Directive");

  BEGIN(g_nDirectiveCaller);
  g_nDirectiveCaller = 0;
}

<directive>"define" {
  OutputLog("// Got a define");
  BEGIN(directive_define);
}

<directive>"else" {
  OutputLog("// Got Else");
  fprintf(OUTPUT, "#else\n");
  BEGIN(directive);
}

<directive>"endif" {
  OutputLog("// Got EndIf");
  fprintf(OUTPUT, "#endif\n");
  BEGIN(directive);
}

<directive>"IfDef" {
  OutputLog("// Got IfDef");
  fprintf(OUTPUT, "#ifdef ");
  BEGIN(directive_ifdef);
}

<directive>"IfNDef" {
  OutputLog("// Got IfNDef");
  fprintf(OUTPUT, "#ifndef ");
  BEGIN(directive_ifndef);
}

<directive>[^}] {
}

<directive_define>{ID} {
  fprintf(OUTPUT, "#define %s\n", yytext);
  BEGIN(directive);
}

<directive_ifdef>{ID} {
  fprintf(OUTPUT, "%s\n", yytext);
  BEGIN(directive);
}

<directive_ifndef>{ID} {
  fprintf(OUTPUT, "%s\n", yytext);
  BEGIN(directive);
}

<PROGRAM>[ \t\n]{ID}; {
  // Get the program name
  BEGIN(Body);
}

<comments>[^}\n]* {
  OutputLog("processing comments");
  ProcessComment();
}

<*>"//"[^\n]* {
  ProcessComment();
}

<Body>{S}{ID}{S}":=" {
  fprintf(OUTPUT, "%s", yytext);
}

<Body>interface {
  OutputLog("// got interface");
}

<Body>uses {
  OutputLog("// processing a uses section");

  g_bType = false;
  BEGIN(Uses);
} // Uses Section

<InClass,Struct,Constants,Body,Func_Body>{S}+end{S}+[^;]*";" {
  OutputLog("// Processing end with comments");
  string str = yytext;

  int i = str.find("end", 0);
  int s = str.find(";");
  if (i != string::npos)
    str.replace(i, 4, "end;" );

  if (s != string::npos)
    str.replace(s, 1, " ");

  PushText(str.c_str());
}

<InClass,Struct,Constants,Body>(^end;|{S}end;|{S}end{S};) {
  OutputLog("// Got end in InClass,Struct or Constants");
  OutputLog2("//", yytext);

  if (!g_bComments)
  {
    OutputLog("// Not a comment");
    if (g_bFuncBody)
    {
      OutputLog("// In function body");
      if (g_nBegins > 0)
        g_nBegins--;

      ProcessEnd();
      g_bStructure = false;

      if (g_nBegins > 0)
        BEGIN(Func_Body);
      else
        BEGIN(mytype);
    }
    else
    {
      OutputLog("// investigate this... we haven't decremented counter");
      ProcessEnd();
      g_bStructure = false;
      BEGIN(mytype);
    }
  }
}

<Body,Constants>^{S}*type {
  if (g_bImplementation)
  {
    OutputLog("// Ignore type Section");

    fprintf(OUTPUT, "#ifdef INCLUDE_TYPE_SECTION\n");
    g_bIgnoreTypeSection = true;

    g_bType = true;
    g_bConstSec = false;
    BEGIN(mytype);
/*
// removed this to investigate other ways of handling type section
    g_bVars = true;
    fprintf(OUTPUT, "\n/*\r\n//type\n");
    g_bComments = true;
    g_bIgnore = true;
    BEGIN(vars);
*/
  }
  else
  {
    OutputLog("// Not Ignoring type Section");

    g_bType = true;
    g_bConstSec = false;
    BEGIN(mytype);
  }
}

<Body,Constants>^(const|resourcestring) {
  if (g_bImplementation)
  {
    OutputLog("// Ignore const Section");

    g_bVars = true;
    fprintf(OUTPUT, "/*\n//const\n");
    g_bComments = true;
    g_bIgnore = true;
    BEGIN(vars);
  }
  else
  {
    OutputLog("// Not Ignoring const Section");

    g_bType = false;
    g_bClassBody = false;
    g_bConstSec = true;
    BEGIN(Constants);
  }
}

<Body>^var|{S}*var {
  if (g_bImplementation)
  {
    OutputLog("// Ignore var Section");

    g_bVars = true;
    fprintf(OUTPUT, "/*\nvar\n");
    g_bComments = true;
    BEGIN(vars);
  }
  else
  {
    OutputLog("// in a type varsection");

    g_bType = false;
    g_bClassBody = false;
    g_bConstSec = true;
    BEGIN(Constants);
  }
}

<vars>begin|asm        {
  OutputLogNum("// Got Begin (vars) - ", g_nBegins);

  if (g_bIgnore)
  {
    OutputLog("// Stop ignoring");
    g_bIgnore = false;
  }

  g_nBegins++;
  g_bVars = false;
  fprintf(OUTPUT, "*/\n{");

  if (!g_bKeepBody)
  {
    fprintf(OUTPUT, "\n#ifndef DOXYGEN_SKIP\n");
  }

  g_bComments = false;
  g_bFuncBody = true;
  BEGIN(Func_Body);
}

<vars>implementation {

  if (g_bInterfaceOnly)
  {
    OutputLog("// End of \'Interface\' section - finish now");
    yyterminate();
  }

  fprintf(OUTPUT, "*/\n");
  OutputLog("// Processing an implementation section (vars)");

  g_bType = false;
  g_bImplementation = true;
  g_bConstSec = false;
  BEGIN(Body);

  // Tidy up if we're ending a class
  if (pClass)
  {
    delete pClass;
    pClass = NULL;
    g_bClassBody = false;
  }
}

<vars>function|procedure|begin {
  if (g_bIgnore)
  {
    OutputLog("// section ignore");
    fprintf(OUTPUT, "*/\n");
  }

  g_bIgnore = false;
  g_bComments = false;
  PushText(yytext);

  g_bType = false;
  g_bConstSec = false;
  g_bImplementation = true;
  g_nBegins = 0;

  ProcessFunction(NORMAL);
  BEGIN(function);
}

<vars>"{*}" {
}

<Func_Body>{S}*"inherited"{S}+ {

  if (g_bConvertBody)
  {
    fprintf(OUTPUT, "\n::");
  }
  else
  {
    fprintf(OUTPUT, "%s", yytext);
  }
}

<Func_Body,IfThen>"<>" {
  if (g_bConvertBody)
  {
    fprintf(OUTPUT, "!=");
  }
  else
  {
    fprintf(OUTPUT, "%s", yytext);
  }
}

<Func_Body,IfThen,Body>")"{S}*{OPER}{S}*"(" {
  string op = yytext;
  Convert_Op(op, true);

  fprintf(OUTPUT, "%s", op.c_str());
}


<Func_Body,IfThen,Body>{OPER} {
  string op = yytext;
  Convert_Op(op, false);

  fprintf(OUTPUT, "%s", op.c_str());
}

<Func_Body>^if|{S}+if{S}+ {
  if (g_bConvertBody)
  {
    OutputLog("// Processing if ");
    PushText(yytext);
    BEGIN(IfThen);
  }
  else
  {
    fprintf(OUTPUT, "%s", yytext);
  }
}

<Func_Body>"for ".*"do" {
  if (g_bConvertBody)
  {
    OutputLog("// Processing for  ");
    PushText(yytext);
    BEGIN(ForLoop);
  }
  else
  {
    fprintf(OUTPUT, "%s", yytext);
  }
}

<ForLoop>"for ".*"do" {

  if (g_bConvertBody)
  {
    string str = yytext;
    string lowstr = str;

    std::transform (lowstr.begin(),lowstr.end(), lowstr.begin(), tolower);

    int forpos = lowstr.find("for", 0);
    int dopos = lowstr.find("do", 0);

    int eqpos;

    eqpos = str.find(":=", 0);
    if (eqpos != string::npos)
    {
      str.replace(eqpos, 2, " =");
    }
    else
    {
      eqpos = str.find('=', 0);
      if (eqpos != string::npos)
      {
        str.replace(eqpos, 2, "==");
      }
    }

    int topos = lowstr.find("to", 0);

    string init = str.substr(forpos + 3, eqpos - (forpos+3));
    string initval = str.substr(eqpos+1, topos - (eqpos+1));
    string opstr = str.substr(topos+2, dopos - (topos+2));

    fprintf(OUTPUT, "for (%s%s; %s < %s;)", init.c_str(), initval.c_str(), init.c_str(),
      opstr.c_str());

  }
  else
  {
    fprintf(OUTPUT, "%s", yytext);
  }

  BEGIN(Func_Body);
}

<Func_Body,IfThen>"self" {
  if (g_bConvertBody)
  {
    fprintf(OUTPUT, "this");
  }
  else
  {
    fprintf(OUTPUT, "%s", yytext);
  }
}

<Func_Body,IfThen>"self." {
  if (g_bConvertBody)
  {
    fprintf(OUTPUT, "this->");
  }
  else
  {
    fprintf(OUTPUT, "%s", yytext);
  }
}

<Func_Body,IfThen>{ID}"."{ID}|{ID}"("{ID}")""."{ID} {
  if (g_bConvertBody)
  {
    string str = yytext;
    int i = str.find('.', 0);
    str.replace(i, 1, "->" );

    i = str.find("self->", 0);
    if (i != string::npos)
      str.replace(i, 4, "this" );

    fprintf(OUTPUT, "%s", str.c_str());
  }
  else
  {
    fprintf(OUTPUT, "%s", yytext);
  }
}

<Func_Body,IfThen>{ID}";" {
  if (g_bConvertBody)
  {
    string str = yytext;
    // todo : should think about keeping a list of variables and either
    // adding () for function calling, or leave alone for variables.
//    int i =  str.find(';', 0);
//    str.replace(i, 3, "();" );
    fprintf(OUTPUT, "%s", str.c_str());
  }
  else
  {
    fprintf(OUTPUT, "%s", yytext);
  }
}

<Func_Body,IfThen>"Owner." {
  if (g_bConvertBody)
  {
    fprintf(OUTPUT, "::");
  }
  else
  {
    fprintf(OUTPUT, "%s", yytext);
  }
}

<Func_Body>{ID}{S}*":"{S}+ {
  if (g_bConvertBody)
  {
    fprintf(OUTPUT, "case %s ", yytext);
  }
  else
  {
    fprintf(OUTPUT, "%s", yytext);
  }
}

<IfThen>if {
  fprintf(OUTPUT, "if (");
}

<IfThen>"then" {
  fprintf(OUTPUT, ") ");
  BEGIN(Func_Body);
}

<Func_Body>"'"[^']+"'"|"''" {
  fprintf(OUTPUT, "%s",yytext);
}

<Func_Body>{S}case{S}[^*\n]+ {
  OutputLogNum("// Got Case - ", g_nBegins);

  if (!g_bComments)
  {
    g_nBegins++;
    g_bCase = true;
  }

  if (g_bConvertBody)
  {
    string str = yytext;
    int i =  str.find("case ", 0);
    str.erase(i, 5);
    i =  str.find(" of", 0);
    str.erase(i,3);

    string str2 = str;
    std::transform (str.begin(),str.end(), str2.begin(), tolower);

    i = str2.find("self", 0);
    if (i != string::npos)
    {
      str = str.replace(i, 4, "this" );
    }

    i =  str2.find(".", 0);
    if (i != string::npos)
    {
      str = str.replace(i, 1, "->" );
    }

    fprintf(OUTPUT, "switch (%s) {", str.c_str());
  }
  else
  {
    if (!g_bComments)
    {
      fprintf(OUTPUT, "%s\n",yytext);
    }
  }
}

<Func_Body>(^try|{S}try){S} {
  OutputLogNum("// Got Try - ", g_nBegins);

  if (!g_bComments)
  {
    OutputLog("// Not a comment");
    g_nBegins++;
    fprintf(OUTPUT, "%s", yytext);
  }
}

<Body,Func_Body>(^begin|{S}*begin|^asm|{S}asm){S} {
  OutputLogNum("// Got Begin (b/fb) - ", g_nBegins);

  if (!g_bComments)
  {
    OutputLog("// Not a comment");
    g_nBegins++;
    if (g_nBegins > 1)
    {
      if (g_bConvertBody)
      {
        fprintf(OUTPUT, "{");
      }
      else
      {
        fprintf(OUTPUT, "begin");
      }
    }
    else
    {
      fprintf(OUTPUT, "{");

      if (!g_bKeepBody)
      {
        fprintf(OUTPUT, "\n#ifndef DOXYGEN_SKIP\n");
      }
    }
  }

  g_bFuncBody = true;
  BEGIN(Func_Body);
}

<Body>"end." {
  fprintf(OUTPUT, "// finished\n");

  if(g_bIgnoreTypeSection)
  {
    fprintf(OUTPUT, "#endif\n");
  }
}

<Func_Body>(end$|{S}end$|end\x0d)      {
  OutputLogNum("// Got End - ", g_nBegins);

  if (!g_bComments)
  {
    OutputLog("// Not a comment");
    g_nBegins--;
    if (g_nBegins > 0)
    {
      if (g_bConvertBody)
      {
        fprintf(OUTPUT, "}");
      }
      else
      {
        fprintf(OUTPUT, "end");
      }
    }
    else
    {
      fprintf(OUTPUT, "}");

      if (!g_bKeepBody)
      {
        fprintf(OUTPUT, "\n*/\n");
        fprintf(OUTPUT, "\n#endif /* DOXYGEN_SKIP */");
      }
    }
  }

  // was just Body
  BEGIN(Func_Body);
}

<Func_Body>(^end;|{S}end;|{S}end{S};|{S}end{S}|end\x3b|end;\x0a) {
  OutputLogNum("// Got End1 - ", g_nBegins);

  if (!g_bComments)
  {
    OutputLog("// Not a comment");
    g_nBegins--;
    if (g_nBegins == 0)
    {
      if (!g_bKeepBody)
      {
        fprintf(OUTPUT, "\n#endif /* DOXYGEN_SKIP */");
      }

      fprintf(OUTPUT, "\n};");
      g_bFuncBody = false;
      BEGIN(Body);
    }
    else
    {
      if (g_bConvertBody)
      {
        fprintf(OUTPUT, "}");
      }
      else
      {
        fprintf(OUTPUT, "end");
      }

      BEGIN(Func_Body);
    }
  }
}

<Body>^finalization {
  fprintf(OUTPUT, "// %s\n", yytext);
}

<Body>^initialization {
  fprintf(OUTPUT, "// %s\n", yytext);
  fprintf(OUTPUT, "\n#ifndef DOXYGEN_SKIP\n");
  BEGIN(Initialisation);
}

<Initialisation>"end." {
  fprintf(OUTPUT, "// finished\n");
  fprintf(OUTPUT, "#endif\n");
  BEGIN(Body);
}

<*>^implementation {

  if (g_bInterfaceOnly)
  {
    OutputLog("// End of \'Interface\' section - finish now");
    yyterminate();
  }

  OutputLog("// Processing an implementation section");

  g_bType = false;
  g_bConstSec = false;
  g_bImplementation = true;
  g_nBegins = 0;
  BEGIN(Body);

  // Tidy up if we're ending a class
  if (pClass)
  {
    delete pClass;
    pClass = NULL;
    g_bClassBody = false;
  }
}

<Constants>^var {
  OutputLog("// in a type varsection");

  g_bType = false;
  g_bClassBody = false;
  g_bConstSec = true;
  BEGIN(Constants);
}

<Constants,mytype,Func_Body,InClass,Struct,myparent>{ID}{S}*":"{S}*"("([^)]*)")"{S}*";" {
  PushText(yytext);
  g_nGeneralCaller = YY_START;
  BEGIN(ProcessEnum);
}

<ProcessEnum>{ID} {
  g_strTypedefName = yytext;
  BEGIN(ProcessEnum1);
}

<ProcessEnum1>":" {} // eat

<ProcessEnum1>{S}*"("([^)]*)")"{S}* {

  ChangeStrings();

  string str = yytext;
  int pos = str.find("(", 0);
  str = str.replace(pos, 1, "{");
  pos = str.find(")", 0);
  str = str.replace(pos, 1, "}");

  g_strTypedefType = str;
}

<ProcessEnum1>";" {
  fprintf(OUTPUT, "enum %s %s;\n", g_strTypedefName.c_str(), g_strTypedefType.c_str());
  BEGIN(g_nGeneralCaller);
}

<Constants,mytype,Func_Body,InClass,Struct,myparent>{ID}{S}*(":"|"="){S}*"array"{S}*"["([^\]])*"]"{S}*"of"{S}*{ID}{S}*("="{S}*"("([^)]*)")"{S}*)*";" {
  OutputLog2("// Processing array = ", yytext);

  PushText(yytext);
  g_nGeneralCaller = YY_START;
  BEGIN(ProcessArray);
}

<Constants,mytype,Func_Body,InClass,Struct,myparent>{ID}{S}*("="|":"){S}*("array"|"set"){S}*"of"{S}*{ID}{S}*";" {
  OutputLog2("// Processing array = ", yytext);

  PushText(yytext);
  g_nGeneralCaller = YY_START;
  BEGIN(ProcessSet);
}

<ProcessSet>{ID} {
  g_strTypedefName = yytext;
  BEGIN(ProcessSetType1);
}

<ProcessSetType1>("="|":") {}

<ProcessSetType1>"set"{S}*"of" {
  g_strTypedef = "set";
  BEGIN(ProcessSetType2);
}

<ProcessSetType1>"array"{S}*"of" {
  g_strTypedef = "array";
  BEGIN(ProcessSetType2);
}

<ProcessSetType2>"("|")"

<ProcessSetType2>{ID} {
  g_strTypedefType = yytext;
}

<ProcessSetType2>";" {
  if (g_bConvertBody)
  {
    Convert_Type(g_strTypedefType);
  }

  fprintf(OUTPUT, "typedef %s<%s> %s;", g_strTypedef.c_str(), g_strTypedefType.c_str(),g_strTypedefName.c_str());
  BEGIN(g_nGeneralCaller);
}

<ProcessArray>{ID} {
  pArray = new array_info(yytext, "", 0, "");
  BEGIN(ProcessArraySize);
}

<ProcessArraySize>(":"|"="){S}*"array"{S}*"[" {} // eat up
<ProcessArraySize>"]" {} // eat up

<ProcessArraySize>"byte" {
  OutputLog("// got byte, so size = 255");
  g_nSize = 255;

  g_lstSize.push_back(g_nSize);
}

<ProcessArraySize>"-"*{NUM} {
  g_nSize = atoi(yytext);

  OutputLogNum("// got size = ", g_nSize);
  g_lstSize.push_back(g_nSize);
}

<ProcessArraySize>{ID} {
  OutputLog2("// Need to decide what to do here...", yytext);
  g_nSize = 999;
  g_lstSize.push_back(g_nSize);
}

<ProcessArraySize>"," {
   OutputLog("// got a multidimensional array");
}

<ProcessArraySize>".." {
  /*g_lstSize.pop_back();*/
}

<ProcessArraySize>"]"{S}*"of" { BEGIN(ProcessArrayType); }

<ProcessArrayType>{ID} {
  OutputLog2("// of type", yytext);

  pArray->sType = yytext;

  if (g_bConvertBody)
  {
    Convert_Type(pArray->sType);
  }
}

<ProcessArrayType>"="{S}*"("([^)]*)")"{S}* {

  ChangeStrings();

  string str = yytext;
  int pos = str.find("(", 0);
  str = str.replace(pos, 1, "{");
  pos = str.find(")", 0);
  str = str.replace(pos, 1, "}");

  pArray->sDefault = str;
}

<ProcessArrayType>";" {

  OutputLog("// Processing array type");
  fprintf(OUTPUT, "%s %s", pArray->sType.c_str(), pArray->sName.c_str());

  list<int>::iterator i;

  string comm;
  char buf[12];
  comm = "/*!< [";
  int c = g_lstSize.size();
  int pos = 0;
  for (i = g_lstSize.begin(); i != g_lstSize.end(); ++i, pos++)
  {
  #ifdef _WIN32
    comm += itoa(*i, buf, 10);
  #else
     snprintf(buf, sizeof(buf), "%d", *i);
     comm += buf;
  #endif

	if (pos+1 < c)
	{
	  comm += "..";
	}
	else
	{
	  comm += "] */";
	}
  }

  if (c > 0)
  {
	fprintf(OUTPUT, "[%d]", g_lstSize.back());
  }

  g_lstSize.clear();

  fprintf(OUTPUT, "%s; %s\n", pArray->sDefault.c_str(), comm.c_str());

  if (pArray)
  {
    delete pArray;
    pArray = NULL;
  }

  BEGIN(g_nGeneralCaller);
}

<Constants>{ID}{S}*(","{S}*{ID}{S}*)+":"{S}*{ID}{S}*";" {
  OutputLog("// got a multiple definition");

  PushText(yytext);
  g_nGeneralCaller = YY_START;
  BEGIN(ProcessVariable);
}

<Constants>{ID}{S}*":"{S}*{ID}{S}*";" {
  OutputLog("// Constants");
  PushText(yytext);
  g_nGeneralCaller = YY_START;
  BEGIN(ProcessVariable);
}

<Constants>{ID}{S}*":"{S}*{ID}{S}*"="{S}*{NUM}";" {
  OutputLog2("// here 1723 ", yytext);
  PushText(yytext);
  g_nGeneralCaller = YY_START;
  BEGIN(ProcessVariable);
}

<Constants>{ID}{S}*"="{S}*('[^'\n]*'|[^;{\n]*)";" {
  OutputLog2("// x = [']y['] = ", yytext);
  PushText(yytext);
  BEGIN(ConstAssign1);
}

<ConstAssign1>{ID} {
  OutputLog2("// got ID = ", yytext);

  if (pClass)
    delete pClass;

  pClass = new class_info;
  pClass->sName = yytext;
  BEGIN(ConstAssign2);
}

<ConstAssign2>"=" {
  OutputLog("// got equals");
  BEGIN(ConstAssign3);
}

<ConstAssign3>('[^'\n]*'|[^;{\n]*)";" {
  OutputLog("// ConstAssign - output");

  ChangeStrings();

  fprintf(OUTPUT, "const %s %s = %s", pClass->sType.c_str(), pClass->sName.c_str(), yytext);

  if (pClass)
  {
    delete pClass;
    pClass = NULL;
  }

  BEGIN(Constants);
}

<mytype>^const|resourcestring {
  OutputLog("// in a type const section");

  g_bType = false;
  g_bClassBody = false;
  g_bConstSec = true;
  BEGIN(Constants);
}

<mytype>^var {
  OutputLog("// in a type varsection");

  g_bType = false;
  g_bClassBody = false;
  g_bConstSec = true;
  BEGIN(Constants);
}

<mytype>{ID}{S}"="{S}"-"*{ID}"("{ID}")"".."{ID}"("{ID}")"";" {
  // TODO : Enum - Similar to arraydef
  fprintf(OUTPUT, "// %s\n", yytext);
}

<mytype>{ID}{S}"="{S}"-"*{ID}*".."{ID}";" {
  // TODO : Enum - Similar to arraydef
  fprintf(OUTPUT, "// %s\n", yytext); }

<mytype,Constants>function|procedure|constructor|destructor          {
  OutputLog2("// type processing :", yytext);

  func_type ft = NORMAL;
  if (strcmp(yytext, "destructor") == 0)
    ft = DESTRUCTOR;

  if (strcmp(yytext, "constructor") == 0)
    ft = CONSTRUCTOR;

  ProcessFunction(ft);
  BEGIN(function);
}

<myparent>"="{S}("procedure"|"function") {

  OutputLog("// function typedef processing");
  g_bCallback = true;
  ProcessFunction(NORMAL);
  BEGIN(callback);
}

<callback>"(" {
  OutputLog("// We've got a parameter list for this function");
  g_bParams = true;
  BEGIN(func_params);
}

<callback>":" {
  BEGIN(func_ret);
}

<callback>";"|"of object;" {
  OutputLog("// function typedef details");
  g_bCallback = false;

  fprintf(OUTPUT, "typedef %s (*%s)(", pFunc->sRet != "" ? pFunc->sRet.c_str() : "void",
    pClass->sName.c_str());

  DisplayParams();

  fprintf(OUTPUT, ");\n");

  if (pFunc)
  {
    delete pFunc;
    pFunc = NULL;
  }

  if (pClass)
  {
    delete pClass;
    pClass = NULL;
  }

  BEGIN(mytype);
}

<myparent>"="{S}"record" {
  OutputLog("// processing a record structure");

  fprintf(OUTPUT, "struct %s\n{\n", pClass->sName.c_str());
  BEGIN(InClass);
  g_bStructure = true;
}

<myparent>"="{S}"packed record" {
  OutputLog("// got a packed record");

  fprintf(OUTPUT, "struct %s\n{\n", pClass->sName.c_str());
  BEGIN(InClass);
  g_bStructure = true;
}

<myparent>"="{S}*"(" {
  ProcessEnums();
  BEGIN(Enum);
}

<Enum>({NUM}"."{NUM}|{NUM}) {
  OutputLog2("// enum num: ", yytext);

  param_info p ("", yytext,  "", "", false, false, false, false);
  lstParams.push_back(p);
}

<Enum>"'"{ID}"'" {
  OutputLog2("// enum 'id': ", yytext);

  param_info p ("", yytext,  "", "", false, false, false, false);
  lstParams.push_back(p);
}

<Enum>{ID} {
  OutputLog2("// enum id: ", yytext);

  param_info p ("", yytext,  "", "", false, false, false, false);
  lstParams.push_back(p);
}

<Enum>{ID}{S}*"="{S}*"-"*{NUM} {
  OutputLog2("// enum here 1: ", yytext);

  string id = yytext;

  int pos = id.find('=', 0);
  string ids = id.substr(0,pos);

  //fprintf(OUTPUT, "int %s", ids.c_str());
    param_info p ("", yytext,  "", ids.c_str(), false, false, false, false);
  lstParams.push_back(p);
}

<Enum>","
<Enum>\n
<Enum>{S}
<Enum>")"  {

  DisplayEnum();
  RemoveParams();

  fprintf(OUTPUT, "};\n");

  g_bEnum = false;
  g_bParams = false;
}

<Enum>";" {

  if (g_bClassBody)
  {
    BEGIN(InClass);
  }
  else if (g_bType)
  {
    BEGIN(mytype);
  }
  else
  {
    BEGIN(Body);
  }

  if (g_bParams)
  {
    if (g_bEnum)
    {
      BEGIN(Enum);
    }
    else
    {
      BEGIN(func_params);
    }
  }

}

<mytype>{ID}{S}*"="{S}*"-"*{NUM}".."{NUM} {
  OutputLog2("// here 1: ", yytext);

  string id = yytext;

  int pos = id.find('=', 0);
  string ids = id.substr(0,pos);

  fprintf(OUTPUT, "int %s", ids.c_str());
}

<mytype>type {
  OutputLog("// ignore type keyword");
}

<mytype>(^end;|{S}end;|{S}end{S};) {
  OutputLog("// Ignore end...");
}

<mytype>{ID} {
  OutputLog2("// processing types : ", yytext);
  // Processing a class

  // Just in case...
  if (pClass)
    delete pClass;

  pClass = new class_info;
  pClass->sName = yytext;
  BEGIN(myparent);
}

<myparent>("="|":"){S}*"class of" {
  OutputLog("// pointer to class");
  BEGIN(ClassPtrVar);
}

<myparent>("="|":"){S}*"^" {
  OutputLog("// pointer to class");
  BEGIN(ClassPtrVar);
}

<myparent>"="{S}"interface"{S}*"(" {
  g_bInterface = true;
  BEGIN(myparent2);
}

<myparent>"="{S}*"class"{S}*";" {
  OutputLog("// got x = class;");
  fprintf(OUTPUT, "class %s;\n", pClass->sName.c_str());

  BEGIN(mytype);
}

<myparent>"="{S}"class"{S}*"(" {
  BEGIN(myparent2);
} // Processing a class

<myparent2>","  // Ignore comma

<myparent2>{ID} {

  if (pClass->sParent != "")
  {
    OutputLog2("// Assigning parent2 : ", yytext);
    pClass->sParent2 = yytext;
  }
  else
  {
    OutputLog2("// Assigning parent : ", yytext);
	OutputLog2("// Name parent : ", pClass->sName.c_str());
    pClass->sParent = yytext;
  }
}

<myparent2>";" {
  OutputLog("// Output class details");
  fprintf(OUTPUT, "class %s : public %s,%s\n{\n", pClass->sName.c_str(), pClass->sParent.c_str(),
    pClass->sParent2.c_str());

  g_bClassBody = true;
  BEGIN(InClass);
}

<myparent2>")"";" {
  OutputInheritedClass(1);
  BEGIN(mytype);
}

<myparent2>")" {

  OutputInheritedClass(0);
  BEGIN(InClass);
}

<myparent>"="{S}"class" {
  OutputLog("// got base class");

  OutputInheritedClass(0);
  BEGIN(InClass);
}

<myparent>"="{S} { BEGIN(myparent3); }
<myparent>"="{S}"type" { BEGIN(myparent3); }
<myparent3>{ID} {

  OutputLog("// output class details and tidy up");

  pClass->sParent = yytext;
  fprintf(OUTPUT, "typedef %s %s", pClass->sParent.c_str(), pClass->sName.c_str());
  BEGIN(mytype);
}

<InClass,Body>published {

  if (g_bClassBody)
  {
    fprintf(OUTPUT, "public:"); BEGIN(InClass);
  }
  else
  {
    fprintf(OUTPUT, "%s", yytext);
  }
}

<InClass,Body>public|private|protected {

  OutputLog("// got keyword");

  if (g_bClassBody)
  {
    fprintf(OUTPUT, "%s:", yytext);
    BEGIN(InClass);
  }
  else
  {
    // some keyword appearing as text
    fprintf(OUTPUT, "%s", yytext);
  }
}

<Body,InClass>(^property|{S}property) {

  // Just in case...
  if (pProperty)
    delete pProperty;

  pProperty = new prop_info;

  pProperty->sName = "";
  pProperty->sType = "";
  BEGIN(Property);
}

<InClass>"["[^\]]+"]" {
  OutputLog("// Processing GUID");
  fprintf(OUTPUT, "%s", yytext);
}

<Property>"["[^\]]+"]" {
  fprintf(OUTPUT, "/*%s*/", yytext);
}


<Property>":" { BEGIN(prop_type); }

<prop_type>read { pProperty->bRead = true; }
<prop_type>write { pProperty->bRead = false; }

<prop_type>default{S}{NUM} {
  OutputLog("// got default");
  pProperty->sDefault = yytext;
 }

<prop_type>default{S}{ID} {
  OutputLog("// got default");
  pProperty->sDefault = yytext;
}
<prop_type>{ID} {
  OutputLog2("// prop type :", yytext);

  if (g_bFom)
  {
    if (pProperty->bRead)
    {
      pProperty->sRead = yytext;
    }
    else
    {
      pProperty->sWrite = yytext;
    }
  }
  else
  {
    pProperty->sType = yytext;

    g_bFom = true;
  }
}

<Property,prop_type>";" {

  if (g_bGenerateSa)
  {
    if (pProperty->sRead != "" && pProperty->sWrite != "")
    {
      fprintf(OUTPUT, "/** \\sa %s For reading   \\sa %s For writing */\n", pProperty->sRead.c_str(), pProperty->sWrite.c_str());
    }
    else if (pProperty->sRead != "")
    {
      fprintf(OUTPUT, "/** \\sa %s For reading*/\n", pProperty->sRead.c_str());
    }
    else if (pProperty->sWrite != "")
    {
      fprintf(OUTPUT, "/** \\sa %s For writing*/\n", pProperty->sWrite.c_str());
    }
  }

  fprintf(OUTPUT, "%s %s; \n", pProperty->sType.c_str(), pProperty->sName.c_str() );

  if (pProperty)
  {
    delete pProperty;
    pProperty = NULL;
  }

  g_bFom = false;

  if (g_bClassBody)
  {
    BEGIN(InClass);
  }
  else
  {
    BEGIN(Body);
  }
}

<Property>{ID}  {
  OutputLog2("// property :", yytext);

  pProperty->sName = yytext;
}

<Body,InClass>default;

<*>"{*}"        // Eat up {*}
<*>"{**" {
  OutputLog("daz2");
  if (!g_bComments)
  {
    if (!g_bIgnore)
    {
      if (g_bJavaDoc)
        fprintf(OUTPUT, "/**");
      else
        fprintf(OUTPUT, "/***");
    }

    g_bComments = true;
  }

  if (YY_START != comments)
    g_nCommentCaller = YY_START;

  BEGIN(comments);
}

<*>"{" {
  OutputLog("// Processing Block Comments");

  if (g_bVars)
  {
    fprintf(OUTPUT, yytext);
  }
  else
  {
    if (!g_bComments)
    {
  	  if (!g_bIgnore)
	  {
	    if (!g_bParams)
		{
          fprintf(OUTPUT, "/*");
		}
		else
		{
		  g_lstComments.push_back("/*");
	    }
	  }

      g_bComments = true;
    }
  }

  if (YY_START != comments)
    g_nCommentCaller = YY_START;

  BEGIN(comments);
}

<*>"}" {

  if (g_bVars)
  {
    OutputLog("g_bVars is true");
    fprintf(OUTPUT, yytext);
  }
  else
  {
    if (g_bIgnore)
    {
      OutputLog("// Ignore section in progress");
    }
    else
    {
	  if (!g_bParams)
	  {
	    OutputLog("g_bParams is false");
        fprintf(OUTPUT, "*/ ");
      }
	  else
	  {
	    g_lstComments.push_back("*/");
	  }
      g_bComments = false;
    }
  }

  BEGIN(g_nCommentCaller);
  g_nCommentCaller = 0;
}

<*>"(*" {
  // The pattern "*)" doesn't match though I don't know why.
  OutputLog("CurlyCommentInclusive");
  fprintf(OUTPUT, "/*");
//  fprintf(OUTPUT, "%.*s", yyleng - 4, &yytext[2]);
//  fprintf(OUTPUT, "*/");

  if (YY_START != ccomments)
    g_nCommentCaller = YY_START;

  BEGIN(ccomments);
}

<ccomments>"*)" {
  fprintf(OUTPUT, "*/");
  BEGIN(g_nCommentCaller);
  g_nCommentCaller = 0;
}

<Body,InClass,Struct>function|procedure|constructor|destructor          {

  if (g_nBegins > 0)
  {
    fprintf(OUTPUT, "%s", yytext);
  }
  else
  {
    OutputLog2("// processing a ", yytext);

    if (g_bComments)
    {
      // print the keyword, then continue commenting
      fprintf(OUTPUT, "%s", yytext);
      BEGIN(comments);
    }
    else
    {
      func_type ft = NORMAL;
      if (strcmp(yytext, "destructor") == 0)
        ft = DESTRUCTOR;

      if (strcmp(yytext, "constructor") == 0)
        ft = CONSTRUCTOR;

      ProcessFunction(ft);
      BEGIN(function);
    }
  }
}

<function>{ID}"."{ID} {
  OutputLog2("// processing function class.name :", yytext);
  string s = yytext;

  int pos = s.find('.', 0);
  int len = s.length();

  OutputLogNum("// Found . at position", pos);

  pFunc->sClass = s.substr(0, pos);
  pFunc->sName = s.substr(pos + 1, len -(pos+1) );

  OutputLog2("// Class = ", pFunc->sClass.c_str());
  OutputLog2("// Name  = ", pFunc->sName.c_str());
}

<function>{ID} {
  OutputLog2("// process function name :", yytext);
  pFunc->sName = yytext;
}

<function>"(" {
  OutputLog("// We've got a parameter list for this function");
  g_bParams = true;
  BEGIN(func_params);
}

<func_ret>{ID}"."{ID} {

  string str = yytext;

  string strUnit;
  string strRet;

  int pos = str.find('.', 0);
  int len = str.length();

  strUnit = str.substr(0, pos);
  strRet = str.substr(pos + 1, len -(pos+1) );

  fprintf(OUTPUT, "/// \\sa %s\n", strUnit.c_str());
  pFunc->sRet = strRet;

  if (g_bCallback)
  {
    BEGIN(callback);
  }
  else
  {
    BEGIN(function);
  }
}

<func_ret>{ID} {
  OutputLog2("// assign return type :", yytext);

  pFunc->sRet = yytext;

  if (g_bCallback)
  {
    BEGIN(callback);
  }
  else
  {
    BEGIN(function);
  }
}

<func_params>")"":" {
ProcessParameterType(g_processtype.c_str());
  OutputLog("// Parameter list has finished - there's a return type to be got");
  g_bParams = false;

  BEGIN(func_ret);
}


<func_params>")" {
ProcessParameterType(g_processtype.c_str());
  OutputLog("// Parameter list has finished");

  g_bAtEnd = true;
}

<func_params>"var"        { g_bVar = true; }

<func_params>"out" {
  g_bOut = true;

  // display parameter wise, treat in the same way as a var
  g_bVar = true;
}

<func_params>"const"      { g_bConst = true; }
<func_params>"of"

<func_params>"=" {
  OutputLog("// about to assign value");

  BEGIN(DefaultVal);
}

<DefaultVal>"'"[^']+"'" {
  //lstParams.back().sDefault = yytext;
  g_defaultvalue = yytext;
  ProcessParameterType(g_processtype.c_str());
  BEGIN(func_params);
}

<DefaultVal>"[]" {
  g_defaultvalue = yytext;
  ProcessParameterType(g_processtype.c_str());
  BEGIN(func_params);
}

<DefaultVal>"''" {
  //lstParams.back().sDefault = yytext;
  g_defaultvalue = yytext;
  ProcessParameterType(g_processtype.c_str());
  BEGIN(func_params);
}

<DefaultVal>{ID} {
  OutputLog2("// defaultval id : ", yytext);

  //lstParams.back().sDefault = yytext;
  g_defaultvalue = yytext;
  ProcessParameterType(g_processtype.c_str());
  BEGIN(func_params);
}

<DefaultVal>{NUM} {
  //lstParams.back().sDefault = yytext;
  g_defaultvalue = yytext;
  ProcessParameterType(g_processtype.c_str());
  BEGIN(func_params);
}

<func_params>{ID} {
  OutputLog2("// assign parameter info :", yytext);

  g_defaultvalue = "";
  g_processtype = "";

  param_info p("", yytext, "", "", g_bConst, g_bVar, g_bOut, g_bArray);
  lstParams.push_back(p);
}

<function>{S}":"{S}    { BEGIN(func_ret); }	// Get return type
<function>":"    { BEGIN(func_ret); }		// Get return type

<function>";" {
  list<param_info>::iterator i;

  OutputLog("// output function details");
  OutputLog(g_bClassBody ? "// g_bClassBody = true" : "// g_bClassBody = false");

// ------------------------
  // todo : remove this and fix underlying cause
  // needed to add, so function details are outputted correctly.
  fprintf(OUTPUT, "\n");
// ------------------------

  // Any return type?
  if (pFunc->sRet != "")
  {
    fprintf(OUTPUT, "%s ", pFunc->sRet.c_str() );
  }

  // destructor
  if (pFunc->eFuncType == DESTRUCTOR)
  {
    if (g_bClassBody)
    {
      fprintf(OUTPUT, "~");
      if (pClass->sName != "")
      {
        pFunc->sName = pClass->sName;
      }
    }
    else
    {
      if (pFunc->sClass != "")
      {
        pFunc->sName = "~" + pFunc->sClass;
      }
    }
  }

  // constructor
  if (pFunc->eFuncType == CONSTRUCTOR)
  {
    if (g_bClassBody)
    {
      if (pClass->sName != "")
      {
        pFunc->sName = pClass->sName;
      }
    }
    else
    {
      if (pFunc->sClass != "")
      {
        pFunc->sName = pFunc->sClass;
      }
    }
  }

  // Class
  if (pFunc->sClass != "" )
  {
    fprintf(OUTPUT, "%s::", pFunc->sClass.c_str() );
  }

  // Function name
  fprintf(OUTPUT, "%s (", pFunc->sName.c_str() );

  DisplayParams();

  fprintf(OUTPUT, ")");

  if (g_bClassBody || !g_bImplementation)
  {
    fprintf(OUTPUT, ";\n");
  }
  else
  {
    fprintf(OUTPUT, "\n");
  }

  if (pFunc)
  {
    delete pFunc;
    pFunc = NULL;
  }

  if (g_bClassBody)
  {
    BEGIN(InClass);
  }
  else
  {
    BEGIN(Body);
  }
}

<func_params>\n { }
<function>\n { }
<func_params>"," { }

<func_params>";"|"of object;" {
  OutputLog("// func_params 1");

  ProcessParameterType(g_processtype.c_str());

  if(g_bAtEnd)
  {
    g_bAtEnd = false;
    g_bParams = false;
    PushText(yytext);
    pFunc->sRet = "";

    if (g_bCallback)
    {
      BEGIN(callback);
    }
    else
    {
      BEGIN(function);
    }
  }
}

<func_params>":" {

  if (g_bAtEnd)
  {
    OutputLog("// Parameter list has finished - there's a return type to be got");
    g_bParams = false;
    g_bAtEnd = false;

    BEGIN(func_ret);
  }
  else
  {
    g_bConst = false;
    g_bOut = false;
    g_bVar = false;
    g_bArray = false;
    BEGIN(param_type);
  }
}

<param_type>{ID}"."{ID} {

  string str;

  str = yytext;

  int i =  str.find('.', 0);
  str = str.replace(i, 3, "::" );
  OutputLog2("// param type :", str.c_str());

  ProcessParameterType(str.c_str());

  BEGIN(func_params);
}

<param_type>"array of" {
  OutputLog("// Processing array of ");

  list<param_info>::iterator i;
  i = lstParams.begin();
  i->bArray = true;
}

<param_type>{ID} {
  OutputLog2("// processing parameter type :", yytext);

  //ProcessParameterType(yytext);
  g_processtype = yytext;

  BEGIN(func_params);
}

<ClassVar>"="{S}*"(" {
  ProcessEnums();
  BEGIN(Enum);
}

<ProcessVariable>{ID} {
  OutputLog2("// ProcessVariable ", yytext);

  g_bParams = true;

  param_info p ("", yytext,  "", "", false, false, false, false);
  lstParams.push_back(p);

  BEGIN(ProcessVariableType);
}

<ProcessVariableType>"," {
  OutputLog("// we've got a multiple variable definition");

  BEGIN(ProcessVariable);
}

<ProcessVariableType>":" {}	// Eat up the colon

<ProcessVariableType>{ID} {
  OutputLog2("// ProcessVariableType :", yytext);
  g_processtype = yytext;
  BEGIN(ProcessVariableType2);
}

<ProcessVariableType2>";" {
  OutputLog("// output the variable definition2");

  ProcessParameterType(g_processtype.c_str());
  DisplayVariables();
  g_bParams = false;

  BEGIN(g_nGeneralCaller);
}

<ProcessVariableType2>"=" {
  BEGIN(ProcessVariableType3);
}

<ProcessVariableType3>"-"*{NUM} {
  g_defaultvalue = yytext;

  OutputLog2("// got size = ", yytext);
  
  ProcessParameterType(g_processtype.c_str());

  BEGIN(ProcessVariableType);
}

<ProcessVariableType>";" {
  OutputLog("// output the variable definition");

  DisplayVariables();
  g_bParams = false;

  BEGIN(g_nGeneralCaller);
}

<InClass,Struct,mytype>{ID}{S}*(","{S}*"//"[^}\n]*)+ {
  OutputLog("// multiple def with comments");
  PushText(yytext);
  g_nGeneralCaller = YY_START;
  BEGIN(ProcessVariable);
}

<InClass,Struct,Constants,mytype>{ID}{S}*":"{S}*"-"*{NUM}{S}*".."{S}*"-"*{NUM}{S}*";" {
  OutputLog2("// got a subrange var = ", yytext);

  string str = yytext;
  int pos = str.find(':', 0);
  int len = str.length();

  string name = str.substr(0,pos);
  string rest = str.substr(pos + 1, len -(pos+1) );

  fprintf(OUTPUT, "long %s;  ", name.c_str());
  fprintf(OUTPUT, "/**< Subrange %s */\n", rest.c_str());
}

<InClass,Struct,mytype>{ID}{S}*(","{S}*{ID}{S}*)+":"{S}*{ID}{S}*";" {
  OutputLog("// got a multiple definition");

  PushText(yytext);
  g_nGeneralCaller = YY_START;
  BEGIN(ProcessVariable);
}

<InClass,Struct>{ID}{S}*":"{S}*{ID}{S}*";" {
  OutputLog("InClass,Struct");
  PushText(yytext);
  g_nGeneralCaller = YY_START;
  BEGIN(ProcessVariable);
}

<InClass,Struct>{ID} {
  OutputLog2("// process a class variable", yytext);

  pClass->sVar = yytext;

//  PushText(yytext);

//  g_nGeneralCaller = YY_START;
//  BEGIN(ProcessVariable);

//  g_bParams = true;

//  param_info p ("", yytext,  "", "", false, false, false, false);
//  lstParams.push_back(p);

  BEGIN(ClassVar);

}

<ClassVar>"," {
  OutputLog("// we've got a multiple variable definition");

  if(g_bClassBody)
  {
    BEGIN(InClass);
  }
  else
  {
    BEGIN(Struct);
  }
}

<ClassVar>":" {}	// Eat up the colon

<ClassVar>{ID} {
  OutputLog2("// classvar ID :", yytext);
  ProcessParameterType(yytext);
}

<ClassVar>";" {
  OutputLog("// output the variable definition");

  DisplayVariables();
  g_bParams = false;

  if(g_bClassBody)
  {
    BEGIN(InClass);
  }
  else
  {
    BEGIN(Struct);
  }
}

<ClassPtrVar>{ID} {
  OutputLog2("// classvar id :", yytext);
  pClass->sType = yytext;
}

<ClassPtrVar>";" {
  OutputLog("// output the typedef");
  fprintf(OUTPUT, "typedef %s* %s;\n", pClass->sType.c_str(), pClass->sName.c_str());

  BEGIN(mytype);
}

<Uses>;         { BEGIN(Body); }
<Uses>{ID} {}
<Uses>, {}

%%

//*****************************************************************************
/// Push text back for processing
void PushText(const char* txt)   ///< Text to be put back
{
  int i;

  char* yycopy = strdup(txt);
  for (i = yyleng -1 ; i >= 0; --i)
    unput(yycopy[i]);

  free(yycopy);
}

//*****************************************************************************
/// Output program version information
void version_info(void)
{
  fprintf(stdout, "Pas2Dox version %s %s\n", version, date);
  fprintf(stdout, "Copyright Darren Bowles 2002,2003\n\n");
  fprintf(stdout, "Pas2dox is a Pascal/Delphi/Kylix input filter for Doxygen\n\n");
  fprintf(stdout, "pas2dox [-h] [-d] [-k] [-i] [-o] <input_file>\n");
  fprintf(stdout, " -h - Help Information\n");
  fprintf(stdout, " -d - Run In Debug Mode\n");
  fprintf(stdout, " -k - Don't Comment Out Function Body\n");
  fprintf(stdout, " -i - Process only \'Interface\' section\n");
  fprintf(stdout, " -j - JavaDoc processing\n");
  fprintf(stdout, " -o - Output to filename.cpp instead of console\n");
  fprintf(stdout, " -b - Experimental convert function body to c++\n");
  fprintf(stdout, " -s - Suppress generation of \\sa clauses on properties");
}

int main (int argc, char** argv)
{
  bool bOutput   = false;
  bool bEnd      = false;
  bool bShowHelp = true;

  for (int i = 1; i < argc && !bEnd; ++i)
  {
    if (strlen(argv[i]) == 2 && argv[i][0] == '-')
    {
      // commandline option
      switch (argv[i][1])
      {
      case 'd':
        g_bDebugMode = true;
        break;

      case 'k':
        g_bKeepBody = true;
        break;

      case 'j':
        g_bJavaDoc = true;
        break;

      case 'o':
        bOutput = true;
        break;

      case 'i':
        g_bInterfaceOnly = true;
        break;

      case 'b':
        g_bConvertBody = true;
        break;
  
      case 's':
        g_bGenerateSa = false;
        break;

      case 'h':
      default:
	    bEnd = true;
      }
    }
    else
    {
      if (i == argc - 1)
      {
#if 0
        static const char piper[] = "c:\\python26\\python d:\\testproj\\python\\sjis2utf8.py <";
        char *fname = new char[strlen(argv[i]) + sizeof piper];
        strcpy(fname, piper);
        strcat(fname, argv[i]);
        // input filename
        yyin = popen(fname, "r");
        delete[] fname;
#else
        yyin = fopen(argv[i], "r");
#endif

        if (yyin == NULL)
        {
          fprintf(stdout, "Error : Filename %s Not Found.\n", argv[i]);
          return 1;
        }

        bShowHelp = false;

        if (bOutput)
        {
          string filename = argv[i];
          filename += ".cpp";

          OUTPUT = fopen(filename.c_str(), "w");
        }
        else
          OUTPUT = stdout;
      }
    }
  }

  if (bShowHelp || !OUTPUT)
  {
    version_info();
    return 0;
  }

  if (g_bDebugMode)
  {
    fprintf(OUTPUT, "// Running In Debug Mode...\n\n");
  }


  yyout = OUTPUT;
  yylex();

  return 0;
}

extern "C"
{
  int yywrap() { return 1; }
  void codeYYdummy() { yy_flex_realloc(0,0); }
}
