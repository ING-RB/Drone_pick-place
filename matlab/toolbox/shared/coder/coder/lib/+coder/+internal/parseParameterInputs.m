function pstruct = parseParameterInputs(parms,options,varargin)
%MATLAB Code Generation Private Function
%
%   Processes varargin for parameter name-value pairs and option structure
%   inputs. This function works both in MATLAB and in code generation.
%   The first input, PARMS, must be a cell array of string scalars
%   (or a struct with field names corresponding to all valid parameters).
%   The return value PSTRUCT is such a structure. The 'uint32' values
%   returned in it are used to look up the corresponding parameter values
%   in varargin{:}. To retrieve a parameter value, use
%   coder.internal.getParameterValue. For example, to retrieve the
%   parameter AbsTol, you might write
%
%       abstol = coder.internal.getParameterValue(pstruct.abstol,1e-5,varargin{:})
%
%   where 1e-5 is the default value for AbsTol in case it wasn't specified
%   by the user.
%
%   The options input must be [] or a structure with any of the fields
%       1. CaseSensitivity
%          true    --> case-sensitive name comparisons.
%          false   --> case-insensitive name comparisons (the default).
%       2. StructExpand
%          true    --> expand structs as sequences of parameter name-value
%                      pairs (the default).
%          false   --> structs not expanded and will generate an error.
%       3. PartialMatching
%          'none'  --> parameter names must match in full (the default).
%          'first' --> parameter names match if they match in all the
%                      characters supplied by the user. There is no
%                      validation of the parameter name set for
%                      suitability. If more than one match is possible, the
%                      first is used. If a preference should be given to an
%                      exact match, sort the fields of parms so that the
%                      shortest possible partial match will always be the
%                      first partial match.
%          'unique'--> Same as 'first' except that if there are no exact
%                      matches, any partial matches must be unique. An
%                      error will be thrown if there are no exact matches
%                      and there is more than one partial match.
%          true    --> Legacy input. Same as 'first'.
%          false   --> Legacy input. Same as 'none'.
%       4. IgnoreNulls
%          true    --> A fixed-size, constant value [] is treated as if the
%                      corresponding parameter were not supplied at all.
%          false   --> Values of [] are treated like any other value input
%                      (the default).
%       5. SupportOverrides
%          true    --> Name-value pairs can be supplied arbitrarily many
%                      times. Only the last one matters. (the default)
%          false   --> A name-value pair can only be supplied once (even if
%                      IgnoreNulls is true and the value is []).
%
%   The maximum number of parameter names is 65535.
%   The maximum length of VARARGIN{:} is also 65535.
%
%   Example:
%
%   Parse a varargin list for parameters 'tol', 'method', and 'maxits',
%   where 'method' is a required parameter. Struct input is not
%   permitted, and case-insensitive partial matching is done. Overrides are
%   not supported (any name-value pair can be supplied at most once).
%
%       % Define the parameter names either using a struct
%       parms = struct( ...
%           'tol',uint32(0), ...
%           'method',uint32(0), ...
%           'maxits',uint32(0));
%       % or a constant cell array.
%       parms = {'tol','method','maxits'};
%       % Select parsing options.
%       poptions = struct( ...
%           'CaseSensitivity',false, ...
%           'PartialMatching','unique', ...
%           'StructExpand',false, ...
%           'IgnoreNulls',true, ...
%           'SupportOverrides',false);
%       % Parse the inputs.
%       pstruct = coder.internal.parseParameterInputs(parms,poptions,varargin{:});
%       % Retrieve parameter values.
%       tol = coder.internal.getParameterValue(pstruct.tol,1e-5,varargin{:});
%       coder.internal.assert(pstruct.method ~= 0,'tbx:foo:MethodRequired');
%       method = coder.internal.getParameterValue(pstruct.method,[],varargin{:});
%       maxits = coder.internal.getParameterValue(pstruct.maxits,1000,varargin{:});

%   Copyright 2009-2021 The MathWorks, Inc.
%#codegen

narginchk(2,inf);
if isempty(coder.target)
    pstruct = parseParameterInputsML({},parms,options,varargin);
else
    coder.inline('always');
    coder.internal.allowHalfInputs;
    coder.internal.allowEnumInputs;
    coder.internal.prefer_const(parms,options);
    pstruct = coder.const(parseParameterInputsCG({},parms,options,varargin{:}));
end
