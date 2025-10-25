function x = validateLatLon(x, funcname, varname, varargin)
%VALIDATELatLon Validate latitude and longitude matrix
%   validateLatLon(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid [latitude;longitude] angle matrix. FUNC_NAME and
%   VAR_NAME are used in VALIDATEATTRIBUTES to come up with the error id
%   and message.
%
%   validateLatLon(...,CLASS) specifies the valid class of the input of X.
%   The default is 'double'.
%
%   validateLatLon(...,ATTRIB) or validateLatLon(...,CLASS,ATTRIB)
%   specifies additional attributes supported in VALIDATEATTRIBUTES, such
%   as sizes and dimensions, in a cell array ATTRIB.
%
%   Y = validateLatLon(...) outputs the validated value.
%
%   Example:
%       % Validate whether [0;0] is a valid latitude and longitude angle 
%       % pair.
%       sigdatatypes.validateLatLon([0; 0],'foo','bar');
%       % Validate whether single input is valid or not 
%       sigdatatypes.validateLatLon(single([0; 0]),'foo','bar',{'double','single'},{'real'});


%   Copyright 2022 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

if numel(varargin)< 2
    type = {'double'};
else
    type = varargin{1};
end

validateattributes(x,type,{'finite','nonnan','nonempty','real',...
    '2d','ncols',2},funcname,varname);
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
end

% [EOF]
