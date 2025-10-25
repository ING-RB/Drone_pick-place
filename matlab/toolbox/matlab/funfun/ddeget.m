function o = ddeget(options,name,default)
%DDEGET  Get DDE OPTIONS parameters.
%   VAL = DDEGET(OPTIONS,'NAME') extracts the value of the named property
%   from integrator options structure OPTIONS, returning an empty matrix if
%   the property value is not specified in OPTIONS. It is sufficient to type
%   only the leading characters that uniquely identify the property. Case is
%   ignored for property names. [] is a valid OPTIONS argument.
%   
%   VAL = DDEGET(OPTIONS,'NAME',DEFAULT) extracts the named property as
%   above, but returns VAL = DEFAULT if the named property is not specified
%   in OPTIONS. For example
%   
%       val = ddeget(opts,'RelTol',1e-4);
%   
%   returns val = 1e-4 if the RelTol property is not specified in opts.
%   
%   See also DDESET, DDE23, DDESD, DDENSD.

%   Copyright 1984-2022 The MathWorks, Inc.

if nargin < 3
    default = [];
end

if ~isempty(options) && ~isstruct(options)
    error(message('MATLAB:ddeget:Arg1NotStruct'));
end

if isempty(options)
    o = default;
    return;
end

% options is struct
if isfield(options, name)  % Handle exact match
    o = options.(name);
    if isempty(o)
        o = default;
    end
    return
end

Names = [
    "AbsTol"
    "Events"
    "InitialStep"
    "InitialY"
    "Jumps"
    "MaxStep"
    "NormControl"
    "OutputFcn"
    "OutputSel"
    "Refine"
    "RelTol"
    "Stats"
    ];

j = startsWith(Names,name,'IgnoreCase',true);
if ~any(j)               % if no matches
    error(message('MATLAB:ddeget:InvalidPropName', name));
elseif sum(j) > 1            % if more than one match
    matches = join(Names(j),', ');
    error(message('MATLAB:ddeget:AmbiguousPropName',name,matches));
end

fieldname = Names(j);
if isfield(options,fieldname)
    o = options.(fieldname);
    if isempty(o)
        o = default;
    end
else
    o = default;
end
