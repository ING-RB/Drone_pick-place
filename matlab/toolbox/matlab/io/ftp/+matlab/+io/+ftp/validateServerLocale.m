function locale = validateServerLocale(locale)
    locale = matlab.internal.datetime.verifyLocale(locale);
end
