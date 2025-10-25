function resize(this,Ny)
%RESIZE  Adjusts input plot to fill all available rows.

%  Copyright 1986-2014 The MathWorks, Inc.
Curves = this.Curves;
nobj = length(Curves);
if nobj>Ny
   delete(Curves(Ny+1:nobj))
   this.Curves = Curves(1:Ny);
else
   p = this.Curves(1).Parent;
   for ct=Ny:-1:nobj+1
      % UDDREVISIT
      Curves(ct,1) = controllibutils.utCustomCopyLineObj(Curves(1),p);
   end
   this.Curves = Curves;
end