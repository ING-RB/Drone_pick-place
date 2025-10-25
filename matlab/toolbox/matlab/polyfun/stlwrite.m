function stlwrite(tri, filename, varargin)
%STLWRITE Create STL file from triangulation
%   STLWRITE(TR, filename) writes a triangulation TR to a binary STL file
%   filename. The triangulation can be either a triangulation object or a
%   2-D delaunayTriangulation object.
% 
%   STLWRITE(TR, filename, fileformat) also specifies a file format for the
%   written file. fileformat can be either 'binary' (default) or 'text'.
%
%   STLWRITE(__, 'Attribute', attributes) includes binary attributes,
%   specified as a uint16 vector. The length of attributes must be equal to
%   the number of triangles in the triangulation. This parameter is
%   supported for binary format only.
%
%   STLWRITE(__, 'SolidIndex', solidID) includes a vector of identification
%   numbers. The identification numbers assign each triangle to a grouping
%   of triangles in the triangulation. The length of solidID is equal to
%   the number of triangles in the triangulation. This parameter is
%   supported for text format only.

% Copyright 2018-2019 The MathWorks, Inc.

% Check input tri
if ~isa(tri, 'triangulation')
    error(message('MATLAB:polyfun:NotTriangulation'));
elseif isempty(tri.Points) || isempty(tri.ConnectivityList)
    error(message("MATLAB:polyfun:EmptyTriangulation"));
end

ntri = size(tri.ConnectivityList, 1);
nvtx = size(tri.ConnectivityList, 2);
if nvtx ~= 3
    error(message('MATLAB:polyfun:stlTrisOnly'))
end

% Extract properties of triangulation tri
tw.Faces = tri.ConnectivityList;
tw.Vertices = tri.Points;
if size(tw.Vertices, 2) == 2
    tw.Vertices(:, 3) = 0;
end
tw.Normals = faceNormal(tri);

% Check filename
if ~isScalarText(filename)
    error(message('MATLAB:polyfun:stlFileName'));
end

% Parse Format and NV pairs
[tw.Format, tw.Attributes, tw.SolidIndex] = parseInputs(ntri, varargin{:});

% Reorder triangles so that triangles in the same solid are in one block,
% with ascending SolidIndex.
if ~isempty(tw.SolidIndex)
    [tw.SolidIndex, ind] = sort(tw.SolidIndex);
    tw.Faces = tw.Faces(ind, :);
    tw.Normals = tw.Normals(ind, :);
end

ST = matlab.internal.meshio.stlwrite(filename, tw);

switch ST.ErrorCode
    case 0 % NO_STL_ERROR
    case 1 % INVALID_FILE_EXTENSION
        error(message("MATLAB:polyfun:stlFileExtension"));
    otherwise % assume 2 - FILE_OPEN_FAILED
        error(message("MATLAB:polyfun:stlFileCannotOpen", filename));
    % Other ErrorCode, not expected here:
    % 3 - FILE_EMPTY (stlread only)
    % 4 - INVALID_STL_FORMAT (stlread only)
    % 5 - FILE_WRITE_FAILED (error while writing the file)
    % 6 - INVALID_DATA (invalid input struct provided to internal function)
end

end

%-----------------------------------------------------------------
function [Format, Attribute, SolidIndex] = parseInputs(ntri, varargin)
Format = 'binary'; %default
Attribute = zeros(ntri, 1, 'uint16');
SolidIndex = ones(ntri, 1);

ninputs = numel(varargin);
if ninputs == 0
    return 
end

this_arg = varargin{1};
if isScalarText(this_arg)
    cmpLength = max(strlength(this_arg), 1);
    if (strncmpi(this_arg, 'text', cmpLength))
        Format = 'text';
        varargin(1) = [];
    elseif (strncmpi(this_arg, 'binary', cmpLength))
        Format = 'binary';
        varargin(1) = [];
    end
end

if mod(numel(varargin), 2) ~= 0
    error(message("MATLAB:polyfun:nameValueError"));
end
for k = 1:2:numel(varargin)
    this_arg = varargin{k};
    if ~isScalarText(this_arg)
        error(message("MATLAB:polyfun:stlWriteParameter"));
    end
    
    cmpLength = max(strlength(this_arg), 1);
    if (strncmpi(this_arg, 'Attribute', cmpLength))
        Attribute = checkAttribute(varargin{k+1}, ntri, Format);
    elseif (strncmpi(this_arg, 'SolidIndex', cmpLength))
        SolidIndex = checkSolidIndex(varargin{k+1}, ntri, Format);
    else
        error(message("MATLAB:polyfun:stlWriteParameter"));
    end
end

end


function B = checkAttribute(A, ntri, Format)

% Special-case: Some empty inputs are treated as default
szA = size(A);
acceptedEmpty = isequal(szA, [0 0]) || isequal(szA, [ntri 0]) || isequal(szA, [0 ntri]);
if isa(A, 'uint16') && acceptedEmpty
   B = zeros(ntri, 1, 'uint16');
   return;
end

if Format == "text"
    error(message("MATLAB:polyfun:stlAttributeNoEffect"))
end

if ~(isa(A, 'uint16') && isvector(A) && isreal(A))
    error(message("MATLAB:polyfun:stlAttributeType"));
end

if length(A) ~= ntri
    error(message("MATLAB:polyfun:stlAttributeSize", ntri));
end

B = A(:);
end


function B = checkSolidIndex(A, ntri, Format)
% Special-case: Some empty inputs are treated as default
szA = size(A);
acceptedEmpty = isequal(szA, [0 0]) || isequal(szA, [ntri 0]) || isequal(szA, [0 ntri]);
if isnumeric(A) && acceptedEmpty
    B = ones(ntri, 1);
    return;
end

if Format == "binary"
    error(message("MATLAB:polyfun:stlSolidIndexNoEffect"))
end

if ~(isnumeric(A) && isvector(A) && isreal(A) && ~issparse(A) && ...
        all(isfinite(A) & (A > 0) & (A == floor(A))))
    error(message("MATLAB:polyfun:stlSolidIndexType"));
end

if numel(A) ~= ntri
    error(message("MATLAB:polyfun:stlSolidIndexSize", ntri));
end

B = double(A(:));

end


function tf = isScalarText(c)
    tf = (ischar(c) && (isrow(c) || isequal(size(c), [0 0]))) || (isstring(c) && isscalar(c));
end
