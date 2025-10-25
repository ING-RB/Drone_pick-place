

classdef Locale < handle
    % The singleton class holds the locale sent from front-end. 
    % It also holds the locale that defined in three buckets: 
    % 1. Locales that we don't have to do anything, like en-us
    % 2. Locales that we map to certain layout by default, like ja-jp
    % For the rest of the locales, we prompt and let user choose

    % Copyright 2021 The MathWorks, Inc.

    properties (Access = private)
        ClientLocale = '';
    end
    properties (Constant)
        MappedLocales = containers.Map(...
            {'ja-jp','ja', 'de-de','de', 'fr-fr', 'fr', 'en-gb'}, ...
            {'jp', 'jp', 'de.deadacute', 'de.deadacute', 'fr', 'fr', 'gb'});
        DefaultSupportedLocales = {'en-us', 'en', 'zh-cn', 'en-in'};
    end
    methods (Static)
        function obj = instance()
            persistent uniqueInstance;
            if isempty(uniqueInstance)
                uniqueInstance = simulink.online.internal.keyboard.Locale();
            end
            obj = uniqueInstance;
  
        end
    end
    
    methods
        function layout = getLayout(obj)
            if isKey(obj.MappedLocales, obj.ClientLocale) 
                layout = obj.MappedLocales(obj.ClientLocale);
            else
                layout = '';
            end
        end

        function val = isDefaultSupported(obj)
            if isempty(obj.ClientLocale)
                val = false;
                return;
            end

            idx = find(contains(simulink.online.internal.keyboard.Locale.DefaultSupportedLocales, ...
             obj.ClientLocale), 1);
            val = ~isempty(idx);
        end

        function locale = get(obj)
            locale = obj.ClientLocale;
        end

        function set(obj, locale)
            obj.ClientLocale = locale;
        end
    end
end