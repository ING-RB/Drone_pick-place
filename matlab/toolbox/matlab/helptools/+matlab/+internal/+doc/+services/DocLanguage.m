classdef DocLanguage < handle
%

%   Copyright 2020-2023 The MathWorks, Inc.

    enumeration
        ENGLISH ('en', 'en')
        SIMPLIFIED_CHINESE ('zh_CN', 'zh_CN')
        JAPANESE('ja_JP', 'ja_JP')
        KOREAN('ko_KR', 'ko_KR')
        SPANISH('es', 'es')
        FRENCH('fr', 'fr')
        GERMAN('de', 'de')
        ITALIAN('it', 'it')
    end
    
    properties
        directoryLanguage
        settingLocaleString % see matlab/java/src/com/mathworks/mlwidgets/html/LanguageLocale.java
    end
    
    methods
        function obj = DocLanguage(directoryLanguage, settingLocaleString)
            obj.directoryLanguage = directoryLanguage;
            obj.settingLocaleString = settingLocaleString;
        end
        
        function dir = getDirectory(obj)
            dir = obj.directoryLanguage; 
        end
        
        function langSetting = getLangSetting(obj)
            langSetting = obj.settingLocaleString;
        end
    end
    
    methods (Static)
        function default = getDefault()
            default = matlab.internal.doc.services.DocLanguage.ENGLISH;
        end
        
        function docLanguage = fromLanguageStr(systemLang)
            switch(systemLang)
              case {'en','en_US'}
                 docLanguage = matlab.internal.doc.services.DocLanguage.ENGLISH;
              case 'zh_CN'
                 docLanguage = matlab.internal.doc.services.DocLanguage.SIMPLIFIED_CHINESE;
              case 'ja_JP'
                 docLanguage = matlab.internal.doc.services.DocLanguage.JAPANESE;
              case 'ko_KR'
                 docLanguage = matlab.internal.doc.services.DocLanguage.KOREAN;
              case 'es'
                 docLanguage = matlab.internal.doc.services.DocLanguage.SPANISH;
              case 'fr'
                  docLanguage = matlab.internal.doc.services.DocLanguage.FRENCH;
              case 'de'
                  docLanguage = matlab.internal.doc.services.DocLanguage.GERMAN;
              case 'it'
                  docLanguage = matlab.internal.doc.services.DocLanguage.ITALIAN;
              otherwise
                 docLanguage = matlab.internal.doc.services.DocLanguage.ENGLISH;    
            end
        end
    end
end

