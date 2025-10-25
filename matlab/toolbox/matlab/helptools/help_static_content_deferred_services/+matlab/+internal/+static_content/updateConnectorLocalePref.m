function updateConnectorLocalePref(newLang)
    if ischar(newLang)
        newLang = string(newLang);
    end
    try
        if strcmp(newLang, 'en')      
            connector.resetLocalePreference;
        else
            %   for example:
            %   setLocalePreference('ja_JP');
            %   setLocalePreference('fr');
            connector.setLocalePreference(newLang);
        end
    catch
        % There's not a lot we can do to recover from this.
    end
end

% Copyright 2020-2022 The MathWorks, Inc.