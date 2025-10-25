function licStruct = getLicInfo(prodnameCell)
%getLicInfo Get license information about a product.
%   S = getLicInfo({product1, product2, ..., productN}) returns the list of
%   license numbers and expiration dates for each given product name.

%   Copyright 2011-2022 The MathWorks, Inc.


% Check whether user has provided a cellstring input.
prodnameCell = convertStringsToChars(prodnameCell);
if ischar(prodnameCell)
    prodnameCell = {prodnameCell};
elseif ~iscellstr(prodnameCell)
    error(message('MATLAB:string'));
end

nProducts = length(prodnameCell);

% Initialize an empty struct.
licStruct = localCreateEmptyLicenseStruct(nProducts);

for idx = 1:nProducts
    currBasecode = matlab.internal.product.getBaseCodeFromProductName(prodnameCell{idx});
    if isempty(currBasecode)
        licStruct(idx) = localCreateUnknownLicenseStruct;
    else
        featureInfo = matlab.internal.licensing.getFeatureInfo(currBasecode);
        if isempty(featureInfo)
            licStruct(idx) = localCreateUnknownLicenseStruct;
        else
            licStruct(idx) = localCreateKnownLicenseStruct(featureInfo);
        end
    end
end

end

function emptyStruct = localCreateEmptyLicenseStruct(n)

c = cell(0, n);
emptyStruct = localCreateLicenseStruct(c, c);

end

function unknownStruct = localCreateUnknownLicenseStruct

unknownStruct = localCreateLicenseStruct({'unknown'}, {''});

end

function knownStruct = localCreateKnownLicenseStruct(prodLicenseInfo)

% Put the license info in the output struct, and convert
% the trials to use 'T' and the entitlment id.
% Remove duplicate license numbers at the same time.
% Return a sorted struct in order of MATLAB, professional, then trials.
mlLicense = license;
mlEntId = matlab.internal.licensing.getCheckedOutFeatureEntitlementID('MATLAB');
mlElement = cell(2, 0);
nLicenses = length(prodLicenseInfo);
licCell = cell(2, nLicenses);  % Row 1 - license, Row 2 - expiration
isTrialLicense = false(1, nLicenses);
nLicsToKeep = 0;
for idx = 1:nLicenses
    isCurrentLicenseATrial = false;
    foundMlEntry = false;
    
    % Get the license number.  If it is DEMO, then use the entitlement ID
    % and add the 'T'.
    tmpLicNum = prodLicenseInfo(idx).license_number;
    if strcmpi(tmpLicNum, 'DEMO')
        isCurrentLicenseATrial = true;
        tmpLicNum = ['T', prodLicenseInfo(idx).entitlement_id];
    end

    % Check if we have the license/entitlement that MATLAB is currently using.
    if (isCurrentLicenseATrial) 
        foundMlEntry = strcmpi(prodLicenseInfo(idx).entitlement_id, mlEntId);
    else
        foundMlEntry = strcmpi(prodLicenseInfo(idx).license_number, mlLicense);
    end

    if (foundMlEntry)
        mlElement = {tmpLicNum; prodLicenseInfo(idx).expdate};
    elseif ~any(strcmp(tmpLicNum, licCell(1,:)))
        % Store the license info only if we do not already have it (and it isn't MATLAB).
        nLicsToKeep = nLicsToKeep + 1;
        licCell(:, nLicsToKeep) = {tmpLicNum; prodLicenseInfo(idx).expdate};
        isTrialLicense(nLicsToKeep) = isCurrentLicenseATrial;
    end
end
licCell = licCell(:, 1:nLicsToKeep);
isTrialLicense = isTrialLicense(1:nLicsToKeep);

% Sort list.  This MATLAB's license goes first, then professional licenses
% in descending order, then trials in descending order of expiration date.
profElements = licCell(:, ~isTrialLicense); % List of professional licenses
sortedProfElements = localSortOnLicenseNumbers(profElements);

trialElements = licCell(:, isTrialLicense); % List of trial licenses
sortedTrialElements = localSortOnEntitlementId(trialElements);

sortedElements = [mlElement, sortedProfElements, sortedTrialElements];
knownStruct = localCreateLicenseStruct(sortedElements(1,:), sortedElements(2,:));

end

function licStruct = localCreateLicenseStruct(licCell, expCell)

licStruct = struct('license_number', {licCell}, ...
                   'expiration_date', {expCell});

end

function sortedLicCell = localSortOnLicenseNumbers(licCell)
if isempty(licCell)
    sortedLicCell = licCell;
    return;
end

% Split the numeric (e.g., '12345') and character (e.g., 'student') parts,
% and convert the numeric part to numbers for descended sorting.
licNums = str2double(licCell(1,:));
isCharIdx = isnan(licNums);

% Sort numeric arrays, then convert them back to strings.
numericPart = licCell(:, ~isCharIdx);
[~, sortedNumericIndices] = sort(licNums(~isCharIdx), 'descend');
sortedNumericPart = numericPart(:, sortedNumericIndices);

% Sort character arrays.
characterPart = licCell(:, isCharIdx);
[~, sortedCharacterIndices] = sort(characterPart(1,:));
sortedCharacterPart = characterPart(:, sortedCharacterIndices);

sortedLicCell = [sortedNumericPart, sortedCharacterPart];

end

function sortedLicCell = localSortOnEntitlementId(licCell)

if isempty(licCell)
    sortedLicCell = licCell;
    return;
end

licDates = datenum(licCell(2,:), 'dd-mmm-yyyy');
% Perpetual licenses use the date '01-jan-0000', which corresponds to a
% datenum of 1.  To ensure that perpetual licenses are listed first,
% convert datenums of 1 to Inf.
licDates(licDates == 1) = Inf;

[~, sortedDateIndices] = sort(licDates, 'descend');
% Note: Use the original licCell to index into because we transformed the
% expiration_date, and indexing into licDates gives datenum output.
sortedLicCell = licCell(:, sortedDateIndices);

end
