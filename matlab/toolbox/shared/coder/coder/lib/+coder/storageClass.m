function storageClass(varargin)
%STORAGECLASS Specify a storage class to attach to a variable.
%
%   CODER.STORAGECLASS('NAME','CLASS') Requests that the global variable
%   named NAME should be of the storage class type CLASS. Both the
%   arguments must be constant strings. The argument NAME must refer to a
%   global variable declared in the function containing the
%   CODER.STORAGECLASS specification. The argument CLASS must be a valid
%   storage class name. Currently supported storage class names are the
%   following:
%       1.) ExportedGlobal
%       2.) ImportedExtern
%       3.) ImportedExternPointer
%   
%   Example: 
%     Make global variable 'x' of storage class type 'ImportedExtern':
%
%     global x
%     coder.storageClass('x','ImportedExtern');
%    
%   This is a code generation function.  It has no effect in MATLAB.
%
%   See also GLOBAL, CODER.CSTRUCTNAME.

%   Copyright 2014-2019 The MathWorks, Inc.

end

