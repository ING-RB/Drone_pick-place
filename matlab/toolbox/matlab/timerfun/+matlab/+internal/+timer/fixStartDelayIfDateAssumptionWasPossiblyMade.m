function startDelay = fixStartDelayIfDateAssumptionWasPossiblyMade(theDateStr, initialStartDelayAssumption, compareAgainstCurrFiringTime)
%

%   Copyright 2019 The MathWorks, Inc.

    formatsToTry = {'HH:mm', 'hh:mm a', 'HH:mm:ss', 'hh:mm:ss a'};
    localeToTry = getListOfLocaleToTry();


    for i = 1 : numel(formatsToTry)
        for j = 1: numel(localeToTry)
            try
                assumedTime = datetime(theDateStr, 'InputFormat', formatsToTry{i}, 'Locale', localeToTry{j});
                startDelay = seconds(assumedTime - datetime(datevec(compareAgainstCurrFiringTime)));
                return;
            catch
                % datetime errored, which means its not one of the
                % 13/14/15/16 forms, so do nothing, try another format
            end
        end
    end
    % if we needed a fixup, the codepath will "return" before hitting this line
    % if we are hitting this line, means the initial assumption was correct to
    % begin with
    startDelay = initialStartDelayAssumption;
end

function out = getListOfLocaleToTry()
    s = settings;
    locale_preferences = s.matlab.datetime.DisplayLocale.ActiveValue;

    % datetime supports 'system' as a value,
    % no need to pull that from feature('locale');
    locale_system = 'system';
    locale_fallback = 'en_US';

    out = {locale_preferences, locale_system, locale_fallback};
end
