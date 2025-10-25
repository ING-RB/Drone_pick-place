function [t,fmt] = guessFormat(dateStrs,tryFmts,errMode,tz,locale,pivot)
%GUESSFORMAT Guess datetime format from raw timestamp text.
% guessFormat tries to recognize timestamps using only a limited list of
% formats, primarily formats that are unambiguously recognizable. A datetime
% format is considered "unambiguous" if it contains
% * a month name (not month number) token, so month and day can't be confused
% * a four-digit year token, so year and day can't be confused
% There are a very small number of exceptions with a month number token that are
% treated "as if" unambiguous because any other format that could be mistaken
% for them is considered very unlikely. If guessFormat succeeds in parsing the
% first timestamp with an umbiguous format, it stops trying other formats, and
% uses that one to parse all the remaining timestamps.
%
% There are other formats, e.g. MM/dd/uuuu and dd/MM/uuuu, that are ambiguous in
% the sense that it may not be possible to tell if a given timestamp matches one
% or the other, but that are so commonly-used that guessFormat does its best to
% recognize them. For these formats, guessFormat tries both, and uses locale to
% inform a precedence. It also looks across all the timestamps (not just the
% first) to decide if one or the other, neither (errors), or both (warns) are
% matches.
%
% guessFormat does not try to recognize formats with two-digit year, which can
% not only be confused with day or month number, but also between a date in
% antiquity and an abbreviated contemporary date.
%
% guessFormat only tries to recognize time portions that are unambiguously
% recognizable (e.g. HH:mm:ss) or treated as such (e.g. HH:mm).

%   Copyright 2014-2020 The MathWorks, Inc.

import matlab.internal.datetime.createFromString
import matlab.internal.datetime.getDatetimeSettings
import matlab.internal.datetime.getFormatsForGuessing

% Find the first non-missing, non-empty, non-NaT/Inf string. guessFormat will
% initially try to find a format that unambiguously matches that one timestamp.
tryStr = {};
for k = 1:numel(dateStrs)
    if ismissing(dateStrs(k)) % curly brace indexing on missing would error
        str = char.empty;
    else
        str = dateStrs{k};
    end
    if ~matlab.internal.datetime.isLiteralNonFinite(str,["NaT","Inf"],true)
        % not non-finite or empty
        tryStr = {str}; % createFromString expects a cellstr
        break
    end
end

if isempty(tryStr)
    % If there are no timestamps (dateStrs is empty), or if all timestamps are
    % empty or NaT/Inf, assume the default format.
    fmt = getDatetimeSettings('defaultformat');
    t = createFromString(dateStrs,fmt,errMode,tz,locale,pivot);
else
    % First try the caller's suggested formats.
    for i = 1:length(tryFmts)
        fmt = tryFmts{i};
        if tryOneFmt(fmt), return, end % quit if this format works
    end
    
    % Get a list of standard formats to try, including some locale-specific
    % ones. The list is thinned to include only those formats that could
    % possibly match the timestamp, e.g. they contain the same number of spaces.
    if isempty(locale)
        [guessformats,numNonAmbiguous] = getFormatsForGuessing(matlab.internal.datetime.getDefaults('locale'), tryStr{:}); % cellstr->char
    else
        [guessformats,numNonAmbiguous] = getFormatsForGuessing(locale, tryStr{:});  % cellstr->char
    end
    
    % The list begins with formats that are unambiguously recognizable (or
    % treated as such). Try those first, and parse all the timestamps with the
    % first format (if any) that works.
    for i = 1:numNonAmbiguous
        fmt = guessformats{i};
        if tryOneFmt(fmt), return, end % quit if this format works
    end
    
    % None of the unambiguous formats worked. Remove them from the list.
    guessformats(1:numNonAmbiguous) = [];
    
    % The remainder of the list (if any) contains ambiguous MM/dd,dd/MM format
    % pairs (one date-only pair and its date+time children). Try those, in
    % pairs, with logic that warns if both are possible.
    if ~isempty(guessformats)
        numAmbiguous = numel(guessformats); % format pairs -- this is always even
        for j = 1:2:numAmbiguous
            % Get the locale's preferred month number (MM) format to try first,
            % and it's opposite "MM swapped with dd" format to try second.
            fmt1 = guessformats{j};  
            fmt2 = guessformats{j+1};
            
            % Parse the first timestamp with the preferred format. If it
            % succeeds, parse all the other timestamps too.
            if tryOneFmt(fmt1)
                % The first format worked on the first timestamp, but look at
                % how it worked on all the other timestamps to decide what to do
                % with the second format.
                numNaTs = sum(isnan(t(:)));
                if numNaTs == 0
                    % The first format worked perfectly on all the timestamps.
                    % It's the preferred one, so go with it, but warn if second
                    % format would have worked too, i.e. if all the day numbers
                    % could have been month numbers.
                    ucal = datetime.dateFields;
                    day = matlab.internal.datetime.getDateFields(t,ucal.DAY_OF_MONTH,tz);
                    if all(day <= 12)
                        warning(message('MATLAB:datetime:AmbiguousDateString',fmt1,fmt2));
                    end
                    fmt = fmt1;
                    return % quit, the first format works
                else % numNaTs > 0
                    % The first format had some failures. Try the second format
                    % on all the timestamps.
                    t2 = createFromString(dateStrs,fmt2,0,tz,locale,pivot);
                    firstNotSecond = any(~isnan(t(:)) & isnan(t2(:)));
                    secondNotFirst = any(isnan(t(:)) & ~isnan(t2(:)));
                    if firstNotSecond && secondNotFirst
                        % If the second format failed somewhere the first one succeeded,
                        % and vice-versa, we definitely have mixed month-first/day-first.
                        % Don't accept either.
                        break
                    elseif firstNotSecond
                        % If the second format failed somewhere the first one succeeded,
                        % but didn't succeed anywhere the first one failed, the first
                        % is unambiguously the right one.
                        fmt = fmt1;
                        return % quit, the first format works well enough
                    elseif secondNotFirst
                        % If the second format succeeded somewhere the first one failed,
                        % but didn't fail anywhere the first one succeeded, the second
                        % is unambiguously the right one.
                        t = t2;
                        fmt = fmt2;
                        return % quit, the second format works well enough
                    else
                        % Otherwise, the two formats worked equally well. Warn about that.
                        warning(message('MATLAB:datetime:AmbiguousDateString',fmt1,fmt2));
                        fmt = fmt1;
                        return % quit, the first format works well enough
                    end
                end
            else
                % The first format didn't work on the first timestamp. Parse the
                % first timestamp with the second format. If it succeeds, parse
                % all the other timestamps too.
                if tryOneFmt(fmt2)
                    % The second format worked on the first timestamp, but look
                    % at how it worked on all the other timestamps to decide
                    % what to do with the first format.
                    numNaTs = sum(isnan(t(:))); % always < numel(t)
                    if numNaTs == 0
                        % The second format worked perfectly. Already know the
                        % first one didn't work perfectly (it failed on the
                        % first timestamp), so go with the second.
                        fmt = fmt2;
                        return % quit, the second format works
                    else % numNaTs > 0
                        % The second format had some failures. Try the first format
                        % on all the timestamps.
                        t1 = createFromString(dateStrs,fmt1,0,tz,locale,pivot);
                        % Already know the first format failed somewhere the
                        % second one succeeded (on the first timestamp). Did it
                        % succeed anywhere the second format failed?
                        firstNotSecond = any(isnan(t(:)) & ~isnan(t1(:)));
                        if firstNotSecond
                            % If the first format succeeded somewhere the second
                            % one failed, we definitely have mixed
                            % month-first/day-first. Don't accept either.
                            break
                        else
                            % If the first format didn't succeed anywhere the
                            % second one failed, the second is unambiguously the
                            % right one.
                            fmt = fmt2;
                            return % quit, the second format works well enough
                        end
                    end
                end
            end
        end
    end
    
    % Finally, try the datetime display preference settings and the standard
    % spreadsheet formats. These are not in the list returned by
    % getFormatsForGuessing; they would need to be categorized as unambiguous
    % or not to do that. We do not attempt to make ambiguous pairs out of these.
    dtFmt = getDatetimeSettings('defaultdateformat');
    dtTmFmt = getDatetimeSettings('defaultformat');
    spFmts = matlab.io.spreadsheet.internal.dateFormats('all');
    extraFmts = unique([spFmts(:); {dtFmt}; {dtTmFmt}], 'stable');
    for i = 1:numel(extraFmts)
        fmt = extraFmts{i};
        if tryOneFmt(fmt), return, end % quit if this format works
    end
    
    % None of the formats worked
    error(message('MATLAB:datetime:ParseErrs','')); % caught by constructor and elaborated on
end%if isempty(tryStr)

% ----------------------------------------------------------------------- %

    function tf = tryOneFmt(fmt)
        % Try to parse the first timestamp with the specified format. If that
        % succeeds, parse all of the timestamps using that format.
        import matlab.internal.datetime.createFromString
        try
            t = createFromString(tryStr,fmt,2,tz,locale,pivot); % error, don't return NaT
            % The test string succeeded
            tf = true;
            if ~isscalar(dateStrs)
                % This may return NaTs, or may error, as requested
                t = createFromString(dateStrs,fmt,errMode,tz,locale,pivot);
            end
        catch ME
            if any(ME.identifier == ["MATLAB:datetime:ParseErr","MATLAB:datetime:ParseErrs"])
                % The test string failed, give up on this format
                tf = false;
            else
                throwAsCaller(ME);
            end
        end
    end

end
