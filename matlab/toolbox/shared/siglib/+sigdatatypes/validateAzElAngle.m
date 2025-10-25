function x = validateAzElAngle(x, funcname, varname, varargin)
%VALIDATEAZELANGLE Validate azimuth and elevation angle matrix
%   validateAzElAngle(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid [azimuth;elevation] angle matrix. FUNC_NAME and
%   VAR_NAME are used in VALIDATEATTRIBUTES to come up with the error id
%   and message.
%
%   validateAzElAngle(...,VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions, in a
%   cell array VARARGIN.
%
%   Y = validateAzElAngle(...) outputs the validated value.
%
%   Example:
%       % Validate whether [0;0] is a valid azimuth and elevation angle 
%       % pair.
%       sigdatatypes.validateAzElAngle([0; 0],'foo','bar');
%       % Validate whether single input is valid or not 
%       sigdatatypes.validateAzElAngle(single([0; 0]),'foo','bar',{'double','single'},{'real'});


%   Copyright 2009-2018 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

if numel(varargin)< 2
    type = {'double'};
else
    type = varargin{1};
end

validateattributes(x,type,{'finite','nonnan','nonempty','real',...
    '2d'},funcname,varname);
if ~isempty(varargin)
    if numel(varargin) < 2
        validateattributes(x,type,varargin{1},funcname,varname);
    else
        validateattributes(x,type,varargin{2},funcname,varname);
    end
end
coder.internal.assert(size(x,1) == 2,...
    'siglib:sigdatatypes:schema:expectedNumRows',varname,2);
validateattributes(x(1,:),type,{'<=',180,'>=',-180},funcname,...
    'Azimuth angles');

validateattributes(x(2,:),type,{'<=',90,'>=',-90},funcname,...
    'Elevation angles');
end

% [EOF]
