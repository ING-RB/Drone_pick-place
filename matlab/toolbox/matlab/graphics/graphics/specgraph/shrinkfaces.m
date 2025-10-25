function [fout, vout] = shrinkfaces(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

[p, faces, verts, sf] = parseargs(nargin,varargin);
origNumVerts = height(verts);
origNumFaces = height(faces);

if length(sf)>1
    error(message('MATLAB:shrinkfaces:NonScalarFactor'));
end
if sf<0
    error(message('MATLAB:shrinkfaces:NonPositiveFactor'));
end

if isempty(sf)
    sf = sqrt(.3);
end

nanindex = isnan(faces);
[faces, verts, newFVCDIdx] = facesvertsnoshare(faces, verts);
fcols = size(faces,2);
coords = verts(faces',:);
facexyz = reshape(coords,fcols,numel(coords)/fcols);

av = nanmean(facexyz);
av = repmat(av,[fcols 1]);

facexyz = facexyz*sf - av*(sf-1);

verts(faces',:) = reshape(facexyz, size(coords));
faces(nanindex) = nan;

if nargout==0
    if ~isempty(p)
        newData = {'Faces', faces, 'Vertices', verts};

        % FaceVertexCData needs to be updated if the original FVCD matched
        % up to the original number of vertices, but not faces.
        origFVCD = p.FaceVertexCData;
        vertsMatchFVCD = origNumVerts == height(origFVCD);
        facesMatchFVCD =  origNumFaces == height(origFVCD);
        if vertsMatchFVCD && ~facesMatchFVCD
            newFVCD = origFVCD(newFVCDIdx,:);
            newData = [newData {'FaceVertexCData',newFVCD}];
        end

        set(p, newData{:});
    else
        fout.faces = faces;
        fout.vertices = verts;
    end
elseif nargout==1
    fout.faces = faces;
    fout.vertices = verts;
else
    fout = faces;
    vout = verts;
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [p, faces, verts, sf] = parseargs(nin, vargin)

p=[];
sf = [];

if nin==1 || nin==2           % shrinkfaces(p), shrinkfaces(fv), shrinkfaces(arg, sf)
    firstarg = vargin{1};
    if isstruct(firstarg)
        faces = firstarg.faces;
        verts = firstarg.vertices;
    elseif all(ishandle(firstarg)) && all(strcmp(get(firstarg, 'type'), 'patch'))
        p = firstarg;
        faces = get(p, 'faces');
        verts = get(p, 'vertices');
    else
        error(message('MATLAB:shrinkfaces:InvalidFirstArgument'));
    end
    if nin==2
        sf = vargin{2};
    end
elseif nin==3            %shrinkfaces(f, v, sf)
    faces = vargin{1};
    verts = vargin{2};
    sf = vargin{3};
else
    error(message('MATLAB:shrinkfaces:WrongNumberOfInputs'));
end

if ~isempty(sf)
    if sf>=0
        sf = sqrt(sf);
    else
        sf = -sqrt(-sf);
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [newf, newv, newFVCDIdx]=facesvertsnoshare(f, v)
fcols = size(f,2);
fmax = 1+max(f(:));
nanindex = isnan(f);
f(nanindex)=fmax;
findex = f';
v(fmax,:) = nan*zeros(1,size(v,2));

newv = v(findex,:);
vrows = size(newv,1);
newf = reshape(1:vrows, fcols, vrows/fcols)';
vindex = 1:height(v);
newFVCDIdx = vindex(findex);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function y = nanmean(x)
%NANMEAN Average or mean ignoring NaNs.
%   NANMEAN(X) returns the average treating NaNs as missing values.
%   For vectors, NANMEAN(X) is the mean value of the non-NaN
%   elements in X.  For matrices, NANMEAN(X) is a row vector
%   containing the mean value of each column, ignoring NaNs.

if isempty(x) % Check for empty input.
    y = NaN;
    return
end

% Replace NaNs with zeros.
nans = isnan(x);
i = find(nans);
x(i) = zeros(size(i));

if min(size(x))==1
    count = length(x)-sum(nans);
else
    count = size(x,1)-sum(nans);
end

% Protect against a column of all NaNs
i = find(count==0);
count(i) = ones(size(i));
y = sum(x)./count;
y(i) = i + NaN;
end