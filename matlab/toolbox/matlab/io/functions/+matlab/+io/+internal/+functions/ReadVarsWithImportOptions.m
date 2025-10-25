classdef ReadVarsWithImportOptions < matlab.io.internal.functions.ReadTableWithImportOptions
%

%   Copyright 2018-2020 The MathWorks, Inc.
    
    methods        
        function [func,supplied,other] = validate(func,varargin)
            [func,supplied,other] = validate@matlab.io.internal.functions.ExecutableFunction(func,varargin{:});
            if isa(func.Options,'matlab.io.xml.XMLImportOptions')
                error(message("MATLAB:io:xml:common:UnsupportedFileTypeXML", "readvars"));
            end
            
            matlab.io.internal.functions.parameter.assertNoRowNamesInputs(supplied);
            matlab.io.internal.functions.parameter.assertNoVariableNameInputs(supplied);
        end
        
        function varargout = execute(func,supplied)
            if nargout > numel(func.Options.SelectedVariableNames)
                error(message('MATLAB:TooManyOutputs'));
            end
            
            func.Options.SelectedVariableNames = func.Options.SelectedVariableNames(1:nargout);
            
            [T,func] = func.executeImpl(supplied);
            
            [varargout{func.Omitted}] = deal(missing);
            i = find(~func.Omitted);
            
            for j = 1:length(i)
                varargout{i(j)} = T.(j);
            end
        end
    end
end
