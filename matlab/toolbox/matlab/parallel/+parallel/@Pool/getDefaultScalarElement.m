function defaultElem = getDefaultScalarElement() %#ok<STOUT>
%getDefaultScalarElement Get the default element when assigning past the
% end of a parallel.Pool array.

%   Copyright 2020 The MathWorks, Inc.

throwAsCaller(MException(message("MATLAB:parallel:pool:CannotPreallocatePoolArray")));
end
