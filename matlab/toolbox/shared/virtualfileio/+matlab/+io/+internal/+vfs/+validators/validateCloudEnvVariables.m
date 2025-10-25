function validateCloudEnvVariables(path)
%VALIDATECLOUDENVVARIABLES   Validates if cloud environement variables are set.
%
%   NOTE: Only use this function if you know that an error has already
%   occurred during reading/writing. This function should NOT be called
%   upfront before doing reading or writing because there are public S3
%   buckets and public Azure blob containers that don't need environment
%   variables to be set, and this function will error in those cases.
%
%   This is a helper function that validates if the cloud environment variables
%   are non-empty for S3 and Azure.
%     1. For Amazon S3, we need to check if both AWS_ACCESS_KEY_ID and
%        AWS_SECRET_ACCESS_KEY are non-empty
%     2. For Microsoft Azure, we need to check if either MW_WASB_SECRET_KEY or
%        MW_WASB_SAS_TOKEN are non-empty

%   Copyright 2018-2022 The MathWorks, Inc.

    schema = regexpi(path, "^s3://|^wasbs://|^wasb://", 'match', 'once');
    if isempty(schema)
        return;
    end
    switch lower(schema)
        case 's3://'
            % This file is created by the AWS CLI when setting up the
            % machine. If set, the user typically doesn't need to also set
            % environment variables.
            if matlab.io.internal.vfs.validators.hasS3CredentialsFile()
                return;
            end
            % Both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set
            if isempty(getenv('AWS_ACCESS_KEY_ID')) || isempty(getenv('AWS_SECRET_ACCESS_KEY'))
                error(message('MATLAB:virtualfileio:path:s3EnvVariablesNotSet', path));
            end
        case {'wasb://', 'wasbs://'}
            % Either MW_WASB_SECRET_KEY or MW_WASB_SAS_TOKEN must be set
            if isempty(getenv('MW_WASB_SECRET_KEY')) && isempty(getenv('MW_WASB_SAS_TOKEN'))
                error(message('MATLAB:virtualfileio:path:azureEnvVariablesNotSet', path));
            end
    end
end
