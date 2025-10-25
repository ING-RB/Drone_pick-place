function shiftedPVPairs = shiftOrderDependentProperties(pvPairs, component)
% SHIFTORDERDEPENDENTPROPERTIES - Shift any order dependent properties to
% the end of the pvPair list while preserving the order of the
% orderDependentProperties
% This will filter duplicate entries in the pvPairs if there
% are multiple property names for a given
% orderDependentProperty.  The last matching pvPair will the
% one preserved. For example, if the end user has specified multiple
% 'Parent' values, all but the last one will be filtered out.
% An example of why you would want to move properties to the
% end is that for some components the 'Value' entry is
% dependent on the configuration of the component, ListBox for
% example.  The 'Value' needs to be set after the other entries
% in the PVPairs have been applied.
%
% pvPairs: a cell array containing any combination of proper
% {'Property', Value} pairs or structs.  HG constructors and
% set methods accept structs as a valid way to specify PV pairs
%
% parameterList: a cell array of char arrays or a string array
% that contains valid properties associated with the component
% getting the pvPairs.  This is used because the inputparser
% supports partial matching and without additional parameters
% to set context, the partial matching could provide results
% different than the component constructor.

% orderDependentProperties: a cell array of char arrays or a
% string array that contains property names that will be found
% and pushed to the end of the cell array of pvPairs.
orderDependentProperties = matlab.ui.control.internal.model.AbstractComponent.getLastPropertiesToSet();

% SET UP PARSER OBJECT
inputParserObj = matlab.ui.control.internal.model.getComponentCreationInputParser(component);

inputParserObj.parse(pvPairs{:});
parameterList = inputParserObj.Parameters;

% Remove orderDependentProperties not in property list (for
% completeness)
for odpIndex = numel(orderDependentProperties):-1:1

    % boolean vector locating prop in parameterList
    comparison = contains(parameterList, orderDependentProperties{odpIndex});

    if ~any(comparison)
        % Remove property from list
        orderDependentProperties(odpIndex) = [];
    end
end

% The successful parse serves as proof that the pvPairs are
% well formatted.  We can assume they are of the format
% {'PropertyName', value} or struct, or a cell array containing
% a combination of the two.
filteredPvPairs = [];  % pvPairs without orderdependent
% unmatchedFields represent properties that either don't match
% the parameters at all, or where the match was ambigous
% between two similar property names (ex. 'MajorTicks',
% 'MajorTicksMode')
unmatchedFields = string(fieldnames(inputParserObj.Unmatched));

% Filter properties from pvPairs that match order dependent
% properties
while numel(pvPairs) > 0

    % HANDLE STRUCT INPUT
    if isstruct(pvPairs{1})
        structValue = pvPairs{1};
        fieldNames = fieldnames(structValue);

        % Remove field if it doesn't match the 'unmatched'
        % fields and matches an order dependent property
        for index = 1:numel(fieldNames)

            % per g1576792, struct input does not support
            % partial matching, thus match cannot be ambiguous
            odMatchFound = any(strcmpi(fieldNames{index}, orderDependentProperties));

            if  odMatchFound

                % Remove option from input, add to odp Inputs
                structValue = rmfield(structValue, fieldNames{index});
            end
        end

        if ~isempty(fields(structValue))
            filteredPvPairs = [filteredPvPairs, {structValue}];
        end
        pvPairs(1) = [];

    else
        % HANDLE PV PAIR INPUT
        import appdesservices.internal.util.ismemberForStringArrays;
        if ismemberForStringArrays(string(pvPairs{1}), unmatchedFields)
            % Property name was not a match to the parameter
            % list or the orderDependentProperties (this will
            % likely result in a runtime set error)
            filteredPvPairs = [filteredPvPairs, pvPairs(1:2)];

        else
            % Property name was a match to exactly one in the
            % parameter list.  There are multiple scenarios:
            % 1. The pvName exactly matches something in the
            %    propList and there is only one potential match.
            % 2. The pvName exactly matches and there are other
            %    partial matches: pvName is 'Value', propList
            %    has 'Value', 'ValueChanging' etc.
            % 3. The pvName partially matches some property,
            %    but the match is not ambiguous,


            if any(strcmpi(pvPairs{1}, parameterList))
                % pvName matches exactly to parameterList
                % Case #1 and #2
                matchedName = pvPairs{1};
            else
                % matchedName is expected to be scalar because
                % the pvName was already checked for exact
                % match and ambigous match.  It should only
                % return one value for 'startsWith'.
                % Case #3
                matchedName = parameterList(startsWith(parameterList, pvPairs{1}, 'IgnoreCase', true));
            end


            if ~any(strcmpi(matchedName, orderDependentProperties))
                % pvPair name exactly matches a property and
                % does not match an orderDependentProperty
                filteredPvPairs = [filteredPvPairs, pvPairs(1:2)];
            end

        end
        pvPairs(1:2) = [];
    end

end

% If PropertyName is not the default (it is specified in the pvPair list)
% add it to the end of the pvPair list
shiftedPVPairs = [];
for index = 1:numel(orderDependentProperties)
    if ~any(strcmp(orderDependentProperties{index}, inputParserObj.UsingDefaults))
        shiftedPVPairs = [shiftedPVPairs, {orderDependentProperties{index}, inputParserObj.Results.(orderDependentProperties{index})}];
    end
end

shiftedPVPairs = [filteredPvPairs, shiftedPVPairs];

end