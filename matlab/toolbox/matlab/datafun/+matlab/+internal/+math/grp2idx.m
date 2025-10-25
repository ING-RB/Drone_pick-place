function [gidx,ng,gdata] = grp2idx(group,inclnan,inclempty)
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%
% GRP2IDX  Create index vector from a grouping variable.
%
%   [GIDX,NG,GDATA] = GRP2IDX(GROUP,INCLNAN,INCLEMPTY) creates an index  
%   vector from the grouping variable GROUP. 
%
%   Inputs:
%       GROUP is a vector. It can be a categorical, numeric, logical,
%       datetime, duration, calendarDuration, enum, cellstr, char, or
%       string vector. Datatypes not included in this list that support
%       unique may also work.
%
%       INCLNAN is a true/false flag about whether to include NaNs present 
%       in the group.
%
%       INCLEMPTY is a true/false flag about whether to include values not
%       represented in categorical, enum, or logical data when counting
%       GIDX and in GDATA.
%
%   Outputs:
%       GIDX is a vector taking integer values from 1 up to the number NG  
%       of distinct groups or NaN for excluded values. 
%
%       NG is an integer containing the number of groups
%
%       GDATA is a vector of the same type as GROUP containing the unique
%       values within GROUP

%   Copyright 2017-2023 The MathWorks, Inc.


% If group is char matrix or row vector throw nice error pointing to
% cellstrs
if ischar(group) && size(group,2) > 1
    error(message('MATLAB:findgroups:CharData'));
end

% If group not vector error
if ~isvector(group)
    error(message('MATLAB:findgroups:GroupingVarNotVector'));
end

% If we have row input move to column for easier processing
if isrow(group) && ~istabular(group)
    group = group(:);
end

ng = [];

if iscategorical(group)
    [gidx,cats] = matlab.internal.math.categoricalAccessor.codesAndCats(group);
    ncats = length(cats);
    % accumarray is faster with integer input, leave gidx as uintNN for now.
    missings = ~gidx; % find zero codes
    anyMissings = any(missings);

    % The missing-group exists only if requested and missings present in group.
    haveMissingGroup = inclnan && anyMissings;

    % Adjust the zero indices corresponding to missing values if there are any.
    if haveMissingGroup
        % If missing elements form their own group, create a new missing-group
        % at the end, and return the index of that group for those missing elements.
        gidx(missings) = ncats + 1;
    elseif anyMissings % but ~inclnan
        % If missing elements are being treated as missing (not their own
        % group), we will ultimately replace the zero internal codes and return
        % NaN group indices for missing elements. But that happens after gidx
        % becomes double.
        if ~inclempty
            % However, if empty groups are not being preserved, need to overwrite
            % zeros with a finite value to make accumarray happy when it's called
            % to find the empty groups. Can't just remove the zeros, need to keep
            % track of their locations so we know where to return NaNs.
            gidx(missings) = ncats + 1; 
        end
    end

    % At this point gidx is still uintNN and elements corresponding to missing data
    % in group contain ...
    %                           |      inclempty
    %      anyMissings  inclnan |   true       false
    %      ---------------------|--------------------
    %             true     true | ncats+1     ncats+1
    %                     false |    0        ncats+1 <- this row will become NaNs
    %            false     true |   N/A         N/A
    %                     false |   N/A         N/A
    %

    % Figure out how many groups we have.
    if inclempty
        % If empty groups are being preserved, it's the number of categories,
        % plus maybe one more for the missing-group.
        ng = ncats + haveMissingGroup;
    else
        % Otherwise find how many non-empty categories, plus maybe the new category
        % for missings (if requested). Don't count the dummy category.
        counts = accumarray(gidx,1,[ncats+1 1]);
        if anyMissings && ~inclnan
            counts(end) = 0; % empty out that dummy category
        end
        nonEmptyGroups = (counts > 0);
        ng = sum(nonEmptyGroups);
    end

    % Turn the integer codes into double group indices.
    allGroupsNonEmpty = (ng == ncats + haveMissingGroup);
    if inclempty || allGroupsNonEmpty
        % If including empty groups, or if all groups are represented (including
        % the missing-group when requested), no need to squeeze out empty categories
        % in the category codes -- the codes _are_ the group indices.
        gidx = double(gidx);
        if haveMissingGroup
            % gidx(missings) was already adjusted to ng == ncats+1.
        elseif anyMissings % but ~inclnan
            gidx(missings) = NaN; % replace zeros from the original codes
        end
    else
        % Reassign the non-empty categories' indices to make them contiguous,
        % thus ignoring categories not present in the data
        groupIdxMap = cumsum(nonEmptyGroups);
        if anyMissings && ~inclnan
            % If missing values are being treated as missing, not their own group,
            % replace the dummy ncats+1 value and return NaN indices.
            groupIdxMap(ncats+1) = NaN;
        end
        gidx = groupIdxMap(gidx); % convert uintNN to double
    end

    if nargout > 2
        % Create gdata as a categorical with exactly the same categories as in
        % the input, and one element for each group in the output.
        if inclempty
            gdataCodes = (1:ng)'; % elements for all of the original categories, plus maybe one more missing element
        else
            gdataCodes = find(nonEmptyGroups); % elements only for non-empty categories, plus maybe one more missing element
            gdataCodes = gdataCodes(:); % force 0x1 col vector when gdataCodes is empty
        end
        
        if haveMissingGroup
            % When a missing group if requested and missings are present, set the
            % element in gdata that represents that group to missing.
            gdataCodes(ng) = 0;
        end

        gdata = matlab.internal.math.categoricalAccessor.fastCtor(group,gdataCodes);
    end

elseif iscell(group) || isstring(group)
    % For cellstrs and string use unique with some special checks
    try
        [gdata,~,gidx] = unique(group);
    catch ME
        if isequal(ME.identifier,'MATLAB:UNIQUE:InputClass')
            error(message('MATLAB:findgroups:GroupTypeIncorrect',class(group)));
        else
            rethrow(ME);
        end
    end

    if ~isempty(gdata)
        % Need to handle missing for cellstr and strings
        % cellstr - '' is sorted to beginning
        % string  - missing is sorted to end and separate
        if inclnan
            % for cell nothing to do
            % for string need to merge missing
            if isstring(group) && ismissing(gdata(end))
                % delete entries from gdata and fix gidx
                imiss = ismissing(gdata);
                idm = nnz(~imiss);
                gidx(gidx > idm) = idm+1;
                imiss(idm+1) = false;
                gdata(imiss) = [];
            end
        else
            if iscell(group) && strcmp('',gdata(1))
                % change group number and delete first entry
                gidx = gidx-1;
                gidx(gidx==0) = NaN;
                gdata(1)=[];
            elseif isstring(group) && ismissing(gdata(end))
                % delete entries from gdata and fix gidx
                imiss = ismissing(gdata);
                gidx(gidx > nnz(~imiss)) = NaN;
                gdata(imiss) = [];
            end
        end

        % sometimes empties are correct size and we don't need to transpose
        if isempty(gdata) && size(gdata,2) == 0
            gdata = gdata';
        end
    end
elseif isdatetime(group) || isduration(group) || iscalendarduration(group)
    % Find groups, index, and handle missing groups
    [gdata, gidx] = findGroupValsAndIdx(group,inclnan);

elseif isenum(group)
    % First grab all enum member names from the meta data
    mc = metaclass(group);
    gnames = cell(size(mc.EnumerationMemberList));
    [gnames{:}] = mc.EnumerationMemberList.Name;

    % Create an object for each enum member
    fh = str2func(mc.Name);
    gdata = fh(gnames);

    % Remove any masked enum members
    gdata = uniqueEnum(gdata);

    if ~inclempty
        % Grab the enums rep in data - do it this way so the order of the
        % output is the same as the enum member list just without the
        % unrepresented members (match what we do for categorical)
        loc = ismember(gdata,group);
        gdata = gdata(loc);
    end

    % Use ismember to get gidx instead of unique to
    % handle potential empty groups
    [~,gidx] = ismember(group,gdata);

elseif islogical(group)
    % Check if we're including empty categories
    if inclempty
        % If so the groups are easily defined
        gidx = group + 1;
        ng = 2;
        gdata = [false; true];
    else
        % if group is empty set categories
        if isempty(group)
            gidx = double(group);
            ng = 0;
            gdata = group;
        else
            % If all are true or false only have one group
            if all(group) || ~any(group)
                gidx = ones(size(group));
                ng = 1;
                gdata = all(group);
            else
                % Otherwise same easy definition as above
                gidx = group + 1;
                ng = 2;
                gdata = [false; true];
            end
        end
    end
elseif isnumeric(group)
    if ~issparse(group) && ~isobject(group)
        % Note that there is no check to ensure that inclnan is logical
        [gdata,~,gidx] = matlab.internal.math.uniquehelper(group,true,true,false,true,logical(inclnan));
    else
        [gdata, gidx] = findGroupValsAndIdx(group,inclnan);
    end
else
    % cannot group by tables error
    if istabular(group)
        error(message('MATLAB:findgroups:GroupTypeIncorrect',class(group)));
    end

    % attempt to call unique on unknown type, if that doesn't work error
    try
        [gdata,~,gidx] = unique(group);
    catch ME
        error(message('MATLAB:findgroups:GroupTypeIncorrect',class(group)));
    end

    % ensure the index returned by unique has a group for each row
    if numel(gidx) ~= numel(group)
        throwAsCaller(MException(message('MATLAB:findgroups:VarUniqueMethodFailedNumRows')));
    end
end

if isempty(ng)
    % Compute number of groups
    ng = size(gdata,1);
end
end

function [gdata, gidx] = findGroupValsAndIdx(group,inclnan)
% Find groups and index for types that could have missing groups

% For most types start with running unique
[gdata,~,gidx] = unique(group);

% Fix missing behavior
% Handle missing values: return NaN group indices
if ~isempty(gdata) && ismissing(gdata(end)) % missings are sorted to end
    gdata = gdata(~ismissing(gdata));
    if inclnan
        gidx(gidx > length(gdata)) = length(gdata)+1;
        gdata(end+1,1) = missing;
    else
        gidx(gidx > length(gdata)) = NaN;
    end
end
end

function C = uniqueEnum(enum)
% Return the unique enumeration members in enum

sz = size(enum);
C = cell(sz);
C{1} = enum(1);

idx = 2;
N = numel(enum);
for k = 2:N
    enumk = enum(k);

    % Compare each enumeration member in enum to each unique member in C
    addEnum = true;
    for j = 1:(idx-1)
        if enumk == C{j}
            addEnum = false;
            break;
        end
    end

    % Add the current enumeration member to C if it is not already present
    if addEnum
        C{idx} = enumk;
        idx = idx + 1;
    end
end
C = [C{1:idx-1}]';
end
