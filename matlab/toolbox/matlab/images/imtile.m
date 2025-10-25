function out = imtile(varargin)

[ Isrc, cmap, gridSize, indices, thumbnailSize, thumbnailInterp, ...
                borderSize, backgroundColor] = parse_inputs(varargin{:});

% Waitbar should never be used from imtile
waitbarEnabled = false;

out = images.internal.createMontage(Isrc, thumbnailSize, thumbnailInterp, ...
    gridSize, borderSize, backgroundColor, indices, cmap, waitbarEnabled);

end

function flag = isStringOrChar(x)
    flag = isstring(x) || ischar(x);
end

function[ I, cmap, gridSize, idxs, thumbnailSize, thumbnailInterp, ...
                    borderSize, backgroundColor] = parse_inputs(varargin)

narginchk(1, 12);

% Initialize variables
thumbnailSize = [];
thumbnailInterp = "bicubic";
cmap = [];
gridSize = [];
borderSize = [0 0];
backgroundColor = [];

I = varargin{1};
if iscell(I)
    nframes = numel(I);

    % Error out for mix and match of filenames and images
    isFileName = isStringOrChar(I{1});

    % If the first value in cell array is file name, all the entries should
    % be filenames else no entries should be filename
    if isFileName
        if ~all(cellfun(@isStringOrChar, I))
            error(message('MATLAB:images:montage:mixedInput'));
        end
    else
        if ~all(~cellfun(@isStringOrChar, I))
            error(message('MATLAB:images:montage:mixedInput'));
        end
    end

elseif isstring(I)
    nframes = numel(I);

elseif ischar(I)
    % If char : imtile('peppers.png'), convert the filename to string
    I = string(I);
    varargin{1} = I;
    nframes = 1;

elseif isa(I,'matlab.io.datastore.ImageDatastore')
    nframes = numel(I.Files);

else
    validateattributes(I, {'uint8' 'double' 'uint16' 'logical' 'single' 'int16'}, {}, ...
        mfilename, 'I, BW, or RGB', 1);

    if isa(I,'dlarray')
        error(message('MATLAB:images:montage:dlarrayNotSupported'));
    end

    if ndims(I)==4 % MxNx{1,3}xP
        if size(I,3)~=1 && size(I,3)~=3
            error(message('MATLAB:images:montage:notVolume'));
        end
        nframes = size(I,4);
    elseif ndims(I)>4
            error(message('MATLAB:images:montage:notVolume'));
    else
        nframes = size(I,3);
    end
end

varargin(2:end) = matlab.images.internal.stringToChar(varargin(2:end));
charStart = find(cellfun('isclass', varargin, 'char'),1,'first');

idxs = [];

if isempty(charStart) && nargin==2 || isequal(charStart,3)
    % IMTILE(X,MAP)
    % IMTILE(X,MAP,Param1,Value1,...)
    cmap = varargin{2};
end

if isempty(charStart) && (nargin > 2)
    error(message('MATLAB:images:montage:nonCharParam'))
end


paramStrings = { 'GridSize', 'Frames', 'ThumbnailSize', ...
                'ThumbnailInterpolation', 'BorderSize', 'BackgroundColor'};
for k = charStart:2:nargin
    param = lower(varargin{k});
    inputStr = validatestring(param, paramStrings, mfilename, 'PARAM', k);
    valueIdx = k + 1;
    if valueIdx > nargin
        error(message('MATLAB:images:montage:missingParameterValue', inputStr));
    end
    
    switch (inputStr)
        case 'GridSize'
            gridSize = varargin{valueIdx};
            validateattributes(gridSize,{'numeric'},...
                {'vector','positive','numel',2}, ...
                mfilename, 'GridSize', valueIdx);
            if all(~isfinite(gridSize))
                gridSize = [];
            else
                gridSize = double(gridSize);
                t = gridSize;
                t(~isfinite(t)) = 0;
                validateattributes(t,{'numeric'},...
                    {'vector','integer','numel',2}, ...
                    mfilename, 'GridSize', valueIdx);
            end
            
        case 'ThumbnailSize'
            thumbnailSize = varargin{valueIdx};
            if ~isempty(thumbnailSize)
                validateattributes(thumbnailSize,{'numeric'},...
                    {'vector','positive','numel',2}, ...
                    mfilename, 'ThumbnailSize', valueIdx);
                if all(~isfinite(thumbnailSize))
                    thumbnailSize = [];
                else
                    thumbnailSize = double(thumbnailSize);
                    t = thumbnailSize;
                    t(~isfinite(t))=0;
                    validateattributes(t,{'numeric'},...
                        {'vector','integer','numel',2}, ...
                        mfilename, 'ThumbnailSize', valueIdx);
                end
            end

        case 'ThumbnailInterpolation'
            % Not supporting custom interpolation kernels
            thumbnailInterp = varargin{valueIdx};
            validateattributes( thumbnailInterp, ["string", "char"], ...
                    "scalartext", mfilename, "ThumbnailInterpolation", ...
                    valueIdx ); 
            
        case 'Frames'
            validateattributes(varargin{valueIdx}, {'numeric','logical'},...
                {'integer','nonnan'}, ...
                mfilename, 'Frames', valueIdx);
            idxs = varargin{valueIdx};
            idxs = idxs(:);
            if islogical(idxs)
                if numel(idxs) > nframes
                    error(message('MATLAB:images:montage:logicalArrayLarger'));
                end

                % Convert logical array mask to Indices
                idxs = find(idxs);
            end

            invalidIdxs = ~isempty(idxs) && any(idxs < 1) || any(idxs > nframes);
            if invalidIdxs
                error(message('MATLAB:images:montage:invalidFrames'));
            end
            idxs = double(idxs(:));

            if isempty(idxs)
                % Empty image if idxs was explicitly set to []
                I = [];
            end

        case 'BorderSize'
            borderSize = varargin{valueIdx};
            if isscalar(borderSize)
                borderSize = [borderSize, borderSize]; %#ok<AGROW>
            end
            validateattributes(borderSize, {'numeric', 'logical'},...
                {'integer', '>=',0 , 'numel', 2, 'nrows', 1}, ...
                mfilename, 'BorderSize', valueIdx);
            borderSize = double(borderSize);
            
        case 'BackgroundColor'
            backgroundColor = varargin{valueIdx};
            backgroundColor = convertColorSpec(images.internal.ColorSpecToRGBConverter,backgroundColor);
            backgroundColor = images.internal.touint8(backgroundColor);
            backgroundColor = reshape(backgroundColor, [1 1 3]);
    end
end

end

%   Copyright 2018-2023 The MathWorks, Inc.
