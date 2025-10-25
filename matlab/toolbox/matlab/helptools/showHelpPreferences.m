%

%  Copyright 2016-2020 The MathWorks, Inc.
function showHelpPreferences()    
    helpPrefsName = com.mathworks.mlwidgets.help.HelpPrefs.getHelpPreferencesName;
    preferences(string(helpPrefsName));   
end
