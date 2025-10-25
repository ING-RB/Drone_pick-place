function stats = getSummaryStats(data, type)
    % getSummaryStats get a set of summary statistics for the vector passed
    % in.
    % Will only work with numeric, categorical, logical or string/cellstrs

    % Copyright 2021-2024 The MathWorks, Inc.

    arguments
        data;
        type string {mustBeScalarOrEmpty} = string.empty;
    end

    NUM_UNIQUE_INTS_FOR_HIST = 100;
    PERCENT_UNQIUE_INTS_FOR_HIST = 0.1;

    stats = struct;
    stats.min = "NaN";
    stats.max = "NaN";
    stats.mean = "NaN";
    stats.numUnique = "0";
    stats.numMissing = string(sum(ismissing(data), 'all'));
    stats.type = string(internal.matlab.datatoolsservices.FormatDataUtils.getClassString(data));
    stats.statsType = type;


    if isempty(data) ||...
            (isobject(data) && ~isnumeric(data) && ~iscategorical(data) && ~isstring(data)...
            && ~isdatetime(data) && ~isduration(data) && ~iscalendarduration(data) && ~isenum(data)) ||...
            (iscell(data) && ~iscellstr(data)) || isstruct(data)
        return;
    end

    statsType = "numeric";
    allIntValues = isnumeric(data) && all(isequaln(floor(data), data), 'all');
    if ~isempty(type)
        statsType = type;
    else
        if isnumeric(data) || isduration(data) || isdatetime(data) || iscalendarduration(data)
            try
                dataSize = length(data);
                numUnique = length(data);
                if (allIntValues)
                    % Only compute this if al ints, this is
                    % expensive
                    numUnique = length(unique(data));
                end
                if (allIntValues && ...
                        (numUnique < NUM_UNIQUE_INTS_FOR_HIST) || ...
                        numUnique <= (PERCENT_UNQIUE_INTS_FOR_HIST & dataSize))
                    statsType = "categorical";
                end
            catch
                % Some numeric datatypes may not support unique
                % like the half datastype. leave these as plot type
            end
        elseif isstring(data) | iscellstr(data) | ischar(data)...
                | iscategorical(data) | islogical(data) | isenum(data)...
                | all(ismissing(data),'all') | isenum(data)
            statsType = "categorical";
        end
    end

    stats.statsType = statsType;

    if statsType == "categorical"
        if ~iscategorical(data)
            % Categorical will fail with the string "<missing>" so replace
            % them all with ##missing## then replace back at the end
            strData = string(data);
            strData(strData == "<missing>") = "##@@missing@@##";
            catData = categorical(strData); % Cast to string for enums
        else
            catData = data;
        end
        cats = categories(catData);
        
        % Check for all blank strings g3052447
        if ~isempty(data) && isempty(cats) || isstring(data)
            ndata = rmmissing(data);

            if isempty(ndata)
                cats = string.empty;
                counts = [];
            else
                ndata = regexprep(ndata, "(^ +| +$)", '${strrep(string($0), " ", "##@@space@@##")}');
                ndata(ndata == "<missing>") = "##@@missing@@##";
                ndata(ndata == "") = "##@@emptyString@@##";
                cats = unique(ndata);
                % Categorical trims strings so we need to replace leading
                % and trailing spaces in order to get accurate histcounts
                counts = histcounts(categorical(ndata), cats);
                cats = strrep(cats, "##@@space@@##", " ");
                cats(cats == "##@@emptyString@@##") = "";
            end
        else
            [counts, cats] = histcounts(catData);
        end

        cats(cats == "##@@missing@@##") = {'"<missing>"'};


        if ~all(ismissing(counts), 'all') && ~allIntValues
            stats.min = string(min(counts));
            stats.max = string(max(counts));
            stats.mean = string(mean(counts));
            % stats.median = string(median(counts));
            stats.numUnique = string(length(cats));
        elseif allIntValues
            try
                stats.min = string(min(data));
                stats.max = string(max(data));
                stats.mean = string(mean(data, 'omitnan'));
                % stats.median = string(median(data), 'omitmissing');
                stats.std = string(std(data, 'omitnan'));
                stats.numUnique = string(length(cats));
            catch
                % Cast stats to double for numerics like half which string constructor
                % doesn't accept
                stats.min = string(min(double(data)));
                stats.max = string(max(double(data)));
                stats.mean = string(mean(double(data), 'omitnan'));
                % stats.median = string(median(double(data), 'omitmissing'));
                stats.std = string(std(double(data), 'omitnan'));
                stats.numUnique = string(length(cats));
            end
        else
            % Edge case all missing data
            stats.min = "0";
            stats.max = "0";
            stats.mean = "0";
            % stats.median = "0";
            stats.numUnique = "0";
        end
    else
        if (~iscalendarduration(data))
            try
                stats.min = string(min(data));
                stats.max = string(max(data));
                stats.mean = string(mean(data, 'omitnan'));
                % stats.median = string(median(data, 'omitnan'));
                stats.std = string(std(data, 'omitnan'));
            catch
                % Cast stats to double for numerics like half which string constructor
                % doesn't accept
                stats.min = string(min(double(data)));
                stats.max = string(max(double(data)));
                stats.mean = string(mean(double(data), 'omitnan'));
                % stats.median = string(double(median(data, 'omitnan')));
                stats.std = string(double(std(double(data), 'omitnan')));
            end
        else
            stats.min = string(calMin(data));
            stats.max = string(calMax(data));
        end
    end
end



function lt = calLT(cd1, cd2)
    [y1,m1,d1,t1] = split(cd1, {'years', 'months', 'day', 'time'});
    [y2,m2,d2,t2] = split(cd2, {'years', 'months', 'day', 'time'});

    lt = false;
    d1 = datetime(y1, m1, d1) + t1;
    d2 = datetime(y2, m2, d2) + t2;
    if (d1 <= d2)
        lt = true;
    end
end

function lt = calGT(cd1, cd2)
    lt = ~calLT(cd1, cd2);
end

function mv = calMin(ca)
    mv = ca(1);
    for c = 2:length(ca)
        if (calLT(ca(c), mv))
            mv = ca(c);
        end
    end
end

function mv = calMax(ca)
    mv = ca(1);
    for c = 2:length(ca)
        if (calGT(ca(c), mv))
            mv = ca(c);
        end
    end
end


