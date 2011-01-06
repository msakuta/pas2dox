/** \file
 * Declared constants
 */ 






   const  Min =  0;
   const  Max =  100;
   const  Center =  (Max - Min) div 2;
   const  Beta =  Chr(225);
   const  NumChars =  Ord("Z") - Ord("A") + 1;
   const  Message =  "Out of memory";
   const  ErrStr =  " Error: " + Message + ". ";
   const  ErrPos =  80 - Length(ErrStr) div 2;
   const  Ln10 =  2.302585092994045684;
   const  Ln10R =  1 / Ln10;
   const  Numeric =  ["0".."9"];
   const  Alpha =  ["A".."Z", "a".."z"];
   const  AlphaNum =  Alpha + Numeric;
   Longint THPTimerARRAY[4]; /*!< [1..4] */

   char TVendor[11]; /*!< [0..11] */

      const HWND _HHwinHwnd = 0; 
 /**< Help Window handle */ 


  // Typed constant
  // Typed constants handling broken with version 1.86 of pas2dox.l
  //   the following line should parse to 'const Integer Max = 100;'
  //   instead of 'Max: const Integer = 100;'
  //Max: Integer = 100;

   const  TMyType =  integer;



   const  CreateError =  "Cannot create file %s";        /*  for explanations of format specifiers, */ 
   const  OpenError =  "Cannot open file %s";            /* see 'Format strings' in the online Help */ 
   const  LineTooLong =  "Line too long";
   const  ProductName =  "Borland Rocks\000\000";
   const  SomeResourceString =  SomeTrueConstant;



// finished

