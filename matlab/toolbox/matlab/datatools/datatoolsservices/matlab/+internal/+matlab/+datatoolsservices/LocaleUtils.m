classdef LocaleUtils < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    methods(Static)
        % Returns the current locale.  For example, 'en_US' or 'ja_JP'.
        function lc = getCurrLocale()
            import internal.matlab.datatoolsservices.LocaleUtils;
            lc = LocaleUtils.getSetLocale();
        end
        
        % Function for tests to force the locale to a specific setting.
        function testSetLocale(locale)
            import internal.matlab.datatoolsservices.LocaleUtils;
            LocaleUtils.getSetLocale("OVERRIDE", locale);
        end
        
        % Returns true if the current locale is a CJK language (Chinese,
        % Japanese or Korean)
        function cjk = isCJK()
            import internal.matlab.datatoolsservices.LocaleUtils;
            
            lc = LocaleUtils.getCurrLocale;
            cjk = startsWith(lc, "zh_") || ...
                startsWith(lc, "ja_") || ...
                startsWith(lc, "ko_");
        end
    end
    
    methods(Static, Access = protected)
        function lc = getSetLocale(varargin)
            mlock;
            persistent currLocale;
            
            if isempty(currLocale)
                % Initialize the currLocale.  lc will be a struct with many
                % fields containing localization information.  lc.messages will
                % be in the format "localeCode.encoding", something like:
                % "en_US.windows-1252" or "ja_JP.UTF-8".
                lc = feature("locale");
                currLocale = extractBefore(lc.messages, ".");
                
                if ~(strlength(currLocale) > 0)
                    % Handle the case where there is no encoding, just return
                    % the lc.messages value as is.
                    currLocale = lc.messages;
                end
            end
            
            if nargin == 2 && varargin{1} == "OVERRIDE"
                % User the override flag to allow tests to overide the locale
                % value
                currLocale = varargin{2};
            end
            lc = currLocale;
        end
    end
end
