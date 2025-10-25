classdef TreatAsMissingInput < matlab.io.internal.FunctionInterface
    %TREATASMISSING 
    
    % Copyright 2018 MathWorks, Inc.
    properties (Parameter)
        %TREATASMISSING
        %   A cell array of character vectors which are to be treated as missing
        %   indicators for the variable when importing text data. When a missing
        %   indicator is found, the MissingRule is used to determine the
        %   appropriate action.
        %
        %   Example, set the options to replace occurrences of 'NA' with '-':
        %
        %       % when ImportOptions/MissingRule = 'fill'
        %       opts = matlab.io.TextVariableImportOptions();
        %       opts.TreatAsMissing = {'NA'};
        %       opts.FillValue = '-';
        %
        %   When importing, any instances of 'NA' will be replaced with '-'
        %
        % See also matlab.io.VariableImportOptions
        %   matlab.io.spreadsheet.SpreadsheetImportOptions/MissingRule
        %   matlab.io.spreadsheet.SpreadsheetImportOptions/ImportErrorRule
        %   matlab.io.VariableImportOptions/FillValue
        TreatAsMissing = {};
    end
    
    methods
        function obj = set.TreatAsMissing(obj,rhs)
            if isnumeric(rhs) && isequal(rhs,[])
                rhs = strings(0);
            else
                rhs = convertCharsToStrings(rhs);
            end
            if ~isstring(rhs) || any(ismissing(rhs),'all')
                error(message('MATLAB:datastoreio:tabulartextdatastore:invalidTreatAsMissing'))
            end
            if isempty(rhs)
                obj.TreatAsMissing = {};
            else
                obj.TreatAsMissing = cellstr(rhs);
            end
        end     
    end
end

