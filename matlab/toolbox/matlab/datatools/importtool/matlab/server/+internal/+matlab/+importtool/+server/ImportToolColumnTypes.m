% This class is unsupported and might change or be removed without notice
% in a future version.

classdef ImportToolColumnTypes < handle
    %Constants for various column types in the Import tool

    % Copyright 2018 The MathWorks, Inc.
     properties (Constant)
        typeConstants = struct( ...
            'double', getString(message('MATLAB:codetools:importtool:NumberDisplayValue')), ...
            'char', getString(message('MATLAB:codetools:importtool:TextDisplayValue')), ...
            'string', getString(message('MATLAB:codetools:importtool:TextDisplayValue')), ...
            'categorical', getString(message('MATLAB:codetools:importtool:CategoricalDisplayValue')), ...
            'datetime', getString(message('MATLAB:codetools:importtool:DatetimeDisplayValue')), ...
            'duration', getString(message('MATLAB:codetools:importtool:DurationDisplayValue')));
        
        typeListConstants = struct( ...
            'double', 'Number', ...
            'char', 'Text', ...
            'string', 'Text', ...
            'categorical', 'Text', ...
            'datetime', 'Datetime', ...
            'duration', 'Text');

        typeImportOptionsConstants = struct();
        % fields like:
        %     'datetime', containers.Map( ...
        %         {'',            'posixtime',   'yyyymmdd'}, ...
        %         {'InputFormat', 'ConvertFrom', 'ConvertFrom'}, ...
        %         'UniformValues', false));
     end
     
     methods(Static, Access='public')        
         function displayType = getColumnTypeForDisplay(dataType)
             displayType = '';
             types = internal.matlab.importtool.server.ImportToolColumnTypes.typeConstants;
             if isfield(types, dataType)
                 displayType = types.(dataType);
             end
         end
         
         function importOptions = getColumnImportOptions(dataType, typeOption)
             typeImportOptions = internal.matlab.importtool.server.ImportToolColumnTypes.typeImportOptionsConstants;
             if isfield(typeImportOptions, dataType) && isKey(typeImportOptions.(dataType), typeOption)
                 typeOptions = typeImportOptions.(dataType);
                 importOptions = typeOptions(typeOption);
                 
                 if ~isstruct(importOptions)
                     % importOptions like 'InputFormat', want struct like
                     % importOptions.InputFormat = typeOption
                     importOptions = struct(importOptions, typeOption);
                 end
             else
                 importOptions = internal.matlab.datatoolsservices.DataTypeMenuUtils.getPropertiesForTypeOption(dataType, typeOption);
             end
         end
         
         function dataTypeListType = getColumnListType(dataType)
             dataTypeListType = '';
             typeLists = internal.matlab.importtool.server.ImportToolColumnTypes.typeListConstants;
             if isfield(typeLists, dataType)
                 dataTypeListType = typeLists.(dataType);
             end
         end
         
         function dataTypeList = getDataTypeList(listType)
             DTMUtils = internal.matlab.datatoolsservices.DataTypeMenuUtils;
             
             typeLists = internal.matlab.importtool.server.ImportToolColumnTypes.typeListConstants;
             if isfield(typeLists, listType)
                 listType = typeLists.(listType);
             end
             
             switch listType
                 case 'Text'
                     listSpec = {'string', 'double', 'categorical', 'datetime text help', 'duration text'};
                     
                 case 'Number'
                     % Number -> Duration disabled: interprets as days, displays in seconds - more confusing than useful
                     listSpec = {'string', 'double', 'categorical', 'datetime text help', 'duration disabled'};

                 case 'Datetime'
                     % Datetime -> Number disabled: interprets as exceltime - more confusing than useful
                     % Datetime -> Duration disabled: interprets as NaN sec
                     listSpec = {'string', 'double disabled', 'categorical', 'datetime', 'duration disabled'};
                     
                 otherwise
                     listSpec = {};
             end

             dataTypeList = DTMUtils.constructList(listSpec{:});
         end
         
         function selectionList = getSelectionDataTypeList(columnTypes)
             dataTypeLists = cellfun(@(x) internal.matlab.importtool.server.ImportToolColumnTypes.getDataTypeList(x), unique(columnTypes), 'UniformOutput', false);
             selectionList = internal.matlab.datatoolsservices.DataTypeMenuUtils.unionListsDisableXor(dataTypeLists{:});
         end
     end
end
