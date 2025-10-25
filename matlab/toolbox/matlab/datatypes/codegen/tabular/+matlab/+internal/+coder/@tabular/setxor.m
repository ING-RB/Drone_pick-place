function [c,ia,ib] = setxor(a,b,varargin) %#codegen
%SETXOR Find rows that occur in one or the other of two tables, but not both.

%   Copyright 2019-2020 The MathWorks, Inc.

if nargin < 3
    flag = 'sorted';
else
    narginchk(2,5); % high=5, to let setmembershipFlagChecks sort flags out
    flag = tabular.setmembershipFlagChecks(varargin{:});
end

[ainds,binds] = tabular.table2midx(a,b);

if flag == "sorted"
    % Sort the multi-index matrices, so that the rows are in ascending order, as
    % this is required by core set membership functions
    [sorted_ainds, sorted_ia] = sortrows(ainds);
    [sorted_binds, sorted_ib] = sortrows(binds);
    
    [d,ia,ib] = setxorLocal(sorted_ainds,sorted_binds,flag,'rows');
    
    % Map the indices back to their values in the original unsorted inputs,
    % before doing further processing.
    ia = sorted_ia(ia);
    ib = sorted_ib(ib);
    
    aa = parenReference(a,ia,':');
    bb = parenReference(b,ib,':');
    
    % If aa or bb are varsized and they become 0x0 at runtime, then it would
    % cause vertcat to error. Check the sizes of aa and bb before calling
    % vertcat and throw a more helpful error indicating the problem. Note that
    % this would always be a runtime error.
    aa_is0x0 = sum(size(aa)) == 0;
    bb_is0x0 = sum(size(bb)) == 0;
    coder.internal.errorIf((~coder.internal.isConst(size(aa)) && aa_is0x0) ...
                        || (aa_is0x0 && ~coder.internal.isConst(size(bb)) && bb_is0x0), ...
                        'MATLAB:table:setmembership:Mx0NotSupported','setxor');
    
    cc = vertcat(aa,bb);

    % If the flag is 'sorted', then we would have to rearrange the output of
    % vertcat. As this would change the order of the rows, we would also have
    % to update the default row names that were created by vertcat
    ord = zeros(size(d));
    ord(~d) = 1:length(ia);
    ord(d) = length(ia) + (1:length(ib));
    iord = 1:length(ord);
    iord(ord) = iord;

    if (~aa.rowDim.hasLabels && bb.rowDim.hasLabels) || ...
       (~bb.rowDim.hasLabels && aa.rowDim.hasLabels)
        % If one of aa or bb has row labels but the other one does not, create
        % appropriate default row labels
        rowLabels = cc.rowDim.labels;
        aaLabels = aa.rowDim.labels;
        bbLabels = bb.rowDim.labels;
        
        for i = 1:length(ia)
           if aa.rowDim.hasLabels
               rowLabels{i} = aaLabels{i};
           else
               rowLabels{i} = aa.rowDim.dfltLabels(iord(i),true);
           end
        end
        aa_nrows = length(ia);
        for i = aa_nrows+1:length(iord)
           if bb.rowDim.hasLabels
               rowLabels{i} = bbLabels{i-aa_nrows};
           else
               rowLabels{i} = aa.rowDim.dfltLabels(iord(i),true);
           end
        end
        cc_rowDim = cc.rowDim.createLike(length(iord),rowLabels);
        c = cc.updateTabularProperties([],[],cc_rowDim,[]);
        c = parenReference(c,ord,':');
    else
        % Else just reorder the output of vertcat
        c = parenReference(cc,ord,':');
    end
    
else
    % Otherwise directly call the core functions
    [~,ia,ib] = setxorLocal(ainds,binds,flag,'rows');
    aa = parenReference(a,ia,':');
    bb = parenReference(b,ib,':');
    
    % If aa or bb are varsized and they become 0x0 at runtime, then it would
    % cause vertcat to error. Check the sizes of aa and bb before calling
    % vertcat and throw a more helpful error indicating the problem. Note that
    % this would always be a runtime error.
    aa_is0x0 = sum(size(aa)) == 0;
    bb_is0x0 = sum(size(bb)) == 0;
    coder.internal.errorIf((~coder.internal.isConst(size(aa)) && aa_is0x0) ...
                        || (aa_is0x0 && ~coder.internal.isConst(size(bb)) && bb_is0x0), ...
                        'MATLAB:table:setmembership:Mx0NotSupported','setxor');

    c = vertcat(aa,bb);
end
 
%-----------------------------------------------------------------------
function [d,ia,ib] = setxorLocal(a,b,order,~)
% The main function doesn't actually need the rows themselves, since those
% are just dummy indices anyway.  It needs to know which of the two inputs
% each row of the xor "came from", so rather than returning the rows, this
% local function returns a logical indicating rows of the result that came
% from the second input (true), or from the first (false).

% Make sure a and b contain unique elements.
[uA,indA] = matlab.internal.coder.datatypes.unique(a,order,'rows');
[uB,indB] = matlab.internal.coder.datatypes.unique(b,order,'rows');

catuAuB = [uA;uB];                    % Sort [uA;uB] in order to find matching entries
[sortuAuB,indSortuAuB] = sortrows(catuAuB);
d = find(all(sortuAuB(1:end-1,:)==sortuAuB(2:end,:),2));    % d indicates the location of matching entries
indSortuAuB([d;d+1]) = [];                                  % Remove all matching entries - indSortuAuB only contains elements not in intersect
if strcmp(order, 'stable') % 'stable'
    indSortuAuB = sort(indSortuAuB);  % Sort the indices to get 'stable' order
end

n = size(uA,1);
d = indSortuAuB > n;  
ia = indA(indSortuAuB(~d,1),1); 
ib = indB(indSortuAuB(d,1)-n,1);

