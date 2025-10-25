function o = odeget(options,name,default)
%ODEGET Get ODE OPTIONS parameters.
%   VAL = ODEGET(OPTIONS,'NAME') extracts the value of the named property
%   from integrator options structure OPTIONS, returning an empty matrix if
%   the property value is not specified in OPTIONS. It is sufficient to type
%   only the leading characters that uniquely identify the property. Case is
%   ignored for property names. [] is a valid OPTIONS argument.
%   
%   VAL = ODEGET(OPTIONS,'NAME',DEFAULT) extracts the named property as
%   above, but returns VAL = DEFAULT if the named property is not specified
%   in OPTIONS. For example
%   
%       val = odeget(opts,'RelTol',1e-4);
%   
%   returns val = 1e-4 if the RelTol property is not specified in opts.
%   
%   See also ODESET, ODE45, ODE23, ODE113, ODE15S, ODE23S, ODE23T, ODE23TB.

%   Mark W. Reichelt and Lawrence F. Shampine, 3/1/94
%   Copyright 1984-2024 The MathWorks, Inc.

arguments
   options {localMustBeEmptyOrStruct}
   name {mustBeTextScalar}
   default = []
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
    "BDF"
    "Events"
    "InitialStep"
    "Jacobian"
    "JConstant"
    "JPattern"
    "Mass"
    "MassSingular"
    "MaxOrder"
    "MaxStep"
    "MinStep"
    "NonNegative"
    "NormControl"
    "OutputFcn"
    "OutputSel"
    "Refine"
    "RelTol"
    "Stats"
    "Vectorized"
    "MStateDependence"
    "MvPattern"
    "InitialSlope"
    ];

j = startsWith(Names,name,'IgnoreCase',true);
if ~any(j)               % if no matches
    error(message('MATLAB:odeget:InvalidPropName', name));
elseif sum(j) > 1            % if more than one match
    % Check for any exact matches (in case any names are subsets of others)
    k = strcmpi(Names,name);
    if sum(k) == 1
        j = k;
    else
        matches = join(Names(j),', ');
        error(message('MATLAB:odeget:AmbiguousPropName',name,matches));
    end
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
end

function localMustBeEmptyOrStruct(options)
if ~isempty(options) && ~isstruct(options)
    error(message('MATLAB:odeget:Arg1NotODESETstruct'));
end
end