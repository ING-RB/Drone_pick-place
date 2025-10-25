classdef FunctionStore
    % A collection of functions objects to avoid repeated construction
    
    % Copyright 2018-2024 The MathWorks, Inc.
    methods (Static)
        function func = getFunctionByName(name)
        func = accessMap('get',name);
        end
        
        function addFunction(name, func)
        accessMap('add',name,func);
        end
    end
end

function func = accessMap(op,name,func)
import matlab.io.internal.functions.*

persistent functionMap;
if isempty(functionMap),functionMap = struct();end


% add a function to the map
switch(op)
    case 'add'
        if ~isa(func,'matlab.io.internal.functions.ExecutableFunction')
            error('Not a function');
        end
        functionMap.(name) = func;
    case 'get'
        
        if isfield(functionMap, name)
            % If a function has already been registered, get that function
            % from the MAP. (Functions are value objects)
            func = functionMap.(name);
            return
        else
            % Try to add one of the known functions.
            switch (name)
                case 'detectImportOptions'
                    func = DetectImportOptions;
                case 'readcell'
                    func = ReadCell;
                case 'readtable'
                    func = ReadTable;
                case 'readmatrix'
                    func = ReadMatrix;
                case 'readtimetable'
                    func = ReadTimeTable;
                case 'readvars'
                    func = ReadVars;
                case 'readlines'
                    func = ReadLines;
                case 'readstruct'
                    func = ReadStruct;
                case 'readdictionary'
                    func = ReadDictionary;
                case 'table2timetable'
                    func = Table2Timetable;
                case 'readtableWithImportOptions'
                    func = ReadTableWithImportOptions;
                case 'readtimetableWithImportOptions'
                    func = ReadTimeTableWithImportOptions;
                case 'readcellWithImportOptions'
                    func = ReadCellWithImportOptions;
                case 'readmatrixWithImportOptions'
                    func = ReadMatrixWithImportOptions;
                case 'readvarsWithImportOptions'
                    func = ReadVarsWithImportOptions;
                case 'setvaropts'
                    func = SetVarOpts;
                otherwise
                    error('Unknown Function');
            end
            functionMap.(name) = func;
        end
end
end
