function G = createRobustGraph(pCells, points, S)
%This function is for internal use only. It may be removed in the future.

% createRobustGraph - Create a navgraph based on the PolyCell adjacency

%   Copyright 2024-2025 The MathWorks, Inc.
%#codegen

    numStates = numel(pCells);
    numLinks = sum(arrayfun(@(x)numel(x.LeftNeighbors)+numel(x.RightNeighbors), pCells));
    states = zeros(numStates, 3);
    links = zeros(numLinks, 2);
    weights = zeros(numLinks, 1);
    
    % Create the state vector with centroid and ID information
    for iCell = 1:numStates
        [x, y] = nav.decomp.internal.PolyCell.asPoly(pCells(iCell),points).centroid;
        states(iCell, :) = [x y iCell];
    end

    % Get all PolyCells as polyshapes for weight calculation
    polySet = nav.decomp.internal.polycell2shape(pCells,points);

    % Create cost functions
    connectedFcn = str2func(S.ConnectedCostFcn);
    userData = S.UserData;

    % Create the links based on neighbors
    iLink = 1;
    for iCell = 1:numStates
        curCell = pCells(iCell);
        nbrs = [curCell.LeftNeighbors(:); curCell.RightNeighbors(:)];
        for iNbr = 1:numel(nbrs)
            nbrId = nbrs(iNbr);
            links(iLink,:) = [iCell nbrId];
            weights(iLink) = connectedFcn(polySet,iCell,nbrId,userData);
            iLink = iLink+1;
        end
    end

    % Handle reconnection, if specified
    newLinks = zeros(0,2); coder.varsize('newLinks',[inf,2]);
    newCosts = zeros(0,1); coder.varsize('newCosts',[inf,1]);
    switch S.ReconnectionMethod
        case "nearest"
            [newLinks,newCosts] = reconnectNearest(links,polySet,S);
        case "all"
            [newLinks,newCosts] = reconnectAll(links,polySet,S);
        otherwise
    end
    links   = [links;   newLinks];
    weights = [weights; newCosts];
    
    % Construct Reeb Graph
    G = navGraph(states,links,Weight=weights);
end
function [newLinks,newCosts] = reconnectNearest(links,polySet,S)
    % Form basic graph to determine if graph is fully connected
    dg = digraph(links(:,1),links(:,2));
    disconnectedFcn = str2func(S.DisconnectedCostFcn);
    userData = S.UserData;

    % Identify connected components in graph. Disconnected components 
    % will be connected to their nearest component-neighbor
    compIdx = dg.conncomp;
    [cID,~,poly2compIdx] = unique(compIdx);
    n = 2*(numel(cID)-1);
    newLinks = zeros(n,2);
    newCosts = zeros(n,1);
    iLink = 1;
    
    for iComp = 1:(numel(cID)-1)
        % Distinguish first component from remaining components
        idxInComp = find(poly2compIdx == 1);
        assert(numel(idxInComp)>=1);
        idxInOtherComp = find(poly2compIdx ~= 1);

        % Find nearest connection between first component to any other component
        dMin = inf; iMin = nan; jMin = nan; iNewlyConnectedComp = nan;
        for i = 1:numel(idxInComp)
            % Compute cost to all cells in other components
            nbrId = idxInComp(i);
            costs = disconnectedFcn(polySet,nbrId,idxInOtherComp,userData);
            [dMinCur,jMinCur] = min(costs);
            if dMinCur < dMin
                dMin = dMinCur;
                iMin = nbrId;
                jMin = idxInOtherComp(jMinCur);
                iNewlyConnectedComp = poly2compIdx(idxInOtherComp(jMinCur));
            end
        end

        % Add bi-directional link
        newLinks(iLink:iLink+1, :) = [iMin jMin; jMin iMin];
        newCosts(iLink:iLink+1) = [dMin; dMin];
        iLink = iLink+2;

        % Move all members of newly-connected component to first component
        inNewlyConnectedComp = poly2compIdx==iNewlyConnectedComp;
        poly2compIdx(inNewlyConnectedComp) = 1;
    end
end
function [newLinks,newCosts] = reconnectAll(links,polySet,S)
    % Form basic graph to determine if graph is fully connected
    dg = digraph(links(:,1),links(:,2));
    disconnectedFcn = str2func(S.DisconnectedCostFcn);
    userData = S.UserData;

    % Identify connected components in graph. Disconnected components 
    % will be connected to their nearest component-neighbor
    compIdx = dg.conncomp;
    [cID,~,poly2compIdx] = unique(compIdx);
    compSizes = reshape(accumarray(poly2compIdx,1),[],1);
    n = 0;
    for i = 1:(numel(cID)-1)
        n = n+sum(compSizes(cID(i))*compSizes(cID((i+1):end)));
    end     
    % Preallocate the correct size arrays, double for bi-directional links
    n = 2*n;
    newLinks = zeros(n,2);
    newCosts = zeros(n,1);
    if numel(cID) > 1
        iLink = 1;
        for iComp = 1:numel(cID)
            idxInComp = find(poly2compIdx == iComp);
            assert(numel(idxInComp)>=1);
            idxInOtherComp = find(poly2compIdx ~= iComp);
            
            for i = 1:numel(idxInComp)
                nbrId = idxInComp(i);
                costs = disconnectedFcn(polySet,nbrId,idxInOtherComp,userData);
                tmpLinks = [repelem(nbrId,numel(idxInOtherComp),1) idxInOtherComp];
                numNew = size(tmpLinks, 1);
                assert(numNew==numel(costs));
                newLinks(iLink:iLink+numNew-1,:) = tmpLinks;
                newCosts(iLink:iLink+numNew-1) = costs;
                iLink = iLink+numNew;
            end
        end
    end
end
