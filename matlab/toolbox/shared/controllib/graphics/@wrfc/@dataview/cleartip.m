function cleartip(this)
%CLEARTIP  Clears data tip for all view objects.
 
%   Copyright 1986-2004 The MathWorks, Inc.
for dv=this(:)'
   dv.addtip('');
end