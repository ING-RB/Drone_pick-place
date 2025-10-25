function t = autoConvertStrings(s,template,requireScalar)
%AUTOCONVERTSTRINGS Convert text array into a datetime or duration array.
%   T = AUTOCONVERTSTRINGS(S,TEMPLATE,REQUIRESCALAR) converts string or
%   char array S into datetime or duration array T. If S represents
%   datetime data then the format of datetime TEMPLATE is used to parse S.
%   Specify REQUIRESCALAR (false by default) force an error when S is not
%   scalar.

%   Copyright 2014-2020 The MathWorks, Inc.

if ischar(s), s = {s}; end
% infinities should be treated as datetime.
isinf = matches(s,["inf" "+inf" "-inf"],"IgnoreCase",true);
isnanLiteral = matches(s,["nan" "+nan" "-nan"],"IgnoreCase",true);
isblank = ismissing(s) | strlength(s)==0;

% Normally, only scalar text (char vector or scalar string) should be
% automatically converted to datetime or duration. However, the
% 'requireScalar' flag provides caller a toggle to control this.
% - cellstr conversion is allowed as legacy behavior (e.g. in relops)
% - assignment of non-scalar string is allowed (analogy to mixed numeric assignment)
if (nargin < 3), requireScalar = false; end
if requireScalar && ~isscalar(s)
    error(message('MATLAB:datetime:AutoConvertStringScalar'));
end

if any(~isinf(:) & ~isblank(:))
    try
        % If the text is a duration, then use it as duration and not as a
        % datetime. This is for text formatted as 'hh:mm:ss' and 'dd:hh:mm:ss'.
        % Without the duration checks, 'hh:mm:ss' would otherwise be treated as 
        % time-of-day leading to unexpected results.
        t(~isinf) = duration(s(~isinf)); % Will error if s contained only literal INF

        % If the only data that would be converted to duration is the INF data, 
        % then we should have been using datetime, separating these comparisons
        % makes sure the first call to duration will error when expected. 
        % If duration succeeded above, then call duration on the inf(s) to get 
        % the correct sign in the output data.
        t(isinf) = duration(s(isinf)); % this should always pass.
    catch
        % If we get here, there were not auto convertable durations. 
        % Try to convert to datetime instead
        t = [];
    end

    if isduration(t) % will be double if duration errored.
        % If we had duration text with infinity, and the infinity was the
        % first non-blank element, then we should ignore that, and treat the
        % whole things as datetime.
        firstConverted = max([find(isfinite(t(:)) | isnanLiteral(:),1) 0]);
        firstInf = max([find(isinf,1) 0]);
        firstNonBlank = max([find(~isblank,1) 0]);
        
        if firstConverted == firstNonBlank
            % First non-blank is also non-finite, keep the duration results
            return
        end
        if firstInf > firstConverted 
            % if the first "inf" text appears after the first finite value
            % and there were other non-blank elements then we have a case
            % where there is other text before the duration text that
            % should be converted to datetime first.
            throwAsCaller(MException(message('MATLAB:datetime:CompareTimeOfDay')));
        end
        % if we get here, redo with datetime. replace timer formatted data
        % with NaT.
        s(isfinite(t)) = {'NaT'};
    end
end

try
    t = template;
    format = getDisplayFormat(template);
    % Format and TimeZone taken from the template. The locale and
    % pivot year are the default. Error if parse fails -- these
    % are strings converted on-the-fly, no point in creating NaT
    t.data = matlab.internal.datetime.createFromString(s,format,2,t.tz);
    return;
catch
end

try
    t = datetime(s,'TimeZone',template.tz); % try once more, see if we can guess the format
catch ME
    % Look for UnrecognizedDateString[s], UnrecognizedDateString[s]WithLocale,
    % or UnrecognizedDateString[s]SuggestLocale, or ParseErrs when the datetime is
    % UTCLeapSeconds.
    if ~isempty(strfind(ME.identifier,'MATLAB:datetime:UnrecognizedDateString')) ...
            || (ME.identifier == "MATLAB:datetime:ParseErrs")
        ME = getAutoConvertError(s);
    end
    throwAsCaller(ME);
end

end
function ME = getAutoConvertError(s)
if isscalar(s)
    ME = MException(message('MATLAB:datetime:AutoConvertString',s{1}));
else
    ME = MException(message('MATLAB:datetime:AutoConvertStrings'));
end
end
