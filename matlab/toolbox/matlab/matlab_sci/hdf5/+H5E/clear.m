function clear
%H5E.clear  Clear error stack.
%   H5E.clear() clears the error stack for the current thread.
%
%   See also H5E.

%   Copyright 2006-2024 The MathWorks, Inc.

matlab.internal.sci.hdf5lib2('H5Eclear');
