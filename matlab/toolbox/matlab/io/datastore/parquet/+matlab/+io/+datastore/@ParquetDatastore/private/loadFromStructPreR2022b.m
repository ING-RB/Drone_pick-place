function obj = loadFromStructPreR2022b(obj, S)
%loadFromStructPreR2022b   Compatibility shim for loading ParquetDatastore from R2022a and
%   older into R2022b and newer.

%   Copyright 2022 The MathWorks, Inc.

    % Recover exact partition state if ParquetDatastore was in rowgroup or numeric
    % ReadSize.
    if isnumeric(obj.ReadSize) || obj.ReadSize == "rowgroup"
        cls = "matlab.io.datastore.internal.RepeatedDatastore";
        rptds = getUnderlyingDatastore(obj.UnderlyingDatastore, cls);
        rptds.RepetitionIndices = S.Partitioner.RowGroups;
    end

    % PreserveVariableNames was added in R2019b.
    % VariableNamingRule was added later, but is dependent on
    % PreserveVariableNames so it doesn't need explicit setting.
    if isfield(S, "PreserveVariableNames")
        obj.PreserveVariableNames = S.PreserveVariableNames;
    end

    % Recover RowTimes and OutputType state. OutputType is dependent on
    % RowTimes, so it will be set to "timetable" if RowTimes is set.
    % Pre-R2019b, this is a pre-normalization name.
    if ~isfield(S, "PreserveVariableNames") && ~isempty(S.NameValueStruct.RowTimes)
        obj.RowTimes = S.NameValueStruct.RowTimes;
    end

    % VariableNames got renamed to PrivateVariableNames at some point.
    if isfield(S, "PrivateVariableNames")
        obj.VariableNames = S.PrivateVariableNames;
    else
        obj.VariableNames = S.VariableNames;
    end

    % SelectedVariableNamesIdx has been on
    % ParquetDatastore since the first release. So it should always be
    % present here.
    obj.SelectedVariableNames = obj.VariableNames(S.SelectedVariableNamesIdx);

    % Post-normalization case for RowTimes.
    if isfield(S, "PreserveVariableNames") && ~isempty(S.NameValueStruct.RowTimes)
        obj.RowTimes = S.NameValueStruct.RowTimes;
    end

    % RowFilter was added in R2022a.
    if isfield(S, "RowFilter")
        obj.RowFilter = S.RowFilter;
    end

    % Reset the object once more, just as a sanity check.
    obj.reset();
end