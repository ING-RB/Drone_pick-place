function Str = message(ID,varargin)
% message Package method for getting string from message ID.

%   Copyright 1986-2010 The MathWorks, Inc.


try
    mObj = message(ID,varargin{:}); 
    Str = mObj.getString;
catch e
    rethrow(e);
end
    

