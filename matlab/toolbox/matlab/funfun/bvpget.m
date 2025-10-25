function o = bvpget(options,name,default)
%BVPGET  Get BVP OPTIONS parameters.
%   VAL = BVPGET(OPTIONS,'NAME') extracts the value of the named property
%   from integrator options structure OPTIONS, returning an empty matrix if
%   the property value is not specified in OPTIONS. It is sufficient to type
%   only the leading characters that uniquely identify the property. Case is
%   ignored for property names. [] is a valid OPTIONS argument. 
%   
%   VAL = BVPGET(OPTIONS,'NAME',DEFAULT) extracts the named property as
%   above, but returns VAL = DEFAULT if the named property is not specified
%   in OPTIONS. For example 
%   
%       val = bvpget(opts,'RelTol',1e-4);
%   
%   returns val = 1e-4 if the RelTol property is not specified in opts.
%   
%   See also BVPSET, BVPINIT, BVP4C, BVP5C, DEVAL.

%   Jacek Kierzenka and Lawrence F. Shampine
%   Copyright 1984-2022 The MathWorks, Inc. 

if nargin < 3
    default = [];
end

if ~isempty(options) && ~isa(options,'struct')
    error(message('MATLAB:bvpget:OptsNotStruct'));
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

Names = ["AbsTol"
         "RelTol"
         "SingularTerm"
         "FJacobian"
         "BCJacobian"
         "Stats"
         "Nmax"
         "Vectorized"
        ];

j = startsWith(Names,name,'IgnoreCase',true);
if ~any(j)               % if no matches
    error(message('MATLAB:bvpget:InvalidPropName', name));
elseif sum(j) > 1        % if more than one match
    % No names are subsets of others, so there will be no exact match
    matches = join(Names(j),', ');
    error(message('MATLAB:bvpget:AmbiguousPropName',name,matches));
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
