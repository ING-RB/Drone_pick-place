classdef HardwareKeywordData
    %HARDWAREKEYWORDDATA Hardware keyword data required by Hardware Manager app

    % Copyright 2021-2022 The MathWorks, Inc.

    properties (SetAccess = private)
        %Keyword
        %   Hardware keyword data headline
        Keyword

        %Description
        %   Hardware keyword data one-liner to provide more information on
        %   the keyword
        Description

        %TooltipText
        %   Tooltip text show up on hovering over the keyword entry
        TooltipText

        %Categories
        %   Categories of this keyword in the form of enumerations from
        %   matlab.hwmgr.internal.data.HardwareKeywordCategory
        Categories

        %KeywordRelatedBaseCodes
        %   Base codes of AddOns related to the keyword
        KeywordRelatedBaseCodes

        %Manufacturers
        %   Map with manufactuer names as keys and related AddOn base codes
        %   as values
        Manufacturers

        %AppletClasses
        %   MATLAB classes of applets associated to the keyword when
        %   applets have no AddOn dependency
        AppletClasses

        %ManufacturerPlaceholder
        %   Customizable placeholder string of the manufuctuer combobox
        ManufacturerPlaceholder
    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = HardwareKeywordData(keyword, description, tooltipText, ...
                categories, nameValueArgs)
            arguments
                keyword (1, 1) string
                description (1, 1) string
                tooltipText (1, 1) string
                categories (1, :) matlab.hwmgr.internal.data.HardwareKeywordCategory {mustBeNonempty}
                nameValueArgs.KeywordRelatedBaseCodes (1, :) string = string.empty()
                nameValueArgs.Manufacturers (1, :) containers.Map {matlab.hwmgr.internal.data.HardwareKeywordData.mustBeValidManufacturerMap} = containers.Map.empty()
                nameValueArgs.AppletClasses (1, :) string = string.empty()
                nameValueArgs.ManufacturerPlaceholder (1, 1) string = ""
            end

            % Count number of empty optional inputs among
            % "KeywordRelatedBaseCodes", "Manufacturers", "AppletClasses"
            count = 0;
            fieldsToCheck = ["KeywordRelatedBaseCodes", "Manufacturers", "AppletClasses"];
            for i = 1:length(fieldsToCheck)
                if isempty(nameValueArgs.(fieldsToCheck(i)))
                    count = count + 1;
                end
            end    
            
            if count ~= 2
                ME = MException('hwmanagerapp:hardwareKeywordData:InvalidData', ...
                    "Exactly one of 'KeywordRelatedBaseCodes', 'Manufacturers' and " + ...
                    "'AppletClasses' must be non-empty");
                throw(ME);
            end

            if isempty(nameValueArgs.Manufacturers) && nameValueArgs.ManufacturerPlaceholder ~= ""
                ME = MException('hwmanagerapp:hardwareKeywordData:InvalidManufacturerPlaceholder', ...
                    "ManufacturerPlaceholder can only be set when Manufacturers is non-empty");
                throw(ME);
            end

            % All basecodes must be upper case.
            obj.Keyword = keyword;
            obj.Description = description;
            obj.TooltipText = tooltipText;
            obj.Categories = categories;
            obj.KeywordRelatedBaseCodes = upper(nameValueArgs.KeywordRelatedBaseCodes);
            if ~isempty(nameValueArgs.Manufacturers)
                obj.Manufacturers = containers.Map(nameValueArgs.Manufacturers.keys, ...
                    cellfun(@(x) upper(x), nameValueArgs.Manufacturers.values, 'UniformOutput', false));
            end
            obj.AppletClasses = nameValueArgs.AppletClasses;
            obj.ManufacturerPlaceholder = nameValueArgs.ManufacturerPlaceholder;
        end
    end

    methods (Static, Access = private)
        function mustBeValidManufacturerMap(map)
            values = map.values();
            for i = 1 : length(values)
                if ~isstring(values{i})
                    ME = MException('hwmanagerapp:hardwareKeywordData:InvalidManufacturersMap', ...
                        "Manufactuers map value must be string array.");
                    throw(ME);
                end
            end
        end
    end
end