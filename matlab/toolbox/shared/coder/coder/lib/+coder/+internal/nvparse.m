function [s,userSupplied,firstParm] = nvparse(parms,varargin)
%MATLAB Code Generation Private Function
%   coder.internal.nvparse is an easy-to-use function for name-value
%   parsing consistent with PRISM standards of partial matching and case
%   insensitivity.
%
%   The first input to coder.internal.nvparse can be either a cell array of
%   parameter names or a struct with field names that are the parameter
%   names and values that are the default values. When the first input is a
%   cell array, the default value for all parameters is taken to be [].
%
%   In MATLAB the output is a struct. For code generation targets it is a
%   constant-preserving struct object (see
%   coder.internal.constantPreservingStruct).
%
%   The second output, userSupplied, is a constant struct having the same
%   field names but with logical values that indicate whether the user has
%   supplied the given parameter or not, true for user-supplied inputs,
%   false when defaults have been used.
%
%   If the third output is requested, coder.internal.nvparse will search
%   forward in varargin{:} to find the first partial or exact match of a
%   constant text input with any of the parameter names. Name-Value pairs
%   are parsed from varargin{firstParm:end}. No errors are issued on
%   account of the unrecognized leading inputs, varargin{1:firstParm-1}.
%   These inputs can then be parsed by other means as desired. When no
%   parameter names are detected, firstParm = length(varargin) + 1.
%
%   Example 1:
%       parms = {'AbsTol','RelTol'};
%       s = coder.internal.nvparse(parms,varargin{:});
%
%       When the user-supplied varargin is {'abs',1e-3}, then
%
%       s.AbsTol will be 1e-3,
%       s.RelTol will be []
%
%   Example 2:
%       parms.AbsTol = 1e-6;
%       parms.RelTol = 1e-4;
%       [s,u,firstParm] = coder.internal.nvparse(parms,varargin{:});
%
%       % When
%       varargin = {'Econ',2,'ignore','abs',1e-3};
%       % s.AbsTol will be 1e-3,
%       % s.RelTol will be 1e-4,
%       % u.AbsTol will be true,
%       % u.RelTol will be false, and
%       % firstParm = 4.
%       % The leading inputs, varargin{1:firstParm-1}, have not been
%       % parsed. Suppose some of these might be flags. Then we might do:
%
%       flags = {'IncludeNaN','IgnoreNaN','Econ'};
%       [f,info] = coder.internal.parseConstantFlags(flags,varargin{1:firstParm-1});
%
%       % f.IncludeNaN will be false,
%       % f.IgnoreNaN will be true, and
%       % f.Econ will be true.
%       % info.nonFlagInputs will be [2], so we might follow up with
%
%       if ~isempty(info.nonFlagInputs)
%           dim = varargin{info.nonFlagInputs(1)};
%       end
%
%   coder.internal.nvparse uses coder.internal.parseInputs and
%   coder.internal.vararginToStruct. The precise option settings used with
%   coder.internal.parseInputs are
%
%     poptions = struct( ...
%         'CaseSensitivity',false, ...
%         'PartialMatching','unique', ...
%         'StructExpand',false, ...
%         'IgnoreNulls',false, ...
%         'SupportOverrides',false);
%
%   See help coder.internal.parseInputs for more information on these
%   options.

%   Copyright 2021 The MathWorks, Inc.
%#codegen

narginchk(1,inf);
coder.internal.allowHalfInputs;
coder.internal.allowEnumInputs;
if isstruct(parms)
    names = fieldnames(parms);
    defaults = parms;
else
    names = parms;
    defaults = [];
end
poptions = struct( ...
    'CaseSensitivity',false, ...
    'PartialMatching','unique', ...
    'StructExpand',false, ...
    'IgnoreNulls',false, ...
    'SupportOverrides',false);
if nargout <= 2
    firstParm = 1;
else
    firstParm = coder.const(findFirstParameterName(names,varargin{:}));
end
pstruct = coder.internal.parseInputs({},names,poptions, ...
    varargin{firstParm:end});
s = coder.internal.vararginToStruct(pstruct,defaults, ...
    varargin{firstParm:end});
if nargout >= 2
    userSupplied = coder.const(logicalValuesStruct(pstruct));
end

%--------------------------------------------------------------------------

function p = logicalValuesStruct(pstruct)
names = fieldnames(pstruct);
coder.unroll;
for k = 1:numel(names)
    p.(names{k}) = logical(pstruct.(names{k}));
end

%--------------------------------------------------------------------------

function k = findFirstParameterName(names,varargin)
% The default return value is k = length(varargin) + 1 so that
% varargin{k:end} is empty.
k = nargin;
coder.unroll;
for idx = 1:nargin - 1
    if coder.const(coder.internal.isConst(varargin{idx}) && k == nargin)
        if coder.const(findFlag(names,varargin{idx}) > 0)
            k = idx;
        end
    end
end

%--------------------------------------------------------------------------
