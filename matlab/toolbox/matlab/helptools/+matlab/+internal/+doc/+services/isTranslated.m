function b = isTranslated
    b = matlab.internal.doc.services.getDocLanguageLocale ~= matlab.internal.doc.services.DocLanguage.ENGLISH;
end

% Copyright 2021 The MathWorks, Inc.
