function locs = timesubs2inds(subsMillisIn,labelsMillisIn,tolMillisIn,doubledoubleMinus) %#codegen
% TIMESUBS2INDS Convert datetime or duration subscripts to indices.

%   Copyright 2022 The MathWorks, Inc.

if isscalar(tolMillisIn)
    tolMillis = repmat(tolMillisIn,size(subsMillisIn));
else
    tolMillis = tolMillisIn;
end
numSubs = numel(subsMillisIn);
numLabels = numel(labelsMillisIn);
if numLabels == 0
    % This case would flow through the small algorithm, but not the large.
    locs = [(1:numSubs)' zeros(numSubs,1)];

elseif numSubs == 0
    % This case would flow through the large algorithm, but not the small.
    locs = zeros(numSubs,2);

elseif numSubs <= 50 % better performance for small number of subscripts
    subsMillis = subsMillisIn(:);
    labelsMillis = labelsMillisIn(:);
    
    % Create a list of rows that match for each subscript, then combine the lists.
    % Because subscripts may match multiple or no labels, can't preserve the shape
    % of the original subscripts.
    locsCell = cell(numSubs,1);

    for i = 1:numSubs
        if doubledoubleMinus % use double-double substraction returning a double
            d = matlab.internal.coder.doubledouble.minus(labelsMillis,subsMillis(i)); % don't need full precision
        else % use core minus
            d = labelsMillis - subsMillis(i);
        end

        % When labelsMillis and subsMillis(i) are both either +/-Inf, the above
        % subtraction returns NaN. Fix those cases, but only for non-NaN tolerance.
        % They should be matches even for finite tolerance. Inf/nonInf and Inf/-Inf
        % cases are matches only if the tolerance is Inf, which only happens
        % with withtol.
        if isinf(subsMillis(i)) && ~isnan(tolMillis(i))
            d(labelsMillis == subsMillis(i)) = 0; % only touch Inf==Inf or -Inf==-Inf
        end

        inds_i = find(abs(d) <= tolMillis(i));
        if isempty(inds_i)
            inds_i = 0; % no match
        end
        locsCell{i} = [repmat(i,length(inds_i),1) inds_i];
    end
    locs = vertcat(locsCell{:});

else % better performance for large number of subscripts
    % Each subscript might match multiple row times, so store matches for each subscript in a cell
    % so we don't have to grow an array to an unknown size.
    locs_i = coder.nullcopy(cell(numSubs,1)); % unsorted locations in A and B for matches, preliminary guess at length
    
    % Presort subscripts and row labels.
    [subsMillis,ordSubs] = sort(subsMillisIn); % A
    [labelsMillis,ordLabels] = sort(labelsMillisIn); % B
    tolMillis = tolMillis(ordSubs);
    
    % Find all instances of A in B, store B-locations in C, i.e. just like the second output
    % of ismember, except store locations for all duplicates from B, not just the first
    % occurrence. Non-matches from A are zeros in C, just like ismember.
    j = 1; % position in input B
    for i = 1:numSubs
        subsMillis_i = subsMillis(i);
        tolMillis_i = tolMillis(i);
    
        % could weed out isnan(tolMillis_i) here, but save that unlikely test for later
    
        while true % catch B up to A
            if doubledoubleMinus % use double-double substraction returning a double
                d_ij = matlab.internal.coder.doubledouble.minus(labelsMillis(j),subsMillis_i); % don't need full precision
            else % use core minus
                d_ij = labelsMillis(j) - subsMillis_i;
            end
            if ~(d_ij < -tolMillis_i), break, end % B >= A - tol (or one of them is NaN) so B is caught up
            if j == numLabels, break, end % at the last B, stop advancing
            j = j + 1; % advance B
        end
    
        if abs(d_ij) <= tolMillis_i ... % A - tol <= B <= A + tol, found finite A in B
                || (labelsMillis(j) == subsMillis_i && ~isnan(tolMillis_i)) % or A == B == +/-Inf
            locs_i_growable = [ordSubs(i) ordLabels(j)]; % save A's and B's unsorted positions
    
            % Step though elements in B that match the current A within tolerance (which may
            % be Inf). Use a temp index to leave B's position alone so the next A can possibly
            % match it and step through the same run.
            if j < numLabels
                jj = j + 1; % start temp index at next element of B
                while true % step through B
                    if doubledoubleMinus
                        d_ij = matlab.internal.coder.doubledouble.minus(labelsMillis(jj),subsMillis_i); % don't need full precision
                    else
                        d_ij = labelsMillis(jj) - subsMillis_i;
                    end
                    if ~((d_ij <= tolMillis_i) || (labelsMillis(jj) == subsMillis_i && ~isnan(tolMillis_i))), break, end
                    locs_i_growable = [locs_i_growable; [ordSubs(i) ordLabels(jj)]]; % save A's and B's unsorted positions
                    if jj == numLabels, break, end
                    jj = jj + 1; % advance B
                end
            end
            locs_i{i} = locs_i_growable; % save A's and B's unsorted positions
    
        elseif d_ij > tolMillis_i ... % B > A + tol, A needs to catch up
                || isnan(tolMillis_i) % A will not match any B
            locs_i{i} = [ordSubs(i) 0]; % save A's unsorted position and a zero
            
        else
            % Either:
            % * A or B is NaN, thus is NaN from here on, or
            % * j is at end of B and B < A - tol, thus B will never catch up
            % Either way, we're out of matches.
            for ii = i:numSubs
                locs_i{ii} = [ordSubs(ii) 0]; % save A's unsorted positions and zeros
            end
            break
        end
    end
    if numSubs > 0
        locs = vertcat(locs_i{:});
    else
        locs = zeros(0,2);
    end
    
    % Post-unsort to put the indices in B's original order within A's original order.
    % Assignment needs to get back unmatched elements as zero indices, so leave them in.
    % Reference does not need them but will ignore them.
    locs = sortrows(locs);
end
