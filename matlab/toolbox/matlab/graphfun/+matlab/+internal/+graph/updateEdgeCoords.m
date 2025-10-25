function [edgeCoords, edgeCoordsIndex] = updateEdgeCoords(BasicGraph, Layout, XData, YData, ZData)

%   Copyright 2015-2024 The MathWorks, Inc.

% Get list of edges and matrix of node coordinates
nrNodes = numnodes(BasicGraph);
nrEdges = numedges(BasicGraph);
ed = BasicGraph.Edges;
s = ed(:,1);
t = ed(:,2);
nc = [XData(:), YData(:), ZData(:)];


% IDENTIFY TYPE OF EACH EDGE (self-loop, parallel edge, straight edge)

% Identify self-loops
isSelfloop = s == t;
nrSelfloops = sum(isSelfloop);

% Number of self-loops for each node.
multSelfloop = accumarray(s, double(isSelfloop), [nrNodes, 1]);

% Radius of self-loops, and minimum radius (used to compute opening angles)
[selfLoopRadius, minRadius] = computeSelfLoopRadius(BasicGraph, Layout, XData, YData);

% Determine parallel edges (same direction or not) and maximal opening
% angle for circle arcs connecting them.
[alpha, ismultedge] = computeOpeningAngle(BasicGraph, XData, YData, selfLoopRadius, minRadius);
nrMultedges = sum(ismultedge);

% Remaining edges are represented as straight lines.
isstraightedge = ~(isSelfloop | ismultedge);
nrStraightedges = length(s) - nrSelfloops - nrMultedges;


% PREALLOCATE edgeCoords AND edgeCoordsIndex

% Number of points necessary to plot each type of edge
nptsSelfloop = 37;
nptsMultedge = 40;
nptsStraightedge = 2;

% Allocate array containing points for all edges in the graph
nrPoints = nrSelfloops * nptsSelfloop + nrStraightedges * nptsStraightedge ...
    + nrMultedges * nptsMultedge;
edgeCoords = zeros(nrPoints,3);

% For each edge i, nptsEdge(i) gives number of points needed
nptsEdge = 2*ones(nrEdges, 1);
nptsEdge(isSelfloop) = nptsSelfloop;
nptsEdge(ismultedge) = nptsMultedge;

% edgeCoordsIndex(i) is the edge that the point edgeCoords(i, :) belongs to
edgeCoordsIndex = repelem(1:nrEdges, nptsEdge).';


% CONSTRUCT THE EDGES

% Straight edges
blockStart = [0; cumsum(nptsEdge)] + 1; % start of each block of points
blockStartStraight = blockStart(isstraightedge); % only
blockStartStraight = reshape(blockStartStraight, 1, []); % this is needed if tmp is [], it transforms 0x0 into 1x0

% First point has coordinates of node s, second ponit of node t.
edgeCoords(blockStartStraight, :) = nc(s(isstraightedge), :);
edgeCoords(blockStartStraight+1, :) = nc(t(isstraightedge), :);

% Self-loops
selfloopCount = ones(size(multSelfloop)); % incremented, going from 1 to multSelfloop in each element
for i = reshape(find(isSelfloop),1,[])
    currentnode = s(i);
    
    % Compute rotation angle of the self-loop
    if strcmp(Layout, 'circle')
        angle = atan2d(YData(currentnode), XData(currentnode));
    else
        % List of t's neighbors
        if isa(BasicGraph, 'matlab.internal.graph.MLDigraph')
            n = unique([successors(BasicGraph, currentnode);...
                predecessors(BasicGraph, currentnode)]);
        else
            n = neighbors(BasicGraph, currentnode);
        end
        n(n == currentnode) = [];
        
        if ~isempty(n)
            % Compute angles of all edges in t, find largest angle
            % (most space for inserting a self-loop)
            diffX = XData(n) - XData(currentnode);
            diffY = YData(n) - YData(currentnode);
            
            angles = atan2d(diffY, diffX);
            
            angles = sort(angles);
            angles(end+1) = angles(1) + 360; %#ok<AGROW>
            
            % Find maximal difference between angles
            [~, ind] = max(diff(angles));
            ind = ind(1);
            angle = (angles(ind) + angles(ind+1))/2;
        else
            angle = 0;
        end
    end
    
    % Construct a teardrop shape based on self-loop number selfLoopCount of
    % multSelfLoop self-loops.
    circle = constructCircle(selfloopCount(currentnode), multSelfloop(currentnode), selfLoopRadius);
    
    % Apply rotation
    rotcircle = circle * [cosd(angle) sind(angle) 0; -sind(angle) cosd(angle) 0; 0 0 1];
    
    % Move self-loop to node coordinates and insert into edgeCoords array
    edgeCoords(blockStart(i):blockStart(i+1)-1,:) = rotcircle + nc(currentnode,:);
    
    % Increment self-loop count
    selfloopCount(currentnode) = selfloopCount(currentnode) + 1;
end


% Multiple parallel edges
for i = reshape(find(ismultedge),1,[])
    
    % Coordinates of start point and end point
    startP = nc(s(i),:);
    endP   = nc(t(i),:);
        
    if alpha(i) ~= 0
        % Radius of circle arc based on the opening angle
        r = norm(startP(1:2) - endP(1:2))/2/sind(alpha(i)/2);
        
        % Unit vector pointing orthogonally to the right of vector
        % startP->endP
        d = startP - endP;
        d = [-d(2) d(1) 0];
        d = d/norm(d);
        
        % Center of the circle
        c = (startP + endP)/2 - d*r*cosd(alpha(i)/2);
        
        % Points on opening angle interval
        phi = linspace(-alpha(i)/2, alpha(i)/2, nptsMultedge).';
        
        % Compute the rotated circle arc
        pts = r*[cosd(phi) sind(phi)]*[d(1) d(2); -d(2) d(1)];
        
        % Move circle arc to the center point, and interpolate the points
        % in the third dimension.
        pts = [pts + c(1:2), linspace(startP(3), endP(3), nptsMultedge)'];
        
        % Explicitly set start / end points to the node coordinates, in
        % case of round-off errors.
        pts(1, :) = startP.';
        pts(end, :) = endP.';
    else
        % Opening angle one implies a straight line is used
        lincoord = linspace(0, 1, blockStart(i+1) - blockStart(i));
        pts = interp1([0 1], [startP; endP], lincoord);
    end
    
    % Insert points into EdgeCoords array
    edgeCoords(blockStart(i):blockStart(i+1)-1,:) = pts;
end
end % END updateEdgeCoords


function [selfLoopRadius, minRadius] = computeSelfLoopRadius(BasicGraph, Layout, XData, YData)
% Computes the radius of all self-loops in the plot, based on a number of
% heuristics. The second output minRadius is used to compute the opening
% angles of the circle arcs representing multiple edges: the distance
% between the two outermost edges should be at least 2*minRadius.
%
% Different heuristics are used for the 'cycle' layout, and for all other
% layouts ('manual', 'force', 'subspace'). The 'layered' layout does not
% call updateEdgeCoords, but uses its own set of heuristics.

n = numnodes(BasicGraph);
el = BasicGraph.Edges;
nc = [XData(:), YData(:)];

t = el(:,1);
h = el(:,2);

isselfloop = t == h;

if ~strcmp(Layout, 'circle')  % General case
    
    % Compute the length of the shortest edge, set the self-loop radius to
    % be 1/5 of that (note this can become zero):
    bb = max(nc, [], 1) - min(nc, [], 1);
    ncdiff = nc(t(~isselfloop), :) - nc(h(~isselfloop), :);
    mindist = min(hypot(ncdiff(:,1), ncdiff(:,2)));
    selfLoopRadius = mindist/5;
    
    % If there are no edges, use a different heuristic:
    if isempty(selfLoopRadius)
        if ~isempty(bb) && bb(1)*bb(2) > 0 % bounding box area is non-empty
            % area of all self-loops is a fraction of total area.
            selfLoopRadius = sqrt( bb(1)*bb(2) / (4*n*pi) );
        else
            selfLoopRadius = 0; % just make it non-empty for the next step
        end
    end
    
    if any(bb ~= 0)
        % Here, we need to deal with the case where on dimension of the
        % plot is much larger than the other. In that case, we choose a
        % minimum and maximum radius based on the shorter (non-zero) dimension:
        len = min(bb(bb~=0));
        maxRadius = len/6;  % make sure self-loops are not larger than BB
        minRadius = len/50; % make sure self-loops stay visible
        selfLoopRadius = min(selfLoopRadius, maxRadius);
        selfLoopRadius = max(selfLoopRadius, minRadius);
    else
        % Case where all nodes are in the same spot
        minRadius = 0;
        selfLoopRadius = 1;
    end
    
else % Case Layout_ = 'circle'
    openingAngle = 360/n;
    
    % this is chosen such that, looking outside from the center of the
    % circle, half of the space would be covered by self-loops.
    selfLoopRadius = sind(openingAngle/4) / (1 - sind(openingAngle/4));
    
    % Additional constraints:
    len = 2;
    minRadius = len/50;  % make sure self-loops stay visible
    maxRadius = 0.5;     % make sure self-loops are smaller than the circle
    
    selfLoopRadius = min(selfLoopRadius, maxRadius);
    selfLoopRadius = max(selfLoopRadius, minRadius);
end
end % END computeSelfLoopRadius


function [alpha, isMultedge] = computeOpeningAngle(BasicGraph, XData, YData, selfLoopRadius, minRadius)
% Returns the opening angle for each multiple edge in the graph, in vector
% alpha. This is computed using a number of heuristics described in the
% code. The input minRadius is the minimum distance that the outermost edges
% in a bundle should have; this is not a guarantee, just a preference.

nrNodes = numnodes(BasicGraph);
nrEdges = numedges(BasicGraph);
ed = BasicGraph.Edges;
s = ed(:,1);
t = ed(:,2);

% Compute vector of length numedges, giving number of multiple edges
% connecting its two end nodes - in both directions.
edgeMult = sparse(t, s, 1, nrNodes, nrNodes);
edgeMult = edgeMult + edgeMult';
edgeMult = full(edgeMult(sub2ind(size(edgeMult),s,t)));

isMultedge = (edgeMult > 1) & (s ~= t);

edgeind = matlab.internal.graph.simplifyEdgeIndex(BasicGraph);

% Indexing trick: For example, for [1 1 2 2 2 3 4 4], this would return [1 3 6 7]
firstEdgeMult(flip(edgeind)) = length(edgeind):-1:1;

% For the same case, this gives me edgeMultIndex = [0 1 0 1 2 0 0 1]
edgeMultIndex = cumsum(isMultedge);
edgeMultIndex = edgeMultIndex - edgeMultIndex(firstEdgeMult(edgeind));

% This translates each run 0 to n into an equispaced run from -1 to 1
angleScaling = (edgeMult - 1 - 2*edgeMultIndex) ./ (edgeMult - 1);

% Set constants used later in the code:
maxCycDist = 2*selfLoopRadius;
minCycDist = 2*minRadius;
alphaMin = 1e-4;        % minimum opening angle (numerical problems for smaller values)
alphaMax = 30;          % maximum opening angle (preference)
alphaMaxAbsolute = 150; % maximum opening angle (hard requirement)

% Compute distance between nodes
ed = ed(isMultedge, :);
xdist = abs(diff(XData(ed), [], 2));
ydist = abs(diff(YData(ed), [], 2));
len = hypot(xdist, ydist);

% Compute the maximum opening angle based on three heuristics:

% 1) distance between circle segments must be <= cycDist
alphaMaxDist = 4*atand(maxCycDist./len);
% 2) circle segment must stay in the bounding box defined by start and end node:
alphaBetween = min(2*atand(ydist./xdist), 2*atand(xdist./ydist));
% 3) opening angle must be less than alphaMax

% Combined value of the opening angle
alphaComb = min([alphaMaxDist, alphaBetween], [], 2);
alphaComb = min(alphaComb, alphaMax);

% Make sure distance between edges is still visible
alphaMinDist = 4*atand(minCycDist./len);
alphaComb = max(alphaComb, alphaMinDist);

% Make sure the last step didn't make alphaComb > alphaMaxAbsolute
alphaComb = min(alphaComb, alphaMaxAbsolute);

% If edge length is zero, set that alpha to zero, too:
alphaComb(len==0) = 0;

% If alpha is less than alphaMin, set it to zero (straight edge):
alphaComb(alphaComb<alphaMin) = 0;

% Translate to array alpha over all edges, simple edges have alpha==nan
alpha = nan(nrEdges, 1);
alpha(isMultedge) = alphaComb;

alpha = alpha .* angleScaling;
end % END computeOpeningAngle

function circle = constructCircle(ind, n, selfLoopRadius)
% Teardrop-shape for self-loop

aWithMargin = 45;
a = aWithMargin / n * 0.9;
rotang = ((2*ind-1)/n-1) * aWithMargin;

% Many self-loops change size based on rotang, to fill out the circular
% self-loop we used to have before introducing multigraph:
r = 2*sind(a) * (cosd(rotang) - sind(a)) / cosd(a)^2;

ang = linspace(90-a, 270+a, 35).';
circle = selfLoopRadius*[0 0 0; (r/sind(a)-r*cosd(ang)) r*sind(ang) zeros(35, 1); 0 0 0];

circle = circle * [cosd(rotang) sind(rotang) 0; -sind(rotang) cosd(rotang) 0; 0 0 1];
end % END constructCircle
