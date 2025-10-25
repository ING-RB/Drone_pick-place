function [dtFmt,dtTmFmt,dtTmMsFmt] = dateFormats(fmttype)
% DATEFORMATS   Return date, date & time, and date & time with millis formats.
%
%   The purpose of this function is to provide compatibility shim to preserve
%   the format for date strings produced on Windows prioir to 16a and preserve
%   their format in datetimes produced via the interactive mode.
%
%   On non-Windows platforms, this returns the user preference datetime formats
%   for setting the formats on datetimes.
%
%   fmttype can be:
%
%   - 'osdep'
%   On Widnows, gets the short date long time formats and adds milliseconds
%   to them. On other platforms, does the behaviour under 'default'.
%
%   - 'default'
%   Gets the datetime preference settings and returns them but adds
%   milliseconds to the date and time format.
%
%   - 'all'
%   Returns all the possible formats for that platforms in a single cell
%   array in the first output. On Windows, it will return both 'osdep' and
%   'default' formats. On other platforms, returns 'default' formats.
%
%   Returns a column cell vector.
%

% Copyright 2015 The MathWorks, Inc.

persistent pc;

if isempty(pc)
    pc = ispc;
end

if pc && strcmp(fmttype, 'osdep')
    [dtFmt, dtTmFmt] = windowsFormats();
elseif strcmp(fmttype, 'default') || strcmp(fmttype, 'osdep')
    [dtFmt, dtTmFmt] = userPreferenceFormats();
elseif strcmp(fmttype, 'all')
    % return all formats in a single cell array as the first output
    nargoutchk(0, 1);
    if pc
        fmts = cell(6, 1);
        [wind, windt] = windowsFormats();
        [prefd, prefdt] = userPreferenceFormats();
        fmts{1} = wind;
        fmts{2} = windt;
        fmts{3} = addMillis(windt);
        fmts{4} = prefd;
        fmts{5} = prefdt;
        fmts{6} = addMillis(prefdt);
    else
        fmts = cell(3, 1);
        [prefd, prefdt] = userPreferenceFormats();
        fmts{1} = prefd;
        fmts{2} = prefdt;
        fmts{3} = addMillis(prefdt);
    end
    dtFmt = fmts;
    return;
else
    error('Invalid fmttype parameter passed in');
end

dtTmMsFmt = addMillis(dtTmFmt);

end

% locals

function dtTmMsFmt = addMillis(dtTmFmt)
    if isempty(strfind(dtTmFmt, 'S'))
        % match any 's' occurences and replace with that many 's' with '.SSS'
        % appended
        dtTmMsFmt = regexprep(dtTmFmt, '(s+)', '$1.SSS');
    else
        dtTmMsFmt = dtTmFmt;
    end
end

function [dateFmt, dateTimeFmt] = windowsFormats()
    persistent dtFmt;
    persistent dtTmFmt;
    if isempty(dtFmt) || isempty(dtTmFmt)
        [dFmt, tFmt] = matlab.io.spreadsheet.internal.systemDateFormats();
        dFmt = fixDayOfWeek(dFmt);
        tFmt = fixTimeAffixes(tFmt);
        tFmt = fixTimeMarker(tFmt);
        dtFmt = dFmt;
        dtTmFmt = [dFmt, ' ', tFmt];
    end
    dateFmt = dtFmt;
    dateTimeFmt = dtTmFmt;
end

function [dtFmt, dtTmFmt] = userPreferenceFormats()
    % Get the user preference
    persistent dtSettings;
    if isempty(dtSettings)
        s = settings;
        dtSettings = s.matlab.datetime;
    end
    dtFmt = dtSettings.DefaultDateFormat.ActiveValue;
    dtTmFmt = dtSettings.DefaultFormat.ActiveValue;
end

function val = fixDayOfWeek(val)
    val = strrep(val, ''' (''eee'')''', '');
end

function val = fixTimeAffixes(val)

%
% German long times display 'h' and 'Uhr' but Excel/COM does not show them
% However, they show Galician ''' and '''''.
%
% Basically, COM display would always take away hour prefixes but leave the
% minute and second affixes be.
%
    % norwegian prefix
    val = strrep(val, '''kl ''', '');

    % dutch suffix
    val = strrep(val, ''' uur''', '');
    
    % germanic suffixes
    val = strrep(val, ''' h''', '');
    val = strrep(val, ''' Uhr''', '');
    val = strrep(val, ''' Auer''', '');
end

function tmfmt = fixTimeMarker(tmfmt)
    %
    % this only needs to be done on non-KO, non-ZH, non-JA locales
    % where the time marker appears before HMS in the Control Panel format
    % but really should appear after (as per XLSREAD).
    %
    % this is to maintain compatibility with the old XLSREAD code.
    %
    if ~any(strncmpi(matlab.internal.display.language(), {'zh', 'ko', 'ja'}, 2))
        
        % disqualify code below if assumptions don't match up
        if numel(tmfmt) < 3 || isempty(strfind(tmfmt, 'a H')) || isempty(strfind(tmfmt, 'a h'))
            return;
        end
        
        hmsPos = find(tmfmt == 'H' | tmfmt == 'h');
        if ~isempty(hmsPos), hmsPos = hmsPos(1); else hmsPos = 0; end
        tmkPos = find(tmfmt == 'a');
        if ~isempty(tmkPos), tmkPos = tmkPos(1); else tmkPos = 0; end
        if tmkPos < hmsPos
            tmfmt = [tmfmt(hmsPos:end), ' ', tmfmt(1:hmsPos-2)]; % -2 for the space
        end
    end
end
