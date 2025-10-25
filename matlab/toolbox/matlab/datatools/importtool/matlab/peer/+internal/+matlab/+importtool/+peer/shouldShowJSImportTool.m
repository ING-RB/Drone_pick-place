function doShowNewImportTool = shouldShowJSImportTool(varargin)
    % This function is unsupported and might change or be removed without notice
    % in a future version.
    
    % Returns true when the JavaScript import tool needs to be shown, otherwise
    % returns false.
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    s = settings;
    doShowNewImportTool = false;
    if hasSetting(s.matlab.importtool, "Decaf")
        st = s.matlab.importtool.Decaf;
        doShowNewImportTool = st.ActiveValue;
    else
        st = addSetting(s.matlab.importtool, "Decaf", "PersonalValue", false);
    end
    
    if nargin == 1
        if islogical(varargin{1})
            st.PersonalValue = varargin{1};
            doShowNewImportTool = varargin{1};
        else
            st.PersonalValue = false;
        end
    end
end
