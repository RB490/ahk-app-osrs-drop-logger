IsPicture( sFile, ByRef W:="", ByRef H:="" ) {         ;  IsPicture() v0.9.0.00   for AutoHotkey 1.1   
Local  File, V1, V2, Type, BigEndian                   ;  Author: SKAN          Created: 24-Aug-2017                 
Local  oIFD, nIFD, nTag, tTag, sLen, Segm, cLen, cTyp  ;  Topic : goo.gl/SK2MXx LastMod: 30-Aug-2017 
Static Bin  

  W := H := 0
  File := FileOpen(sFile,"r")
  If ! ( IsObject(File) )
     Return 0   
  VarSetCapacity(Bin,46,0)
  sLen := File.RawRead(Bin,46)
  If (sLen<46)
     Return (File.Close()>>64)  

  V1 := NumGet(Bin,"Int64") 
  If ( V1 = 0x0A1A0A0D474E5089) && ( Type := "PNG" )              ; PNG
  {
      If ! (IsByRef(W) || IsByRef(H))
         Return ( File.Close()+"" ) . Type 

      cTyp := 0,  File.Seek(8,0)
      While (cTyp<>0x444E4549)                                    ; Until IEND chunk
      {
        If (File.RawRead(Bin,8)<8)
           Break
        cLen := NumGet(Bin,"UInt")                                ; Chunk data Length
        cLen := ( (cLen & 255)<<24 | (cLen>>8 & 255)<<16 | (cLen>>16 & 255)<<8 | cLen>>24 )
        cTyp := NumGet(Bin,4,"UInt") 
        If ( cTyp=0x52444849 )                                    ; IHDR chunk found
        {
            File.RawRead(Bin,cLen)
            W := NumGet(Bin,0,"UInt")
            W := ( (W & 255)<<24 | (W>>8 & 255)<<16 | (W>>16 & 255)<<8 | W>>24 )
            H := NumGet(Bin,4,"UInt")
            H := ( (H & 255)<<24 | (H>>8 & 255)<<16 | (H>>16 & 255)<<8 | H>>24 )
            Break
        }
        File.Seek(cLen+4,1)
      }        
      Return ( File.Close()+"" ) . ( W>0 && H>0 ? Type : 0 )
  }

  V1 &= 0xFFFFFFFF                                                ; Convert Int64 to UInt 
  If ( V1 = 0x2A004D4D || V1 = 0x002A4949 ) && ( Type := "TIF" )  ; TIFF/MAC or TIFF/IBM-PC
  {
      If ! (IsByRef(W) || IsByRef(H))
         Return ( File.Close()+"" ) . Type 

      BigEndian := ( NumGet(Bin,"UShort") = 0x4D4D )
      oIFD := NumGet(Bin,4,"UInt")                                ; Offset to IFD0 
      oIFD := BigEndian 
           ? ( (oIFD & 255)<<24 | (oIFD>>8 & 255)<<16 | (oIFD>>16 & 255)<<8 | oIFD>>24 ) : oIFD
      File.SeeK(oIFD,0)    
      File.RawRead(Bin,2)
      nIFD := NumGet(Bin,"UShort")                                ; Number of tags in IFD0
      nIFD := BigEndian ? ( (nIFD & 0xFF)<<8 | nIFD>>8 ) : nIFD 

      While ( W=0 || H=0 && A_Index<=nIFD )                       ; Read IFD0 tags one by one
      {
        File.RawRead(Bin,12)                                      ; Each Tag is 12 bytes     
        nTag := NumGet(Bin,"UShort")                              ; Tag ID
        nTag := BigEndian ? ( (nTag & 0xFF)<<8 | nTag>>8 ) : nTag 
        tTag := NumGet(Bin,2,"UShort")                            ; TagType:  4=UInt, 3=UShort
        tTag := BigEndian ? ( (tTag & 0xFF)<<8 | tTag>>8 ) : tTag 

        If ( nTag=0x0100 )                                        ; 0x0100 = TIFFTAG_IMAGEWIDTH 
        If ( tTag=3 )                                             ; Width is stored as UShort
             W := Numget(Bin,8,"UShort")
           , W := BigEndian ? ( (W & 0xFF)<<8 | W>>8 ) : W
        Else W := Numget(Bin,8,"UInt")                     ; Width is stored as UInt
           , W := BigEndian ? ( (W & 255)<<24 | (W>>8 & 255)<<16 | (W>>16 & 255)<<8 | W>>24 ) : W
        
        If ( nTag=0x0101 )                                        ; 0x0101 = TIFFTAG_IMAGELENGTH 
        If ( tTag=3 )                                             ; Height is stored as UShort
             H := Numget(Bin,8,"UShort")
           , H := BigEndian ? ( (H & 0xFF)<<8 | H>>8 ) : H
        Else H := Numget(Bin,8,"UInt")                     ; Height is stored as UInt
           , H := BigEndian ? ( (H & 255)<<24 | (H>>8 & 255)<<16 | (H>>16 & 255)<<8 | H>>24 ) : H
      }  
      Return ( File.Close()+"" ) . ( W>0 && H>0 ? Type : 0 )
  }

  V1 &= 0xFFFFFF                                                  ; Convert UInt to UInt24
  If ( V1 = 0xFFD8FF) && ( Type := "JPG" )                        ; JPEG/JFIF and JPEG/Exif
  {
      If ! (IsByRef(W) || IsByRef(H))
         Return ( File.Close()+"" ) . Type 

      sLen := 0,  File.Seek(4,0)                                       
      Loop {                                                      ; Read segments one by one
        File.Seek(sLen-2,1)
        If ( File.RawRead(Bin,4)<4 || (Segm:=NumGet(Bin,0,"UShort"))<0x00FF )
             Return (File.Close()>>64)
        Else Segm >>= 8
        If ( Segm>=0xC0 && Segm<=0xCF && Segm<>0xCC && Segm<>0xC4 )
           Break    
        sLen := NumGet(Bin,2,"UShort" )                           ; Segment Length
        sLen := ( (sLen & 0xFF)<<8 | sLen>>8 )
      }   

      File.Seek(-4,1),                 File.RawRead(Bin,sLen)
      W := NumGet(Bin,7,"UShort"),     W := ( (W & 0xFF)<<8 | W>>8 )
      H := NumGet(Bin,5,"UShort"),     H := ( (H & 0xFF)<<8 | H>>8 )
      Return ( File.Close()+"" ) . ( W>0 && H>0 ? Type : 0 )
  }

  V2 := NumGet(Bin,3,"UInt") & 0xFFFFFF
  If ( V1 = 0x464947 && V2 = 0x613738 || V2 = 0x613938 )          ; "GIF" and "87a" or "89a"
  {
      File.Seek(-1,2)                                             ; Seek last Char
      If ( File.ReadUCHAR() = 0x3B )                              ; Last character is semi-colon
           W := NumGet(Bin,6,"UShort")  
         , H := NumGet(Bin,8,"UShort")
      Return ( File.Close()+"" ) . ( W>0 && H>0 ? "GIF" : 0 ) 
  }
  
  File.Close()  ; Close the file and operate from 46 memory bytes for ICO, BMP, WMF and EMF
   
  If ( NumGet(Bin,0, "UInt") = 0x00010000 && NumGet(Bin,4,"UChar") > 0 )            
  && ( NumGet(Bin,9,"UChar") = 0 && NumGet(Bin,10,"UShort") < 2 ) && (Type:="ICO")    ; ICO
  {
      If (IsByRef(W) || IsByRef(H))
        W := NumGet(Bin,0,"UChar") ? NumGet(Bin,0,"UChar") : 256 
      , H := NumGet(Bin,1,"UChar") ? NumGet(Bin,1,"UChar") : 256
      Return ( File.Close()+"" ) . Type
  }  

  If ( V1 & 0xFFFF = 0x4D42 && NumGet(Bin,6,"UInt") = 0 )           ; BMP
  && ( V2 := NumGet(Bin,14,"UInt") ) && ( V2=12 || V2=40 || V2=56 || V2=108 || V2=124 )
  {       
         W := NumGet(Bin,18,V2=12?"UShort":"UInt")                  ; accommodating BITMAPCOREHEADER 
         H := NumGet(Bin,V2=12?20:22, V2=12?"UShort":"UInt")        ; accommodating BITMAPCOREHEADER
         H := Abs(H)                                                ; Bitmap might be top bottom
    Return ( W>0 && H>0 ? "BMP" : 0 )
  } 

  If ( NumGet(Bin,40,"UInt") = 0x464D4520 && NumGet(Bin,"Int") = 1 )                  ; EMF  
      Return "EMF" . ( W := H := "" )
                                                                  
  If ( NumGet(Bin, 0,"UInt") = 0x9AC6CDD7 && NumGet(Bin,24,"UInt") = 0x03000009 )     ; WMF -> APM 
      Return "WMF" . ( W := H := "" )
                                                                  
  If ( NumGet(Bin, 2,"UInt") = 0x03000009 && NumGet(Bin,16,"Short") = 0 )             ; WMF       
       Return "WMF" . ( W := H := "" )

Return 0
} ; ________________________________________________________________________________________________