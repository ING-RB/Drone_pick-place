function sliced_type_check(varargin)
% This function is undocumented and reserved for internal use.  It may be
% removed in a future release.

% Copyright 2009-2023 The MathWorks, Inc.

    for idx = 1:2:numel(varargin)
        if isa(varargin{idx+1}, 'function_handle')
            error(message('MATLAB:parfor:sliced_function_handle', ...
                           varargin{idx}, varargin{idx}, ...
                           doclink('/toolbox/parallel-computing/distcomp_ug.map', 'ERR_PARFOR_FCNHDL_CHECK', ...
                                   'Parallel Computing Toolbox, "parfor"')))
        end
        if isa(varargin{idx+1}, 'dictionary')
            error(message('MATLAB:parfor:sliced_dictionary', ...
                varargin{idx}, ...
                doclink('/toolbox/parallel-computing/distcomp_ug.map', 'SLICED_VARIABLES', ...
                'parfor-Loops in MATLAB, "Sliced Variables"')))
        end
        if isa(varargin{idx+1}, 'Composite')
            error(message('MATLAB:parfor:InvalidComposite'));
        end
    end
end
