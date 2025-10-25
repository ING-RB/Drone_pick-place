classdef Util
    % A collection of functions that help to get the layout and option data

    % Copyright 2022 The MathWorks, Inc.
    methods(Static)
        % get layout and options
        % layout: an array of struct with label and value fields:
        % for example: [struct('label', 'English(United States)', 'value', 'us'), ...
        % struct('label', 'English(United Kingdom)', 'value', 'gb')]

        % options: a struct that has layout value as field and 
        % an array of struct with label and value fields as value 
        % for example: struct('us', [struct('label', 'Default', 'value', 'default'),...
        % struct('label', 'US international', 'value', 'intl')])
        function [layouts, options] = getLayoutOptions()
            import simulink.online.internal.keyboard.prefDlg.Util;
            allLayoutOptions = Util.getAllLayoutOptions();
            
            options = allLayoutOptions.options;
            layouts = allLayoutOptions.layouts;
        
        end

        % label2ValueMap: uses label as key 
        % value2labelMap: uses value as key
        function [label2ValueMap, value2labelMap] = getLayoutMaps()
            import simulink.online.internal.keyboard.prefDlg.Util;

            persistent l2vMap;
            persistent v2lMap;        
            if isempty(l2vMap) || isempty(v2lMap)
                layouts = Util.getLayoutOptions();
                l2vMap = containers.Map('KeyType','char','ValueType','char');
                v2lMap = containers.Map('KeyType','char','ValueType','char');
        
                for i = 1: length(layouts)
                    label = layouts(i).label;
                    value = layouts(i).value;
                    l2vMap(label) = value;
                    v2lMap(value) = label;
                end
            end
            label2ValueMap = l2vMap;
            value2labelMap = v2lMap;
        end
        
        % returns a cell array of layout labels
        function entries = getLayoutEntries()
            import simulink.online.internal.keyboard.prefDlg.Util;

            label2ValueMap = Util.getLayoutMaps();
            entries = keys(label2ValueMap);
        end


        % returns a cell array of layout values
        function values = getLayoutValues()
            import simulink.online.internal.keyboard.prefDlg.Util;

            [~, value2LabelMap] = Util.getLayoutMaps();
            values = keys(value2LabelMap);
        end
        
        % get a layout label given a value
        function label = getLayoutLabel(value)
            import simulink.online.internal.keyboard.prefDlg.Util;

            [~, value2LabelMap] = Util.getLayoutMaps();
            label = value2LabelMap(value);
        end

        % get a layout value given a label
        function value = getLayoutValue(label)
            import simulink.online.internal.keyboard.prefDlg.Util;

            label2ValueMap = Util.getLayoutMaps();
            value = label2ValueMap(label);
        end

        % get all options as a cell array for a given layout
        function options = getOptions(layout)
            import simulink.online.internal.keyboard.prefDlg.Util;

            [~, optionStruct] = Util.getLayoutOptions();
            if ~isfield(optionStruct, layout)
                error(['invalid keyboard layout ' layout]);
            end    
            options = optionStruct.(layout);
        end
        
        % get option labels as a cell array
        % and the option label for a given option value
        function [entries, label] = getOptionEntriesAndLabel(layout, value)  
            import simulink.online.internal.keyboard.prefDlg.Util;

            label = [];
 
            optionArr = Util.getOptions(layout);
            len = length(optionArr);
            entries = cell(len, 1);
            for i = 1: len
                entries{i} = optionArr(i).label;
                if strcmp(optionArr(i).value, value)
                    label = optionArr(i).label;
                end
            end

            if isempty(label)
                error(['invalid layout(' layout ') and option(' value ') combination']);
            end
        end

        % get the option label for a given option value and layout value
        function value = getOptionValue(layout, label)
            import simulink.online.internal.keyboard.prefDlg.Util;

            value = [];

            [~, options] = Util.getLayoutOptions();
            if ~isfield(options, layout)
                error(['invalid keyboard layout ' layout]);
            end    
            optionArr = options.(layout);
            for i = 1: length(optionArr)
                if strcmp(optionArr(i).label, label)
                    value = optionArr(i).value;
                end
            end

            if isempty(value)
                error(['invalid layout(' layout ') and option(' label ') combination']);
            end
        end

        % read the layout and options from the json file
        function settings = getAllLayoutOptions()
            import simulink.online.internal.keyboard.prefDlg.Util;
            persistent allLayoutOptions;
            if isempty(allLayoutOptions)
                layoutFile = fullfile(matlabroot, 'toolbox/simulink/online/server/m/+simulink/+online/+internal/+keyboard/+prefDlg/layout.json');
                optionsFile = fullfile(matlabroot, 'toolbox/simulink/online/server/m/+simulink/+online/+internal/+keyboard/+prefDlg/options.json');

                layouts = Util.readJsonFile(layoutFile);
                options = Util.readJsonFile(optionsFile);
                allLayoutOptions = struct('layouts', layouts, 'options', options);
            end

            settings = allLayoutOptions;
        end

        function isValid = isValidLayout(value)
            import simulink.online.internal.keyboard.prefDlg.Util;

            [~, value2LabelMap] = Util.getLayoutMaps();
            isValid = isKey(value2LabelMap, value);
        end

        % get default option given a layout 
        function option = getDefaultOption(layout)
            import simulink.online.internal.keyboard.prefDlg.Util;
            
            options = Util.getOptions(layout);
            option = options(1).value;
        end

    end

    methods(Static, Access = private)
        function data = readJsonFile(fileName)
            fid = fopen(fileName);
            raw = fread(fid,inf);
            str = char(raw');
            fclose(fid);
            data = jsondecode(str);
        end
            
    end
end
