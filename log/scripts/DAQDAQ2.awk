#!/bin/gawk -f


BEGIN{
  FS="[><]";
  line=-1;
  ch=0;
}{
   if(match($0,"Lockpoint")>0){
	   line=NR;
   } 
   if(NR==line+1){
	   ch++;
	   if(ch<=4){
	     print "<Val>"$3+mult*del1"</Val>"
	   }
	   else if(ch>4 && ch<=8){
	     print "<Val>"$3+mult*del2"</Val>"
	   }
	   else if(ch>8){
	     print "<Val>"$3+mult*del3"</Val>"
	   }
   }
   else{
	   print $0
   }
}
