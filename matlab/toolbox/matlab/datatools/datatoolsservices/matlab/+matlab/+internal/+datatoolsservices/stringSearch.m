function [matchIndex, startIndex, endIndex] = stringSearch(val, pat, NVPairs)
    arguments
        val (:,1)
        pat (1,1) string
        NVPairs.IgnoreCase (1,1) logical = true
        NVPairs.WholeWord (1,1) logical = false
        NVPairs.Regex (1,1) logical = false
        NVPairs.UseNumericDisplay (1,1) logical = false
        NVPairs.NumericFormat (1,1) string = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat()
    end

    try
        le = lasterror;
        str = string(val);
    catch
        lasterror(le);
        % Some numeric types don't have string constructors
        if (isnumeric(val))
            str = string(double(val));
        else
            str = repmat(string, height(val), 1);
        end
    end

    if isnumeric(val) || isduration(val) || iscalendarduration(val)
        try
            le = lasterror;
            str(ismissing(val)) = "NaN";
        catch
            % Some 
            lasterror(le);
        end
    elseif isdatetime(val)
        str(ismissing(val)) = "NaT";
    end

    args = namedargs2cell(NVPairs);
    [matchIndex, startIndex, endIndex] = doStrMatch(str, pat, args{:});

    if isnumeric(val) && NVPairs.UseNumericDisplay
        [str, e] = matlab.internal.display.numericDisplay(val, Format=NVPairs.NumericFormat);
        if (e > 1)
            e = log10(e);
            str = str + "e+" + num2str(e,'%02d');
        elseif (e < 0)
            e = log10(abs(e));
            str = str + "e-" + num2str(e,'%02d');
        end

        [matchIndex1, startIndex1, endIndex1] = doStrMatch(str, pat, args{:});
        matchIndex = matchIndex1 | matchIndex;
        startIndex = {startIndex{:}, startIndex1{:}};
        endIndex = {endIndex{:}, endIndex1{:}};
    end

end

function [matchIndex, startIndex, endIndex] = doStrMatch(str, pat, NVPairs)
    arguments
        str (:,1)
        pat (1,1) string
        NVPairs.IgnoreCase (1,1) logical = true
        NVPairs.WholeWord (1,1) logical = false
        NVPairs.Regex (1,1) logical = false
        NVPairs.UseNumericDisplay (1,1) logical = false
        NVPairs.NumericFormat (1,1) string = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat()
    end

    matchIndex = [];
    startIndex = [];
    endIndex = [];
    patLen = strlength(pat);

    if (NVPairs.WholeWord && ~NVPairs.Regex)
        matchIndex = matches(str, pat, "IgnoreCase", NVPairs.IgnoreCase);
        if nargout >= 2
            startIndex = zeros(length(matchIndex), 1);
            startIndex(matchIndex) = 1;
            startIndex = num2cell(startIndex);
            startIndex(~matchIndex) = {double.empty};
        end

        if nargout >= 3
            endIndex = zeros(length(matchIndex), 1);
            endIndex(matchIndex) = patLen;
            endIndex = num2cell(endIndex);
            endIndex(~matchIndex) = {double.empty};
        end
     elseif (NVPairs.Regex)
            if NVPairs.IgnoreCase
                [startIndex, endIndex]  = regexpi(str, pat, 'start', 'end');
            else
                [startIndex, endIndex]  = regexp(str, pat, 'start', 'end');
            end
            if ~iscell(startIndex)
                startIndex = num2cell(startIndex);
                endIndex = num2cell(endIndex);
            end
            matchIndex = false(length(startIndex), 1);
            for i=1:length(matchIndex)
                matchIndex(i) = ~isempty(startIndex{i});
            end
    else
        matchIndex = contains(str, pat, IgnoreCase=NVPairs.IgnoreCase);
        if nargout >= 2
            if NVPairs.IgnoreCase
                [startIndex, endIndex]  = regexpi(str, regexptranslate('escape', pat), 'start', 'end');
            else
                [startIndex, endIndex]  = regexp(str, regexptranslate('escape', pat), 'start', 'end');
            end

            if ~iscell(startIndex)
                startIndex = {startIndex};
            end

            if ~iscell(endIndex)
                endIndex = {endIndex};
            end

            % Since this is a substring search the contains is the "truth"
            startIndex(matchIndex == 0) = {[]};
            endIndex(matchIndex == 0) = {[]};
        end
    end
end
