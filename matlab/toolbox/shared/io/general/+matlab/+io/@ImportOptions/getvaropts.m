function vopts = getvaropts(opts,selection)
arguments
    opts(1,1) matlab.io.ImportOptions
    selection = ':';
end
if islogical(selection)
    selection = find(selection);
end
selection = matlab.io.internal.validators.validateCellStringInput(selection, 'NAMES');
vopts = opts.fast_var_opts.getVarOpts(opts.fast_var_opts.fixSelection(selection));
end
% Copyright 2016-2023 The MathWorks, Inc.