function addtip(this,tipfcn,info)
%ADDTIP  Adds a buttondownfcn to mean lines in @MeanValueView object.

%   Copyright 2013 The MathWorks, Inc.
for ct1 = 1:size(this.Points,1)
   for ct2 = 1:size(this.Points,2)
      info.Row = ct1;
      info.Col = ct2;
      Line = this.Points(ct1,ct2);
      this.installtip(Line,tipfcn,info)
      set(Line,'Tag','CharPoint')
   end
end
