classdef IndexedWarnings < handle
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties (SetAccess = protected, Hidden)
        WarningsMap
    end
    
    methods
        function this = IndexedWarnings
            this.WarningsMap = containers.Map;
        end
        
        function addIndex(this, warningId, index)
            % Add an index to the specified warning id.
            map = this.WarningsMap;
            if ~iscell(warningId)
                warningId = {warningId};
            end
            for indx = 1:numel(warningId)
                if isKey(map, warningId(indx))
                    map(warningId{indx}) = [map(warningId{indx}) index];
                else
                    map(warningId{indx}) = index;
                end
            end
        end
        
        function warnings = getWarningStrings(this, id)
            % Convert cached warnings and ids into warning strings.
            map = this.WarningsMap;
            warningIds = keys(map);
            warnings = cell(numel(warningIds), 1);
            for indx = 1:numel(warningIds)
                if nargin < 2
                    % If no id is passed, the keys are the ids. and the
                    % first 'hole' in the message is for the indices
                    warnings{indx} = getString(message(warningIds{indx}, this.convertIdsToString(map(warningIds{indx}))));
                else
                    % If an id is passed it must have 2 'holes', the first
                    % is for the indices and the second is for the warning.
                    warnings{indx} = getString(message(id, this.convertIdsToString(map(warningIds{indx})), warningIds{indx}));
                end
            end
        end
    end
    
    methods (Static, Hidden)
        
        % Make static for testing.
        function str = convertIdsToString(ids)
            % should be sorted already but just in case.
            ids = sort(ids);
            if numel(ids) == 1
                str = sprintf('%d', ids(1));
                return;
            end
            str = '';
            d = diff(ids);
            
            gaps = find(d > 1);
            if isempty(gaps)
                str = sprintf('%d-%d', ids(1), ids(end));
            else
                gaps = [0 gaps numel(ids)];
                for indx = 1:numel(gaps)-1
                    if gaps(indx + 1) - gaps(indx) == 1
                        str = sprintf('%s%d,', str, ids(gaps(indx) + 1));
                    else
                        str = sprintf('%s%d-%d,', str, ids(gaps(indx) + 1), ids(gaps(indx + 1)));
                    end
                end
                str(end) = [];
            end
        end
    end
end

% [EOF]
