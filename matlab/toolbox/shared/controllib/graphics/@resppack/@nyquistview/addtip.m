function addtip(this,tipfcn,info)
%ADDTIP  Adds line tip to each curve in each view object

%  Copyright 1986-2004 The MathWorks, Inc.
Curves = this.Curves;
for ct1 = 1:size(Curves,1)
   for ct2 = 1:size(Curves,2)
      info.Row = ct1; 
      info.Col = ct2;
      this.installtip(Curves(ct1,ct2),tipfcn,info)
   end
end
