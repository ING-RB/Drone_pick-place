function success = updateLanguage
    lang = matlab.internal.doc.services.getDocLanguageLocale;
    if isempty(lang)
        lang = matlab.internal.doc.services.DocLanguage.getDefault;
    end
    args =  struct('lang',lang.directoryLanguage);
    success = matlab.internal.doc.search.sendSearchMessage("docconfig", "Params", args);
end