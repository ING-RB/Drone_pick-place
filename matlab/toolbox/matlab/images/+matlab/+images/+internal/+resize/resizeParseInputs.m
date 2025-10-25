function params = resizeParseInputs(varargin)
% Parse the input arguments, returning the resulting set of parameters
% as a struct for imresize

% Copyright 2020-2021 The MathWorks, Inc.

narginchk(1, Inf);

% Set parameter defaults.
params.kernel = @matlab.images.internal.resize.cubic;
params.kernel_width = 4;
params.antialiasing = [];
params.colormap_method = 'optimized';
params.dither_option = 'dither';
params.num_dims = 2; % This parameter is used to distinguish between 
                     % imresize and imresize3. It is 2 for imresize and 3 
                     % for imresize3.  This way, some methods can be 
                     % generalized for both functions.
params.size_dim = []; % If user specifies NaN for an output size, this
                      % parameter indicates the dimension for which the
                      % size was specified.

method_arg_idx = findMethodArg(varargin{:});

first_param_string_idx = matlab.images.internal.resize.findFirstParamString(varargin, method_arg_idx);

[params.A, params.inputCategories, params.map, params.scale, params.output_size] = ...
    parsePreMethodArgs(varargin, method_arg_idx, first_param_string_idx);

% gpuArray imresize does not support categorical input
if isa(params.A, 'gpuarray')
    if(iscategorical(A))
        error(message('MATLAB:images:imresize:unsupportedCategoricalSyntax'));
    end
end

if (iscategorical(params.A))
    % defaults for categorical input 
    params.kernel = @matlab.images.internal.resize.box;
    params.kernel_width = 1;
end

if ~isempty(method_arg_idx)
    [params.kernel, params.kernel_width, params.antialiasing] = ...
        parseMethodArg(varargin{method_arg_idx});
end

if (iscategorical(params.A) &&...
            func2str(params.kernel) == "matlab.images.internal.resize.box")
    % antialiasing defaults for categorical input 
    params.antialiasing = false;
end

warnIfPostMethodArgs(varargin, method_arg_idx, first_param_string_idx);

params = parseParamValuePairs(params, varargin, first_param_string_idx);

params = fixupSizeAndScale(params);

% For categorical inputs, the interpolation method is always 'nearest' as
% other methods don't make sense. Anti-aliasing is set to false in this
% case.
if iscategorical(params.A)
    % For categorical the only valid 'Method' value is 'nearest'. The
    % default value for 'Method' is 'nearest' as well.
    nearestKernel = 'matlab.images.internal.resize.box';
    
    if(~isequal(func2str(params.kernel),nearestKernel))
        error(message('MATLAB:images:imresize:badMethodForCategorical'));
    end
    
    if(params.antialiasing == true)
        error(message('MATLAB:images:imresize:invalidAntialiasingForCategorical'));
    end
    params.antialiasing = false;
end

if isempty(params.antialiasing)
    % If params.antialiasing is empty here, that means the user did not
    % explicitly specify a method or the Antialiasing parameter.  The
    % default interpolation method is bicubic, for which the default
    % antialiasing is true.
    params.antialiasing = true;
end

end


%=====================================================================
function [A, inputCategories, map, scale, output_size] = parsePreMethodArgs(args, method_arg_idx, ...
                                                  first_param_idx)
% Parse all the input arguments before the method argument.

% Keep only the arguments before the method argument.
if ~isempty(method_arg_idx)
    args = args(1:method_arg_idx-1);
elseif ~isempty(first_param_idx)
    args = args(1:first_param_idx-1);
end

% There must be at least one input argument before the method argument.
if numel(args) < 1
    error(message('MATLAB:images:imresize:badSyntaxMissingImage'));
end

% Set default outputs.
map = [];
scale = [];
output_size = [];
inputCategories = [];

A = args{1};
validateattributes(A, {'single', ...
                       'double', ...
                       'int8', ...
                       'int16', ...
                       'int32', ...
                       'uint8', ...
                       'uint16', ...
                       'uint32', ...
                       'logical',...
                       'categorical'}, ...
                      {'nonsparse', ...
                       'nonempty'}, ...
                       mfilename, 'A', 1);
if(iscategorical(A))
    inputCategories = categories(A);
end

if numel(args) < 2
    return
end

next_arg = 2;
if size(args{next_arg},2) == 3
    % IMRESIZE(X,MAP,...)
    if(iscategorical(A))
        error(message('MATLAB:images:imresize:unsupportedCategoricalSyntax'));
    end
    map = args{next_arg};
    if isa(A, 'gpuArray')||isa(map, 'gpuArray')
        error(message('MATLAB:images:imresize:unsupportedGPUIndexedImages'));
    end
    try
        matlab.images.internal.iptcheckmap(map, mfilename, 'MAP', 2);
    catch ME
        if isequal(size(map),[1,3]) && strcmp(ME.identifier,'MATLAB:images:validate:badMapValues')
            error(message('MATLAB:images:imresize:invalidOutputSize'));
        else
            throw(ME);
        end
    end
    next_arg = next_arg + 1;
end

if next_arg > numel(args)
    return
end

next = args{next_arg};

% The next input argument must either be the scale or the output size.
[scale, output_size] = scaleOrSize(next, next_arg);
next_arg = next_arg + 1;

if next_arg <= numel(args)
    error(message('MATLAB:images:imresize:badSyntaxUnrecognizedInput', next_arg));
end

end

%=====================================================================
function idx = findMethodArg(varargin)
% Find the location of the method argument, if it exists, before the
% param-value pairs.  If not found, return [].

idx = [];
for k = 1:nargin
    arg = varargin{k};
    if ischar(arg)
        if isMethodString(arg)
            idx = k;
            break;
            
        else
            % If this argument is a string but is not a method string, it
            % must be a parameter string.
            break;
        end
        
    elseif iscell(arg)
        idx = k;
        break;
    end
end

end


%=====================================================================
function [scale, output_size] = scaleOrSize(arg, position)
% Determine whether ARG is the scale factor or the output size.

scale = [];
output_size = [];

if isnumeric(arg) && isscalar(arg)
    % Argument looks like a scale factor.
    validateattributes(arg, {'numeric'}, {'nonzero', 'real'}, mfilename, ...
        'SCALE', position);
    scale = double(arg);

elseif isnumeric(arg) && isvector(arg) && (numel(arg) == 2)
    % Argument looks like output_size.
    validateattributes(arg, {'numeric'}, {'vector', 'real', 'positive'}, ...
                  mfilename, '[MROWS NCOLS]', position);
    output_size = double(arg);
    
else
    error(message('MATLAB:images:imresize:badScaleOrSize'));
end

end

%=====================================================================
function [kernel, kernel_width, antialiasing] = parseMethodArg(method)
% Return the kernel function handle and kernel width corresponding to
% the specified method.

[valid_method_names, method_kernels, kernel_widths] = getMethodInfo();

antialiasing = true;

if ischar(method)
    % Replace validatestring here as an optimization. -SLE, 31-Oct-2006
    idx = find(strncmpi(method, valid_method_names, numel(method)));

    switch numel(idx)
      case 0
        error(message('MATLAB:images:imresize:unrecognizedMethodString', method));
        
      case 1
        kernel = method_kernels{idx};
        kernel_width = kernel_widths(idx);
        if strcmp(valid_method_names{idx}, 'nearest')
            antialiasing = false;
        end
        
      otherwise
        error(message('MATLAB:images:imresize:ambiguousMethodString', method));
    end
    
else
    % Cell-array form
    kernel = method{1};
    kernel_width = method{2};
end

end


%=====================================================================
function warnIfPostMethodArgs(args, method_arg_idx, first_param_string_idx)
% If there are arguments between the method argument and the first
% parameter string, these must be old-style antialiasing syntaxes that
% are no longer supported.  Issue a warning message.  Note that
% either method_arg_idx and first_param_string_idx may be empty.

if isempty(method_arg_idx)
    method_arg_idx = numel(args) + 1;
end

if isempty(first_param_string_idx)
    first_param_string_idx = numel(args) + 1;
end

if (first_param_string_idx - method_arg_idx) > 1
    warning(message('MATLAB:images:imresize:oldSyntaxesIgnored', ...
        'N and H are now ignored in the old syntaxes IMRESIZE(...,method,N) and IMRESIZE(...,method,H).', ...
        'Use IMRESIZE_OLD if you need the previous behavior.'));
end

end


%=====================================================================
function params = parseParamValuePairs(params_in, args, first_param_string)

params = params_in;

if isempty(first_param_string)
    return
end

if rem(numel(args) - first_param_string, 2) == 0
    error(message('MATLAB:images:imresize:oddNumberArgs'));
end

% Originally implemented valid_params and param_check_fcns as a
% structure which was accessed using dynamic field reference.  Changed
% to separate cell arrays as a performance optimization. -SLE,
% 31-Oct-2006
valid_params = {'Scale', ...
                'Colormap', ...
                'Dither', ...
                'OutputSize', ...
                'Method', ...
                'Antialiasing'};

param_check_fcns = {@processScaleParam, ...
                    @processColormapParam, ...
                    @processDitherParam, ...
                    @processOutputSizeParam, ...
                    @processMethodParam, ...
                    @matlab.images.internal.resize.processAntialiasingParam};

for k = first_param_string:2:numel(args)
    param_string = args{k};
    if ~ischar(param_string)
        error(message('MATLAB:images:imresize:expectedParamString', k));
    end
                  
    idx = find(strncmpi(param_string, valid_params, numel(param_string)));
    num_matches = numel(idx);
    if num_matches == 0
        error(message('MATLAB:images:imresize:unrecognizedParamString', param_string));
    
    elseif num_matches > 1
        error(message('MATLAB:images:imresize:ambiguousParamString', param_string));
        
    else
        check_fcn = param_check_fcns{idx};
        params = check_fcn(args{k+1}, params);

    end
end

end

%=====================================================================
function params = fixupSizeAndScale(params_in)
% If the scale factor was specified as a scalar, turn it into a
% params.num_dims element vector.  If the scale factor wasn't specified,
% derive it from the specified output size.
%
% If the output size has NaN(s) in it, fill in the value(s)
% automatically. If the output size wasn't specified, derive it from
% the specified scale factor.

params = params_in;

if isempty(params.scale) && isempty(params.output_size)
    error(message('MATLAB:images:imresize:missingScaleAndSize'));
end

% If the input is a scalar, turn it into a params.num_dims element vector.
if ~isempty(params.scale) && isscalar(params.scale)
    params.scale = repmat(params.scale, 1, params.num_dims);
end

[params.output_size, params.size_dim] = fixupSize(params);

if isempty(params.scale)
    params.scale = matlab.images.internal.resize.deriveScaleFromSize(params);
end

if isempty(params.output_size)
    params.output_size = matlab.images.internal.resize.deriveSizeFromScale(params);
end

end


%=====================================================================
function params = processScaleParam(arg, params_in)

valid = isnumeric(arg) && ...
    ((numel(arg) == 1) || (numel(arg) == params_in.num_dims)) && ...
    all(arg > 0);

if ~valid
    error(message('MATLAB:images:imresize:invalidScale'));
end

params = params_in;
params.scale = arg;

end


%=====================================================================
function params = processColormapParam(arg, params_in)

valid = ischar(arg) && (strcmp(arg, 'optimized') || strcmp(arg, 'original'));
if ~valid
    error(message('MATLAB:images:imresize:badColormapOption'));
end

if iscategorical(params_in.A)
    error(message('MATLAB:images:imresize:unsupportedNVPairForCategorical','Colormap'));
end
params = params_in;
params.colormap_method = arg;

end


%=====================================================================
function params = processDitherParam(arg, params_in)

valid = (isnumeric(arg) || islogical(arg)) && isscalar(arg);
if ~valid
    error(message('MATLAB:images:imresize:badDitherOption'));
end
if iscategorical(params_in.A)
    error(message('MATLAB:images:imresize:unsupportedNVPairForCategorical','Dither'));
end
params = params_in;
if arg
    params.dither_option = 'dither';
else
    params.dither_option = 'nodither';
end

end


%=====================================================================
function params = processOutputSizeParam(arg, params_in)

valid = isnumeric(arg) && ...
    (numel(arg) == params_in.num_dims) && ...
    all(isnan(arg) | (arg > 0));
if ~valid
    error(message('MATLAB:images:imresize:badOutputSize'));
end

params = params_in;
params.output_size = arg;

end

%=====================================================================
function params = processMethodParam(arg, params_in)

valid = isMethodString(arg) || isMethodCell(arg);
if ~valid
    error(message('MATLAB:images:imresize:badMethod'));
end

params = params_in;
[params.kernel, params.kernel_width, antialiasing] = parseMethodArg(arg);

if iscategorical(params_in.A) &&...
            ~isequal(func2str(params.kernel),'matlab.images.internal.resize.box') 
    error(message('MATLAB:images:imresize:badMethodForCategorical'));
end

if isempty(params.antialiasing)
    % Antialiasing hasn't been set explicitly in the input arguments
    % parsed so far, so set it according to what parseMethodArg
    % returns.
    params.antialiasing = antialiasing;
end   

end

%=====================================================================
function tf = isMethodCell(in)
% True of the input argument is a two-element cell array containing a
% function handle and a numeric scalar.

tf = iscell(in) && ...
     numel(in) == 2 && ...
     isa(in{1}, 'function_handle') && ...
     isnumeric(in{2}) && ...
     isscalar(in{2});

end

%=====================================================================
function tf = isMethodString(in)
% Returns true if the input is the name of a method.

if ~ischar(in)
    tf = false;
    
else
    valid_method_strings = getMethodInfo();

    num_matches = sum(strncmpi(in, valid_method_strings, numel(in)));
    tf = num_matches == 1;
end

end

%=====================================================================
function [names,kernels,widths] = getMethodInfo

% Original implementation of getMethodInfo returned this information as
% a single struct array, which was somewhat more readable. Replaced
% with three separate arrays as a performance optimization. -SLE,
% 31-Oct-2006
names = {'nearest', ...
         'bilinear', ...
         'bicubic', ...
         'box', ...
         'triangle', ...
         'cubic', ...
         'lanczos2', ...
         'lanczos3'};

kernels = {@matlab.images.internal.resize.box, ...
           @matlab.images.internal.resize.triangle, ...
           @matlab.images.internal.resize.cubic, ...
           @matlab.images.internal.resize.box, ...
           @matlab.images.internal.resize.triangle, ...
           @matlab.images.internal.resize.cubic, ...
           @matlab.images.internal.resize.lanczos2, ...
           @matlab.images.internal.resize.lanczos3};

widths = [1.0 2.0 4.0 1.0 2.0 4.0 4.0 6.0];

end

%=====================================================================
function [output_size, size_dim] = fixupSize(params)
% If params.output_size has a NaN in it, calculate the appropriate
% value to substitute for the NaN.

output_size = params.output_size;
size_dim = [];

if ~isempty(output_size)
    if ~all(output_size)
        error(message('MATLAB:images:imresize:zeroOutputSize'));
    end
    
    if all(isnan(output_size))
        error(message('MATLAB:images:imresize:allNaN'));
    end
    
    if isnan(output_size(1))
        output_size(1) = params.output_size(2) * size(params.A, 1) / ...
            size(params.A, 2);
        size_dim = 2;   
    elseif isnan(output_size(2))
        output_size(2) = params.output_size(1) * size(params.A, 2) / ...
            size(params.A, 1);
        size_dim = 1;    
    end
    
    output_size = ceil(output_size);
end

end
