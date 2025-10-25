function varargout = convertSizeArgToDouble(varargin)
%convertSizeArgToDouble convert size argument to double.

%   Copyright 2023 The MathWorks, Inc.

varargout = varargin;
for i = 1:nargin
    vi = varargout{i};
    try
        if isobject(vi) && (isnumeric(vi) || islogical(vi))
            varargout{i} = cast(vi,'like',1);
        end
    catch e
        if e.identifier == "MATLAB:cast:UnsupportedPrototype"
            me = MException(message('MATLAB:invalidConversion','double',class(vi)));
            throwAsCaller(me);
        end
    end
end
