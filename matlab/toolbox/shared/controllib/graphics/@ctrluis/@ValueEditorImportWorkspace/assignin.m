function assignin(this,var,val) 
% ASSIGNIN  Assign a variable in the workspace
%
 
% Copyright 2012-2014 The MathWorks, Inc.

this.Data.(matlab.lang.makeValidName(var)) = val;

ed = ctrluis.dataevent(this,'ComponentChanged',var);
send(this,'ComponentChanged',ed)
end
