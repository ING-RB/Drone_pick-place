function checkForMissingOutputArgument(params, num_output_args)
% If input image is indexed and the colormap option is optimized, the user
% should be calling the function with two output arguments in order to
% capture the new, optimized colormap.  If the user did not use two output
% arguments, issue a warning message.

% Copyright 2020 The MathWorks, Inc.

if matlab.images.internal.resize.isInputIndexed(params) && strcmp(params.colormap_method, 'optimized') && ...
        (num_output_args < 2)

    warning(message('MATLAB:images:imresize:missingOutputArg'))
end
