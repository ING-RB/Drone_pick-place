function docContent = retrieveDocCenterPropertiesContent(searchTerms)
% retrieves Doc Center property page content for a given search Term as a
% struct of the search term and the Doc Center property descriptions.

%   Copyright 2016-2024 The MathWorks, Inc.

% searchTerms is a character vertor of a single term to search for. if it
% is a character vector convert it to a cell array
if(~iscell(searchTerms))
    searchTerms = {searchTerms};
end

docContent(length(searchTerms)) = struct('SearchTerm', '', 'Properties', []);

for i = 1:length(searchTerms)
    searchTerm = searchTerms{i};
    docContent(i).SearchTerm = searchTerm;
    docContent(i).Properties = getComponentProperties(searchTerm);
end
end

function referenceData = getReferenceData(searchTerm)

% g3312337 - In 24b, all base MATLAB UI components' doc pages updated 
% from Properties page to Object page. 
% UIFigure, UIAxes, and all other components remain
% Properties pages until later transition.

referenceType = [ ...
    matlab.internal.reference.property.RefEntityType.Properties ...
    matlab.internal.reference.property.RefEntityType.Object ...
    ];

referenceData = getReferenceDataByType(searchTerm, referenceType);

end

function referenceData = getReferenceDataByType(searchTerm, referenceType)

% get a request to search Doc Center
request = matlab.internal.reference.api.ReferenceRequest(searchTerm, referenceType);
% create a retriever to extract content
retriever = matlab.internal.reference.api.ReferenceDataRetriever(request);

referenceData = retriever.getReferenceData();
end

function props = getComponentProperties(searchTerm)
% iterates over groups to get component properties

props =[];

referenceData = getReferenceData(searchTerm);
% Case where search term does not have reference data associated with it
if isempty (referenceData)
    return
end

if length(referenceData) > 1
    % Some components (e.g., UTHTML) are transitioning and have both
    % Properties and Object page so get double reference hits
    referenceData = referenceData(1);
end

for i = 1:length(referenceData.ClassPropertyGroups)
    classPropertyGroup = referenceData.ClassPropertyGroups(i);
    groupName = classPropertyGroup.Title;
    groupedProperties = classPropertyGroup.ClassProperties;
    % concat properties for each group
    props = [props; getPropertiesCell(groupName, groupedProperties)];
end
end

function propStruct = getPropertiesCell(groupName, groupedProperties)
% converts Doc Center data into a struct with relevant fields
props = cell(length(groupedProperties), 5);
for i = 1:length(groupedProperties)
    property = groupedProperties(i);
    props{i, 1} = property.Name; % property name
    props{i, 2} = property.Purpose;  % purpose
    props{i, 3} = strjoin(property.Values, ' | '); % inputs
    props{i, 4} = property.Href; % help path
    props{i, 5} = groupName; % group
end
propStruct = struct('property', props(:,1), 'description', props(:,2), 'inputs', props(:,3), 'helpPath', props(:,4), 'group', props(:,5));
end