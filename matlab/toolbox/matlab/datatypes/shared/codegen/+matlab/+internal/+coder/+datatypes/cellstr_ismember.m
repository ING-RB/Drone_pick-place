function [lia,locb] = cellstr_ismember(a, b) %#codegen
%CELLSTR_ISMEMBER True for set member in a cellstr.
%   CELLSTR_ISIMEMBER(A,B) implements ismember for cellstr or char vector
%   inputs in codegen.

%   Copyright 2018-2020 The MathWorks, Inc.

coder.internal.prefer_const(a,b);
coder.extrinsic('cellstr','unique');

% The only A and B allowed are character arrays or cellstr.
coder.internal.errorIf(ischar(a) && ischar(b), 'MATLAB:ISMEMBER:InputClass', class(a),class(b));
coder.internal.assert((ischar(a) || iscellstr(a)) && (ischar(b) || iscellstr(b)), 'MATLAB:ISMEMBER:InputClass', class(a),class(b)); %#ok<ISCLSTR>

if coder.internal.isConst(a) && coder.internal.isConst(b)
    if nargout > 1
        [lia,locb] = coder.const(@feval,'ismember',a,b);
    else
        lia = coder.const(feval('ismember',a,b));
    end
% Scalar A: no sort needed
elseif coder.internal.isConst(size(b)) && ( (ischar(a) && coder.internal.isConst(size(a,1)) && isrow(a)) || coder.internal.isConst(size(a)) && isscalar(a) )
    if ischar(b)
        lia = strcmp(a,b);
        if lia
            locb = 1;
        else
            locb = 0;
        end
    else
        lia = false;
        locb = 0;
        for i = 1:numel(b)
            if strcmp(a,b{i})
                lia = true;
                locb = i;
                break
            end
        end
    end
% Scalar B: no sort needed
elseif coder.internal.isConst(size(a)) && ( (ischar(b) && coder.internal.isConst(size(b,1)) && isrow(b)) || coder.internal.isConst(size(b)) && isscalar(b) )
    lia = strcmp(a,b);
    if nargout > 1
        locb = double(lia);
    end
    lia = reshape(lia,size(a));
else
    % If A or B is char, convert it to a cellstr and remove trailing spaces
    if coder.internal.isConst(a)
        a_ = coder.const(cellstr(a));
        [uA,~,icA] = coder.const(@unique,reshape(a_,[],1),'sorted');
    else
        if ischar(a)
            a_ = matlab.internal.coder.datatypes.cellstr(a);
        else
            a_ = a;
        end
        % force a_ to be homogeneous
        if coder.internal.isConst(size(a_))
            coder.varsize('a_',[],false(1,ndims(a_)));
        end
        [uA,~,icA] = matlab.internal.coder.datatypes.cellstr_unique(reshape(a_,[],1),'sorted');
    end
    if coder.internal.isConst(b)
        b_ = coder.const(cellstr(b));
        % Duplicates within the sets are eliminated
        if nargout <= 1
            uB = coder.const(unique(reshape(b_,[],1),'sorted'));
        else
            [uB,ib] = coder.const(@unique,reshape(b_,[],1),'sorted');
        end
    else
        if ischar(b)
            b_ = matlab.internal.coder.datatypes.cellstr(b);
        else
            b_ = b;
        end
        % force b_ to be homogeneous
        if coder.internal.isConst(size(b_))
            coder.varsize('b_',[],false(1,ndims(b_)));
        end
        % Duplicates within the sets are eliminated
        if nargout <= 1
            uB = matlab.internal.coder.datatypes.cellstr_unique(reshape(b_,[],1),'sorted');
        else
            [uB,ib] = matlab.internal.coder.datatypes.cellstr_unique(reshape(b_,[],1),'sorted');
        end
    end
    % Compute lia and locb
    %
    % The implementation below is meant to be a more codegen-friendly
    % implementation of the following simplified code from @cell/ismember:
    %
    %     % Sort the unique elements of A and B, duplicate entries are adjacent
    %     [sortuAuB,IndSortuAuB] = sort([uA;uB]);
    %     % d indicates the indices matching entries
    %     d = strcmp(sortuAuB(1:end-1),sortuAuB(2:end));
    %     indReps = IndSortuAuB(d);                  % Find locations of repeats
    %     [lia,locb] = ismember(icA,indReps);        % Find repeats among original list
    %
    %     % compute locb
    %     szuA = size(uA,1);
    %     d = find(d);
    %     newd = d(locb(lia));                       % NEWD is D for non-unique A
    %     where = ib(IndSortuAuB(newd+1)-szuA);
    %     locb(lia) = where;
    %
    % In the codegen-friendly implementation, we do the following instead:
    %
    %     uAInUB = ismember(uA,uB);
    %     lia = uAInUB(icA);
    %
    %     % compute locb
    %     [~,locbOfUA] = ismember(uA,b);
    %     locb = locbOfUA(icA);
    %
    % This second version avoids the need for an expensive sort and avoids the
    % memory cost of creating the temporary cellstr variables [uA;uB] and
    % sortuAuB by instead creating uAInUB and locbOfUA, which are logical and
    % numeric respectively.
    uAInUB = false(numel(uA),1);
    if nargout <= 1
        if numel(uB) > 0
            % uAInUB = ismember(uA,uB);
            j = coder.internal.indexInt(1);
            for i = 1:numel(uA)
                if string(uA{i}) < string(uB{j})
                    % uAInUB(i) = false; % uA{i} is not in uB
                elseif strcmp(uA{i},uB{j})
                    uAInUB(i) = true;
                    j = j + 1;
                else
                    while j <= numel(uB) && string(uA{i}) > string(uB{j})
                        j = j + 1;
                    end
                    if j <= numel(uB) && strcmp(uA{i},uB{j})
                        uAInUB(i) = true;
                        j = j + 1;
                    end
                end
                if j > numel(uB)
                    break
                end
            end
            lia = uAInUB(icA);
        else
            lia = false(numel(a_),1);
        end
    else
        locbOfUA = zeros(numel(uA),1);
        if numel(uB) > 0
            % uAInUB = ismember(uA,uB);
            % [~,locbOfUA] = ismember(uA,b);
            j = coder.internal.indexInt(1);
            for i = 1:numel(uA)
                if string(uA{i}) < string(uB{j})
                    % uAInUB(i) = false; % uA{i} is not in uB
                elseif strcmp(uA{i},uB{j})
                    uAInUB(i) = true;
                    locbOfUA(i) = ib(j);
                    j = j + 1;
                else
                    while j <= numel(uB) && string(uA{i}) > string(uB{j})
                        j = j + 1;
                    end
                    if j <= numel(uB) && strcmp(uA{i},uB{j})
                        uAInUB(i) = true;
                        locbOfUA(i) = ib(j);
                        j = j + 1;
                    end
                end
                if j > numel(uB)
                    break
                end
            end
        end
        lia = uAInUB(icA);
        locb = locbOfUA(icA);
        if coder.internal.isConst(size(a_,1)) && ismatrix(a_)
            locb = reshape(locb,size(a_,1),[]);
        elseif coder.internal.isConst(size(a_,2)) && ismatrix(a_)
            locb = reshape(locb,[],size(a_,2));
        else
            locb = reshape(locb,size(a_));
        end
    end
    % we need to force the height or width of lia to be constant in some cases
    if coder.internal.isConst(size(a_,1)) && ismatrix(a_)
        lia = reshape(lia,size(a_,1),[]);
    elseif coder.internal.isConst(size(a_,2)) && ismatrix(a_)
        lia = reshape(lia,[],size(a_,2));
    else
        lia = reshape(lia,size(a_));
    end
end
