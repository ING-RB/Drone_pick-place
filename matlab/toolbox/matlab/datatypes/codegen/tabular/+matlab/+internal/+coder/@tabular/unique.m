function [c,ia,ic] = unique(a,varargin) %#codegen
%UNIQUE Find unique rows in a table.

%   Copyright 2019-2020 The MathWorks, Inc.

ainds = tabular.table2midx(a);
nin = nargin;
if nin > 1
    % Process the flags and figure out if we need to sort the inputs
    processedVarargin = tabular.processSetMembershipFlags(varargin{:});
    sortInputs = true;
    
    for i = 1:length(processedVarargin)
        if strncmpi('stable', processedVarargin{i}, max(length(processedVarargin{i}), 1))
            % If at least one flag matches stable, then we are either looking
            % for stable output or it will be an error. So set the sortInputs
            % flag to false and exit.
            sortInputs = false;
            break
        end
    end
else
   % Default behavior is sorted
   sortInputs = true;
   processedVarargin = {};
end
    
if sortInputs
    % Sort the multi-index matrices, so that the rows are in ascending
    % order, as this is required by core set membership functions
    [sorted_ainds, sorted_ia] = sortrows(ainds);

    [~,ia,ic] = unique(sorted_ainds,'rows',processedVarargin{:});

    % Map the indices back to their values in the original unsorted inputs,
    % before doing further processing.
    ia = sorted_ia(ia);

    % ic contains the correct indices but their order is not correct. Obtain
    % the correct order by sorting the sorted_ia indices and then use that
    % order to rearrange ic.
    [~,ord] = sort(sorted_ia);
    ic = ic(ord);

else
    % Otherwise directly call core unique
    [~,ia,ic] = unique(ainds,'rows',processedVarargin{:});
end

c = parenReference(a,ia,':');