function x = validate3DCartCoord(x, funcname, varname, varargin)
%VALIDATE3DCARTCOORD Validate 3D coordinates
%   validate3DCartCoord(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid 3D coordinates. FUNC_NAME and VAR_NAME are used
%   in VALIDATEATTRIBUTES to come up with the error id and message.
%
%   validate3DCartCoord(...,VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions, in a
%   cell array VARARGIN.
%
%   Y = validate3DCartCoord(...) outputs the validated value.
%
%   Example:
%       % Validate whether [1;1;1] is a valid 3D coordinates.
%       sigdatatypes.validate3DCartCoord([1; 1; 1],'foo','bar');

%   Copyright 2009-2015 The MathWorks, Inc.

%#codegen 
%#ok<*EMCA>


validateattributes(x,{'double'},{'finite','nonnan','nonempty','real',...
    '2d'},funcname,varname);


if ~isempty(varargin)
    validateattributes(x,{'double'},varargin{:},funcname,varname);
end
coder.internal.assert(size(x,1) == 3,...
                      'siglib:sigdatatypes:schema:expectedNumRows',varname,3);


% [EOF]
