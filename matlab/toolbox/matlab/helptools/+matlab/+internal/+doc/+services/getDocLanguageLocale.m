function docLanguage = getDocLanguageLocale()
%

%   Copyright 2020-2023 The MathWorks, Inc.

    docLanguageSetting = matlab.internal.doc.i18n.getDocLanguage;
    docLanguage = matlab.internal.doc.services.DocLanguage.fromLanguageStr(docLanguageSetting);
end
