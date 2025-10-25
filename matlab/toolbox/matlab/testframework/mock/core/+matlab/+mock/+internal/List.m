classdef List < handle
    % This class is undocumented and may change in a future release.

    % Copyright 2015-2024 The MathWorks, Inc.

    properties (SetAccess=private)
        Entries = matlab.mock.internal.ListEntry.empty(1,0);
    end

    properties (Access=private)
        AddingNewEntriesDisabled = false;
    end

    methods
        function prepend(list, value)
            import matlab.mock.internal.ListEntry;

            if list.AddingNewEntriesDisabled
                return;
            end

            list.Entries = [ListEntry.empty(1,0), value, list.Entries];
        end

        function entry = append(list, entry, id)
            import matlab.mock.internal.ListEntry;

            if nargin > 2
                entry = ListEntry(entry, id);
            end

            if list.AddingNewEntriesDisabled
                return;
            end

            list.Entries(end+1) = entry;
        end

        function entry = findFirst(list, comparisonFcn)
            import matlab.mock.internal.ListEntry;

            for entry = list.Entries
                if comparisonFcn(entry.Value)
                    return;
                end
            end

            % No entries found
            entry = ListEntry.empty;
        end

        function entries = findAll(list, comparisonFcn)
            entries = list.Entries(cellfun(comparisonFcn, {list.Entries.Value}));
        end

        function clear(list)
            list.Entries(:) = [];
        end

        function disableAddingNewEntries(list)
            list.AddingNewEntriesDisabled = true;
        end
    end
end

