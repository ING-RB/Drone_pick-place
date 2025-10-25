function x = validateLLA(x, funcname, varname, varargin)
%VALIDATELLA Validate LLA coordinate matrix
%   validateLLLA(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid [latitude;longitude;altitude] matrix. FUNC_NAME and
%   VAR_NAME are used in VALIDATEATTRIBUTES to come up with the error id
%   and message.
%
%   validateLLA(...,CLASS) specifies the valid class of the input of X.
%   The default is 'double'.
%
%   validateLLA(...,ATTRIB) or validateLLA(...,CLASS,ATTRIB)
%   specifies additional attributes supported in VALIDATEATTRIBUTES, such
%   as sizes and dimensions, in a cell array ATTRIB.
%
%   Y = validateLLA(...) outputs the validated value.
%
%   Example:
%       % Validate whether [0;0] is a valid latitude and longitude angle 
%       % pair.
%       sigdatatypes.validateLLA([0; 0],'foo','bar');
%       % Validate whether single input is valid or not 
%       sigdatatypes.validateLLA(single([0; 0]),'foo','bar',{'double','single'},{'real'});


%   Copyright 2022 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

if numel(varargin)< 2
    type = {'double'};
else
    type = varargin{1};
end

validateattributes(x,type,{'finite','nonnan','nonempty','real',...
    '2d','ncols',3},funcname,varname);
if ~isempty(varargin)
    if numel(varargin) < 2
        validateattributes(x,type,varargin{1},funcname,varname);
    else
        validateattributes(x,type,varargin{2},funcname,varname);
    end
end
validateattributes(x(:,2),type,{'<=',180,'>=',-180},funcname,...
    'Longitude');

validateattributes(x(:,1),type,{'<=',90,'>=',-90},funcname,...
    'Latitude');
validateattributes(x(:,3),type,{'nonnegative'},funcname,...
    'Altitude');
end

% [EOF]
