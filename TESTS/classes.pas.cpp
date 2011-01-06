/** \file
 * classes and procedures
 */ 



/**
 * TMemoryStream class derived from TCustomMemoryStream
 */ 
 class TMemoryStream : public TCustomMemoryStream
{
public:

  private:
      Longint FCapacity; 
                            ///< Private field
      
SetCapacity (Longint NewCapacity 
);
   ///< Private method
  protected:
        
Pointer Realloc (Longint &NewCapacity 
);
 ;

    /// Protected property
         /** \sa FCapacity For reading   \sa SetCapacity For writing */
Longint Capacity; 

  public:
     
~TMemoryStream ();
 ;
     
Clear ();

      
LoadFromStream (TStream Stream 
);


       
LoadFromFile (const string FileName 
);

      
SetSize (Longint NewSize 
);
 ;
         
Longint Write (const  Buffer ,
const Longint Count 
);
 ;
 };


   typedef integer TMyType;

   class TMyClass
{
public:

 };
/*TMyClass*/  






           
TMemoryStream::Write (const Longint Buffer ,///< buffer line
const Longint Count ///< counter
)
{
#ifndef DOXYGEN_SKIP
  // some comment
#endif /* DOXYGEN_SKIP */
};

   
LoadFromStream (TStream Stream 
)
{
#ifndef DOXYGEN_SKIP

#endif /* DOXYGEN_SKIP */
};

// finished

