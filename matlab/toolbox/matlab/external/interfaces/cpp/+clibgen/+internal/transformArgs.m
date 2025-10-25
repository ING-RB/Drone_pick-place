function [trans_args, trans_out] = transformArgs(initial_args, initial_output)
% transform inputs and outputs to construct final MATLAB signature

%   Copyright 2018-2021 The MathWorks, Inc.

dim_info = getDimInfo(initial_args, initial_output);

initial_args = arrayfun(@clibgen.internal.modifyShape, initial_args);
initial_output = arrayfun(@clibgen.internal.modifyShape, initial_output);

[trans_args, trans_out] = transform(initial_args, initial_output, dim_info);

if isempty(trans_args)
    trans_args = struct([]);
end

if isempty(trans_out)
    trans_out = struct([]);
end
end

function dim_info = getDimInfo(i_args, i_out)
dim_info = struct([]);
x = 1;

for arg = i_args
    [MATLABName, dimensions] = helper(arg);
    if ~isempty(MATLABName)
        dim_info(x).MATLABName = MATLABName;
        dim_info(x).dimensions = dimensions;
        x = x + 1;
    end
end

[MATLABName, dimensions] = helper(i_out);
if ~isempty(MATLABName)
    dim_info(x).MATLABName = MATLABName;
    dim_info(x).dimensions = dimensions;
end

    function [MATLABName, dimensions] = helper(arg)
        MATLABName = [];
        dimensions = [];
        if ~isempty(arg) && (arg.Storage == "array" || arg.Storage == "pointer")
            MATLABName = arg.MATLABName;
            dimensions = clibgen.internal.getDimensions(arg);
        end
    end
end

function [transformed_args, transformed_output] = transform(initial_args, initial_output, dimension_info)
% **** INPUT ****
% initial_args
%   MATLABName  string
%   MATLABType  string
%   Direction   "input", "output", or "inputoutput"
%   Shape       "scalar", "array", or "nullTerminated"
%   Storage "pointer", "array", "reference" or "value"
%
% initial_output
%   MATLABName  string
%   MATLABType  string
%   Shape       "scalar", "array", or "nullTerminated"
%   Storage "pointer", "array", "reference", or "value"
%
% dimension_info
%   MATLABName  string - array or pointer parameter name
%   dimensions  struct vector
%       type        "value" or "parameter"
%       value       value or MATLABName (ex. "4", "12", "rows", "len")
%
% **** OUTPUT ****
% transformed_args
%   MATLABName  string
%   MATLABType  string
%   Direction   "input", "output", or "inputoutput"
%   Shape       "scalar", "array", or "nullTerminated"
%   Storage "pointer", "array", "reference" or "value"
%   Dimensions  struct vector
%       type        "value" or "parameter"
%       value       value or MATLABName (ex. "4", "12", "rows", "len")
%       MATLABType  (if type == "parameter") string
%       Direction   (if type == "parameter") "input", "output", or "inputoutput"
%       Shape       (if type == "parameter") "scalar", "array", or "nullTerminated"
%       Storage "pointer", "array", "reference" or "value"
% transformed_output
%   MATLABName  string
%   MATLABType  string
%   Shape       "scalar", "array", or "nullTerminated"
%   Storage "pointer", "array", "reference" or "value"
%   Dimensions  struct vector
%       type        "value" or "parameter"
%       value       value or MATLABName (ex. "4", "12", "rows", "len")
%       MATLABType  (if type == "parameter") string
%       Direction   (if type == "parameter") "input", "output", or "inputoutput"
%       Shape       (if type == "parameter") "scalar", "array", or "nullTerminated"
%       Storage "pointer", "array", "reference" or "value"

% if a dimension paremeter is for an 'input' or 'inputoutput' array, the
% dimension value is implicitly given by the array and shouldn't appear in
% the MATLAB signature.
hidden_parameters = []; % parameters which don't appear in MATLAB signature
for dim_info = dimension_info
    % search the initial arguments for an argument with dimensions
    idx = find(arrayfun(@(s) strcmp(s.MATLABName, dim_info.MATLABName), initial_args));
    if isempty(idx)
        % output struct is not in initial_args
        continue;
    end
    direction = initial_args(idx).Direction;
    if strcmp(direction, 'input') || strcmp(direction, 'inputoutput')
        for dim = dim_info.dimensions
            if strcmp(dim.type, "parameter")
                hidden_parameters = [hidden_parameters dim.value]; %#ok<AGROW>
            end
        end
    end
end

% construct transformed arguments
transformed_args = [];
for an_arg = initial_args
    MATLABName = an_arg.MATLABName;
    
    % is the argument hidden?
    if ~isempty(hidden_parameters(strcmp(hidden_parameters,MATLABName)))
        an_arg.IsHidden = true;
    end
    
    % add dimensions irrespective of whether hidden or not, in case the
    % dimension itself is a pointer type and its own dimensions
    % merge dimension information
    an_arg.dimensions = constructDimensions(an_arg, initial_args, dimension_info);

    % transform NumElementsInBuffer
    if isfield(an_arg, 'BufferSize') && ~isempty(an_arg.BufferSize)
        an_arg_bufferSize.Shape = "array";
        an_arg_bufferSize.MATLABName = MATLABName;
        dimension_info_bufferSize.MATLABName = MATLABName;
        dimension_info_bufferSize.dimensions.value = an_arg.BufferSize;
        if ischar(an_arg.BufferSize) || isstring(an_arg.BufferSize)
            dimension_info_bufferSize.dimensions.type = "parameter";
        else
            dimension_info_bufferSize.dimensions.type = "value";
        end
        an_arg.BufferSize = constructDimensions(an_arg_bufferSize, initial_args, dimension_info_bufferSize);
    end

    transformed_args = [transformed_args an_arg]; %#ok<AGROW>
end

% construct transformed output
transformed_output = [];
for an_arg = initial_output
    an_arg.dimensions = constructDimensions(an_arg, initial_args, dimension_info);
    transformed_output = [transformed_output an_arg]; %#ok<AGROW>
end
end

% utility function: construct a dimension information
function dims = constructDimensions(an_arg, i_args, dimension_info)
if ~strcmp(an_arg.Shape, "array")
    dims = [];
    return;
end

f_search = @(search_in) find(arrayfun(@(s) strcmp(s.MATLABName, an_arg.MATLABName), search_in));
d_idx = f_search(dimension_info);
if isempty(d_idx)
    dims = [];
else
    dims = dimension_info(d_idx).dimensions;
    
    % if a dimension is a parameter, need the information about the
    % parameter
    for d_idx = 1:numel(dims)
        if strcmp(dims(d_idx).type, 'parameter')
            % if dimension is a method or data member
            for i_idx = 1:numel(an_arg)
               if isfield(an_arg(i_idx),'MemberOrMethodDims')
                  memberDims = an_arg(i_idx).MemberOrMethodDims;
                  dimStruct = memberDims(arrayfun(@(x) strcmp(x.dimName, dims(d_idx).value), memberDims));
                  if not(isempty(dimStruct))
                     dims(d_idx).MATLABType = dimStruct.mwType;
                     dims(d_idx).CppPosition = dimStruct.cppPosition;
                     dims(d_idx).DimType = dimStruct.dimType;
                     dims(d_idx).Storage = dimStruct.storage;
                     break;
                  end
               end
            end
              
            for i_idx = 1:numel(i_args)
               if strcmp(dims(d_idx).value, i_args(i_idx).MATLABName)
                   % sets values if dimension is method's input arguments
                   dims(d_idx).MATLABType = i_args(i_idx).MATLABType;
                   dims(d_idx).Shape = i_args(i_idx).Shape;
                   dims(d_idx).Storage = i_args(i_idx).Storage;
                   dims(d_idx).CppPosition = i_args(i_idx).CppPosition;
                   dims(d_idx).DimType = "Parameter";
                   if isfield(i_args(i_idx), 'Direction')
                       % output struct for return doesn't have 'Direction'
                       dims(d_idx).Direction = i_args(i_idx).Direction;
                       break;
                   end
               end
            end
        end
    end
  end
end
