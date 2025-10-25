function logOpenFig(figData, varName)
%   This function is unsupported and might change or be removed without
%   notice in a future version.

%  Copyright 2024 The MathWorks, Inc.

arguments
    figData (1,1) struct
    varName (1,1) string
end

meta_data = [];
if isfield(figData, 'meta_data')
    % FIG-files created in R2023a or newer contain meta-data.
    if isstruct(figData.meta_data) ...
            && isscalar(figData.meta_data)
        meta_data = figData.meta_data;
    else
        % The meta data is in an unexpected format. Use an empty struct to
        % differentiate "invalid meta data" from "no meta data".
        meta_data = struct();
    end
end

[uuid, createdInRelease] = processMetaData(meta_data, varName);

data = struct(...
    'fig_created_in', createdInRelease, ...
    'fig_uuid', uuid, ...
    'fig_variable_name', varName);

dataId = matlab.ddux.internal.DataIdentification("ML", "ML_GRAPHICS", "ML_GRAPHICS_OPENFIG");
matlab.ddux.internal.logData(dataId, data);

end

function [uuid, str] = processMetaData(meta_data, varName)

if isfield(meta_data, 'uuid') ...
        && isa(meta_data.uuid, 'string') ...
        && isscalar(meta_data.uuid) ...
        && ~ismissing(meta_data.uuid)
    % FIG-files created in R2023a or newer contain meta-data with a uuid.
    uuid = meta_data.uuid;
elseif isstruct(meta_data)
    % The meta data is in an unexpected format.
    uuid = "Invalid";
else
    % No meta data was found (most likely pre-R2023a FIG-file).
    uuid = "";
end

if isfield(meta_data, 'matlab_release')
    if isstruct(meta_data.matlab_release) ...
            && isscalar(meta_data.matlab_release)
        % FIG-files created in R2023a or newer contain meta-data with
        % release information.
        str = generateprocessMetaDataReleaseString(meta_data.matlab_release);
    else
        % The release data is in an unexpected format.
        str = "Invalid";
    end
elseif startsWith(varName, "hgM")
    % FIG-files created in R2014b or newer contain a variable with a name
    % that starts with "hgM". If this variable is present, then it will be
    % used to access the figure data.
    str = "R2014b";
elseif startsWith(varName, "hgS")
    % All FIG-files should contain a variable that starts with hgS, but
    % this variable is only used if there is no variable that starts with
    % hgM, which should only happen if the FIG-file was created in R2014a
    % or earlier.
    str = "R2014a";
else
    % This is an invalid case that should not match any valid FIG-file.
    str = "Unrecognized";
end

end

function str = generateprocessMetaDataReleaseString(releaseData)

% The Date is redundant with the other fields, and it is stored as a
% datetime object, so remove it.
if isfield(releaseData, "Date")
    releaseData = rmfield(releaseData,"Date");
end

% Extract the remaining information and concatenate it into a
% string vector. This will convert any non-string fields (such as
% "Update") into a string. This is written to automatically include
% other fields if new fields are added in later releases.
releaseData = string(struct2cell(releaseData));
releaseData = releaseData(~ismissing(releaseData));
str = strjoin(releaseData, " ");

end

% LocalWords: datetime hgM hgS
