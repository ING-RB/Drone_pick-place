classdef FixedWidthInputs < matlab.io.internal.FunctionInterface
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    properties (Parameter)
        %PARTIALFIELDRULE what to do with fields that end before matching the requested width
        %   PARTIALFIELDRULE determines what happens when a field contains fewer characters
        %   than the requested width before a line ending is found.
        %
        %      'keep' - Keep the partial field data and convert the text to the appropriate
        %               datatype. This may result in a conversion error
        %
        %      'fill' - replace the partial data with the contents of 'FillValue'
        %
        %   'omitrow' - Rows where partial data occur will not be imported.
        %
        %   'omitvar' - Variables where partial data occur will not be imported.
        %
        %      'wrap' - Begin reading the next line of characters
        %
        %     'error' - Error during import and abort the operation
        PartialFieldRule = 'keep';
    end
    properties (Parameter, Dependent)
        %VARIABLEWIDTHS Number of characters to read for each variable
        %   VARIABLEWIDTHS must be a vector of positive integer values with the same number
        %   of elememts as the object's VariableNames property.
        VariableWidths
    end
    
    properties (Access = protected)
        widths_ = 1;
    end
    methods
        function opts = set.PartialFieldRule(opts,rhs)
        opts.PartialFieldRule = validatestring(rhs,{'keep','omitrow','omitvar','fill','wrap','error'});
        end
        
        function opts = set.VariableWidths(opts,rhs)
        fields = string(fieldnames(opts));
        varNamesExist = any(strcmp(fields,"VariableNames"));
        if (~isempty(rhs) && ~isvector(rhs)) ...
                || ~isnumeric(rhs) ...
                || ~all(floor(rhs)==rhs & isfinite(rhs) & rhs > 0) ...
                || varNamesExist && numel(rhs) ~= numel(opts.VariableNames)
            error(message('MATLAB:textio:io:VariableWidths'))
        end
        opts.widths_ = rhs;
        end
        
        function val = get.VariableWidths(opts)
        val = opts.widths_;
        end
    end
end

