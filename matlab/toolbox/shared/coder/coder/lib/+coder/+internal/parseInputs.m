function [pstruct,unmatched] = parseInputs(opArgs,NVPairNames,options,varargin)
%MATLAB Code Generation Private Function
%
%   Processes varargin for optional inputs, parameter name-value pairs, and
%   option structure inputs. This function works both in MATLAB and in code
%   generation.
%
%   INPUTS
%
%   opArgs   Define variable names for optional input arguments. The opArgs
%            input can be a cellstr, a cell of string scalars, or a struct.
%            Optional inputs are the inputs in varargin prior to the first
%            (constant) member of NVPairNames present in varargin, if any.
%            Note that a member of NVPairNames is recognized as such using
%            the partial matching and case sensitivity options provided, so
%            when using partial matching, beware of optional "flag" input
%            arguments that are partial matches with one or more
%            NVPairNames. That is not supported.
%            * If opArgs is a cellstr or cell array of string scalars
%              (string arrays are not currently supported), the entries
%              define the optional variable names. Optional inputs are
%              matched to these variable names in order, left-to-right.
%            * If opArgs is a struct, the fieldnames of the struct define
%              the optional argument variable names. The value for each
%              field should be a function handle f such that f(x) returns a
%              constant true or false indicating whether the input argument
%              x should be matched with the corresponding field name, i.e.
%              x can be matched with the optional input argument varname if
%              opArgs.varname(x) returns constant true. It must be
%              emphasized that only a CONSTANT true results in a match. If
%              opArgs.varname(x) returns false or is not constant, then the
%              next field is tested. If any of the subsequent fields match,
%              the skipped-over optional argument variable names will not
%              be matched and will be considered "not supplied".
%
%   NVPairNames is a cellstr or a cell array of string scalars. It defines
%              the parameter names of name-value pairs.
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
%          'none'  --> names must match in full (the default).
%          'first' --> names match if they match in all the
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
%   * The maximum number of combined optional argument and parameter names
%     is 65535.
%   * The maximum length of VARARGIN{:} is also 65535.
%   * If an input is redundant, the last instance overrides the previous
%     ones. A limitation is that there is no way to perform validation of
%     overridden inputs. They are completely ignored.
%
%   OUTPUT
%
%   The pstruct output is a structure. Its fieldnames are the combined
%   optional argument names and name-value pair parameter names. Each field
%   is a uint32 defining where in varargin to find that input if it was
%   supplied. The field is zero if that input was not supplied. If the
%   StructExpand option is used and that variable is defined inside an
%   options structure input, then the field encodes two uint16 values used
%   by coder.internal.getParameterValue to find that value. Each parameter
%   can be returned from varargin by a separate call to
%   coder.internal.getParameterValue. Alternatively,
%   coder.internal.vararginToStruct can be used to fetch all input values
%   in one step, returning a struct.
%
%   It is possible to parse in a hierarchical or sequential fashion,
%   where the allowed name-value pairs depend on constant-folded at
%   earlier parsing stages:
%
%   [pstruct,unmatched] = coder.internal.parseInputs({},names1,poptions,varargin{:});
%
%   Then examine the results of this parsing step and supply different
%   parameter names for further parsing:
%
%   pstruct2 = coder.internalparseInputs({},names2,poptions,varargin{unmatched});
%
%   The unmatched output is a logical array for varargin that is true for
%   unmatched entries and their adjacent values.
%   * RECOMMENDATION 1: Be careful when combining optional argument parsing
%       with use of the unmatched feature. It must be possible to infer
%       the difference between an optional input and the first parameter
%       name. If the first parameter name is unmatched, it might be
%       consumed as an optional input when fewer optional inputs are
%       provided than is possible. Specifying optional inputs to the
%       parser with a struct and appropriate "match" functions might
%       design around the issue.
%   * RECOMMENDATION 2: Do not combine StructExpand=true with use of the
%       unmatched output. There is no support for unmatched fields, only
%       unmatched inputs. You can have structs to be expanded in
%       varargin, but be aware that an error will be issued if any fields
%       do not match the provided parameter names.
%
%   Example:
%
%   A function FOO is defined as function y = foo(x,varargin). It accepts
%   an optional dim input and an optional string or char array flag that
%   can be either 'alpha' or 'beta'. Possible name-value pair inputs are
%  'tol', 'method', and 'maxits', where 'method' is a required parameter.
%   Struct expansion is not permitted, and unique case-insensitive partial
%   matching is done. Overrides are not supported (any parameter can only
%   be supplied once).
%
%   function [dim,flag,tol,method,maxits] = fooParseInputs(x,varargin)
%   % Define optional arguments.
%   opArgs.dim = @(d)isnumeric(d);
%   opArgs.flag = @(d)coder.internal.isTextRow(d);
%   % Define the parameter names.
%   NVPairNames = {'tol','method','maxits'};
%   % Select parsing options.
%   poptions = struct( ...
%       'CaseSensitivity',false, ...
%       'PartialMatching','unique', ...
%       'StructExpand',false, ...
%       'IgnoreNulls',true, ...
%       'SupportOverrides',false);
%   % Parse the inputs.
%   pstruct = coder.internal.parseInputs(opArgs,NVPairNames,poptions,varargin{:});
%   % Retrieve input values.
%   defaultDim = coder.internal.constNonSingletonDim(x);
%   dim = coder.internal.getParameterValue(pstruct.dim,defaultDim,varargin{:});
%   flag = coder.internal.getParameterValue(pstruct.flag,'alpha',varargin{:});
%   tol = coder.internal.getParameterValue(pstruct.tol,1e-5,varargin{:});
%   coder.internal.assert(pstruct.method ~= 0,'tbx:foo:MethodRequired');
%   method = coder.internal.getParameterValue(pstruct.method,[],varargin{:});
%   maxits = coder.internal.getParameterValue(pstruct.maxits,1000,varargin{:});
%
%   % We can return a structure instead of individual values:
%
%   function s = fooParseInputs(x,varargin)
%   opArgs.dim = @(d)isnumeric(d);
%   opArgs.flag = @(d)coder.internal.isTextRow(d);
%   NVPairNames = {'tol','method','maxits'};
%   poptions = struct( ...
%       'CaseSensitivity',false, ...
%       'PartialMatching','unique', ...
%       'StructExpand',false, ...
%       'IgnoreNulls',true, ...
%       'SupportOverrides',false);
%   pstruct = coder.internal.parseInputs(opArgs,NVPairNames,poptions,varargin{:});
%   % Define default values in case some parameters are not supplied. An
%   % alternative to defining a structure of default values is to use [] as
%   % the default value for all unsupplied parameters.
%   default.dim = coder.internal.constNonSingletonDim(x);
%   default.flag = 'alpha';
%   default.tol = 1e-5;
%   default.method = [];
%   default.maxits = 1000;
%   s = coder.internal.vararginToStruct(pstruct,default,varargin{:});

%   Copyright 2009-2022 The MathWorks, Inc.
%#codegen

narginchk(3,inf);
if isempty(coder.target)
    if nargout > 1
        [pstruct,unmatched] = parseParameterInputsML( ...
            opArgs,NVPairNames,options,varargin);
    else
        pstruct = parseParameterInputsML( ...
            opArgs,NVPairNames,options,varargin);
    end
else
    coder.inline('always');
    coder.internal.allowHalfInputs;
    coder.internal.allowEnumInputs;
    coder.internal.prefer_const(opArgs,NVPairNames,options);
    if nargout > 1
        [pstruct,unmatched] = coder.const(@parseParameterInputsCG, ...
            opArgs,NVPairNames,options,varargin{:});
    else
        pstruct = coder.const(parseParameterInputsCG( ...
            opArgs,NVPairNames,options,varargin{:}));
    end
end
