classdef NumberDisplayFormatProvider < handle
    % NUMBERDISPLAYFORMATPROVIDER provides the display format for a view
    % This class returns the numberDisplayFormat and LongNumDisplayformat
    
    % Copyright 2021-2022 The MathWorks, Inc.
    
    properties(Dependent = true)
        NumDisplayFormat; 
    end
    
    properties
        LongNumDisplayFormat;
    end
    
    % Internal Property for NumDisplayFormat to store the current valid
    % short display format.
    properties(Access='protected')
       NumDisplayFormat_I;
    end
  
    properties(Constant)        
        ShortPrecisionFormats = ["short", "shortE", "shortG", "shortEng"];
        longPrecisionFormats = ["long", "longE", "longG", "longEng"];
    end
    
    properties(Access=private)
        useSettingForContext logical;
    end
    
    methods
        
        function obj = NumberDisplayFormatProvider(userContext, displayFormat)
            arguments
                userContext = '';
                displayFormat char = '';
            end
            settingsRegnMap = internal.matlab.variableeditor.ArrayViewModel.getSettingRegistrationMap();
            obj.useSettingForContext = (~isempty(userContext) && isKey(settingsRegnMap, userContext) && settingsRegnMap(userContext));
            obj.initFormat(displayFormat);
        end
        
        function val = get.NumDisplayFormat(this)
            val = this.NumDisplayFormat_I;
        end
        
        function set.NumDisplayFormat(this, numFormat)
            arguments
                this
                numFormat (1,1) string
            end
            this.NumDisplayFormat_I = numFormat;
            longFormat = internal.matlab.variableeditor.NumberDisplayFormatProvider.getCorrespondingLongFormat(numFormat);
            this.LongNumDisplayFormat = longFormat;
        end
    end
    
    methods(Access='private')
        function initFormat(this, numFormat)
            arguments
                this
                numFormat
            end
            if isempty(numFormat)
                s = settings;
                if (this.useSettingForContext)
                    numFormat = s.matlab.desktop.variables.ArrayEditor_CS_Format.ActiveValue;
                else
                    numFormat = s.matlab.commandwindow.NumericFormat.ActiveValue;
                end
            end
            this.NumDisplayFormat = numFormat;
        end
    end

    methods(Static)
        function longFormat = getCorrespondingLongFormat(numberFormat)
            longFormat = numberFormat;
            mappedLongFormat = matches(internal.matlab.variableeditor.NumberDisplayFormatProvider.ShortPrecisionFormats, numberFormat);
            if (any(mappedLongFormat))
                longFormat = internal.matlab.variableeditor.NumberDisplayFormatProvider.longPrecisionFormats(mappedLongFormat);
            end
        end
    end
end

