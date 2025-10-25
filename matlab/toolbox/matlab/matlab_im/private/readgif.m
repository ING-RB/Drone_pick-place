function [X,map] = readgif(filename, varargin)
%READGIF Read an image from a GIF file.
%   [X,MAP] = READGIF(FILENAME) reads the first image from the
%   specified file.
%
%   [X,MAP] = READGIF(FILENAME, F, ...) reads just the frames in
%   FILENAME specified by the integer vector F.
%
%   [X,MAP] = READGIF(..., 'Frames', F) reads just the specified
%   frames from the file.  F can be an integer scalar, a vector of
%   integers, or 'all'.
%
%   [X,MAP] = READGIF(...,'AutoOrient',tf) same as above, AutoOrient 
%   value is ignored.
%
%   See also IMREAD, IMWRITE, IMFINFO.

%   Copyright 1984-2024 The MathWorks, Inc.

% Handle possibility of numeric index as first positional argument
if numel(varargin)>=1 && isnumeric(varargin{1})
    % Force it to be processed as named argument
    varargin = {'Frames', varargin{1:end}};
end

options = validateArguments(varargin{:});


% Read multiframe GIF image
[X,map] = read_multiframe_gif(filename);

% Remove unwanted frames.
if ~isequal(options.Frames, 'all')
    if any(options.Frames < 1) || any(options.Frames > size(X, 4))            
        error(message('MATLAB:imagesci:readgif:frameCount', size(X, 4)));            
    end
    X = X(:, :, :, options.Frames);
end

end

%--------------------------------------------------------------------------
% Function to read Multiframe GIF files by decoding the transparency and 
% disposal methods of the following images in relation to the base image.
function [X,map] = read_multiframe_gif(filename)

[info,colorTableType] = imgifinfo(filename);

try
    data = matlab.io.internal.imagesci.gifread(filename);
    totalValidFrames = numel(data);
catch ME 
    throwAsCaller(ME);
end

anyValidInfoStructs = true;

% If the number of frames present in the image reported by enquiring for
% information does not match the number of frames determined by reading
% data, compensate by eliminating the corrupt info struct as best as
% possible
if numel(data) ~= numel(info)
    isInfoValid = true(1, numel(info));
    for cntInfo = 1:numel(info)
        for cntData = 1:numel(data)
            % If the Height and Width of an info struct do not match the
            % size of the data, then it is corrupt.
            if size(data{cntData}) == double([info(cntInfo).Height info(cntInfo).Width])
                isInfoValid(cntInfo) = true;
                break;
            end
            isInfoValid(cntInfo) = false;
        end
    end
    % If there is at least one valid info struct, remove any corrupt
    % structs. Otherwise keep the corrupt info structs and mark them so
    % that they will not be used for post processing.
    if any(isInfoValid)
        info(~isInfoValid) = [];       
    else
        anyValidInfoStructs = false;
    end
end

% This only returns the color table for the first frame in the GIF file.
map = info.ColorTable;

if ~anyValidInfoStructs
    % Since our info structs are all corrupt, we don't have valid metadata
    % to use for postprocessing. Return the raw data.
    X = data{:};
    return;
end

% Postprocess the obtained data

% Identify the extents of the image and create a bounding box to enclose
% the image
maxTopVal = max([info.Top] + [info.Height]);
maxLeftVal = max([info.Left] + [info.Width]);
sz = [maxTopVal-1 maxLeftVal-1];
X = zeros([sz(1) sz(2) 1 totalValidFrames],'uint8');

% Base image does not require Postprocessing
X(info(1).Top:info(1).Top+info(1).Height-1, ...
    info(1).Left:info(1).Left+info(1).Width-1, :, 1) = data{1};

undisposed_index = 1;

% Determine appearance of all frames using disposal method and transparency

% Disposal Methods:
% Pixels which are outside of the frame's region are not affected.
%
% 0 - Unspecified: Replace previous frame's region with this frame's
%     region. Typically used for non transparent frames.
%
% 1 - Do Not Dispose: This frame shows through transparent
%     pixels of subsequent frames.
%
% 2 - Restore to Background: Background color shows through
%     transparent pixels of this frame.
%
% 3 - Restore to Previous: Revert to last "Do Not Dispose" or
%     "Unspecified" then apply new frame, displaying "previous"
%     through transparent pixels of new frame.

% Transparency Settings:
% Specify which of the pixels in the GIF frames are transparent.
%
% No: No transparency. The disposal method settings do not matter.
%
% White: White pixels are transparent.
%
% First Pixel: All pixels in the frame having the color of the first
% pixel are considered transparent.
%
% Other: Brings up color picker to select color for transparency.

% Check if the same Global color table or same default color table
% is used for every frame in the GIF file. Every frame of the
% GIF image has one global color table if present or respective
% local color tables. If neither global color table or local
% color tables are present, then a default table is used.
hasLocalColorTable = checkIfLocalColorTableUsed(colorTableType);

% Decode the current frame in relation to previous frame
for j = 2:totalValidFrames
    % Obtain the composited image
    [tempImage, undisposed_index] = ...
        handle_positive_base_frame(data{j}, info(j), X(:,:,:,undisposed_index), ...
                                   X(:,:,:,j-1), undisposed_index, j,map,hasLocalColorTable);
    % Place the composited image in the appropriate location
    X(1:size(tempImage, 1), 1:size(tempImage, 2),:,j) = tempImage;
end
end


%--------------------------------------------------------------------------
% Function to return the decoded GIF image based on the current frame, 
% previous frame, transparent color and disposal method.
function [imdata, undisposed_index] = handle_positive_base_frame(current_frame,...
                                                                 current_info,...
                                                                 undisposed_frame,...
                                                                 previous_frame,...
                                                                 undisposed_index,...
                                                                 current_index,...
                                                                 map,...
                                                                 hasLocalColorTable)

% Get region's row and column indices.
region.left   = current_info.Left;
region.top    = current_info.Top;
region.width  = current_info.Width;
region.height = current_info.Height;
region.right  = region.left + region.width - 1;
region.bottom = region.top + region.height - 1;

% Get the Disposal Method
% If Disposal Method is not set for this frame ([]) or is not present in
% the file at all, set disposalMethod to 'RestorePrevious'.
disposalMethod = 'RestorePrevious'; 
if isfield(current_info, 'DisposalMethod') && ~isempty(current_info.DisposalMethod)
    disposalMethod = current_info.DisposalMethod;
end

switch (lower(disposalMethod))
    case lower('DoNotspecify')
        disposalNum = 0;
    case lower('LeaveInPlace')
        disposalNum = 1;
    case lower('RestoreBG')
        disposalNum = 2;
    case lower('RestorePrevious')
        disposalNum = 3;
    otherwise % Default Restore Previous
        disposalNum = 3;
end

% Pad the current frame if necessary.
temp_frame = current_frame;
current_frame = zeros(size(previous_frame),'uint8');
current_frame(region.top:region.bottom, region.left:region.right) = temp_frame;

% Check if there are transparent pixels in the GIF frame
% (If there is no TransparentColor field - there are no transparent pixels in
% the file; if TransparentColor is [], this frame has no transparent
% pixels, but others in the file do; otherwise this frame has transparent pixels)
if isfield(current_info, 'TransparentColor') && ~isempty(current_info.TransparentColor)
    % converting transparent color from one-based to zero-based indexing
    transparent_pixels = current_frame == (current_info.TransparentColor-1);
else
    transparent_pixels = [];
end

% If optimize is set to true, current frame need not be converted
% as it should render properly.
if hasLocalColorTable
    % If the current frame's color table and previous's frame
    % color is different then convert the current frame such
    % that it can render correctly using the first color table.
    
    current_frame = transformCurrentFrame(current_frame, current_info, map);
end


% Decode as per the disposal method
switch (disposalNum)
    
    % Currently imread returns only the first local
    % color table (if present).
    % Using the first local color table to read all the frames later
    % shows distorted frames of the image.
    % 
    % Rescale the frames (starting from second
    % frame) such that it works correctly when rendered using the first 
    % local color table.
    %
    % Algorithm:
    % 1. Save the transparent pixels of the current frame.
    % 2. Rescale the non-transparent current frame such that it renders
    %    properly with the first local color map (if one exist).
    %    
    %    To rescale just the non-transparent pixels, do the following:
    %      a. Rescale the current frame using the first local color map
    %      b. Restore the transparent pixels from step 1 and apply 
    %         the background color or the previous frame's transparent
    %         color.
   
    case 0 % Do not Specify
        
        % Check if there are transparent pixels in the GIF image. With
        % disposal method set to "Do not specify", the frame should have
        % non-transparent pixels only. But there are scenarios when the GIF
        % file may not be well-formed, in which case, the transparent
        % pixels are replaced with the background color if it exists, or
        % with previous frame otherwise.
        if ~isempty(transparent_pixels)
            % BackgroundColor field always exists
            if isempty(current_info.BackgroundColor)
                current_frame(transparent_pixels) = previous_frame(transparent_pixels);
            else
                % converting background color from one-based to zero-based indexing
                current_frame(transparent_pixels) = (current_info.BackgroundColor-1);
            end
        end

        % Replace the previous frame's region with the new region.
        previous_frame(region.top:region.bottom, region.left:region.right) = ...
            current_frame(region.top:region.bottom, region.left:region.right);
        imdata = previous_frame;
        undisposed_index = current_index;
        
    case 1 % Do not Dispose

        % Replace the transparent pixels with the previous frame
        if ~isempty(transparent_pixels)
            current_frame(transparent_pixels) = previous_frame(transparent_pixels);
        end
        
        previous_frame(region.top:region.bottom, region.left:region.right) = ...
            current_frame(region.top:region.bottom, region.left:region.right);
        imdata = previous_frame;
        undisposed_index = current_index;
    
    case 2 % Restore to Background
        
        % Replace the transparent pixels with the background color
        % If there is no background color, leave them as transparent
        % (BackgroundColor field always exists)
        if ~isempty(transparent_pixels) && ~isempty(current_info.BackgroundColor)
            % converting background color from one-based to zero-based indexing
            current_frame(transparent_pixels) = (current_info.BackgroundColor-1);
        end
        
        % Copy the obtained frame into the corresponding region in old frame
        previous_frame(region.top:region.bottom, region.left:region.right) = ...
            current_frame(region.top:region.bottom, region.left:region.right);
        imdata = previous_frame;
        
    case 3 % Restore to Previous

         % Replace the transparent pixels with the undisposed frame pixels
        if ~isempty(transparent_pixels)
            current_frame(transparent_pixels) = undisposed_frame(transparent_pixels);
        end
        
        % Copy the obtained frame into the corresponding region in old frame
        previous_frame(region.top:region.bottom, region.left:region.right) = ...
            current_frame(region.top:region.bottom, region.left:region.right);
        imdata = previous_frame;
       
    otherwise
        error(message('MATLAB:imagesci:readgif:corruptGIFfile')); 
end

end

%------------------------------------------------------------------------
% Helper method to convert the GIF frame to RGB and vice-versa.
function current_frame = transformCurrentFrame(current_frame,current_info,map) 
% Convert the current frame to RBG using the  respective local color table.
tempRGB = ind2rgb(current_frame,current_info.ColorTable);
% Convert the RGB frame back to indexed image using the first color table
current_frame = rgb2ind(tempRGB,map);

end

%-------------------------------------------------------------------------
% Helper method to check if Global color table or default color table
% is used in every GIF Frame.
function hasLocalColorTable = checkIfLocalColorTableUsed(colorTableType)
hasLocalColorTable = true;
index = colorTableType == 1; % 1 represent global color table
% If Global color table is true for all GIF frames, then set optimize to true
if all(index)
    hasLocalColorTable = false;
else
    index = colorTableType == 3; % 3 represents local color table
    % If Default color table is true for each GIF frame, then set 
    % optimize to true.
    if all(index)
        hasLocalColorTable = false;
    end
end
end


function options = validateArguments(options)
arguments
    options.Frames (1,:) {validateFrames(options.Frames)} = 1

    % AutoOrient value is ignored for GIF images
    options.AutoOrient (1,1) {mustBeA(options.AutoOrient,'logical')} = false 
end

end

function validateFrames(frames)
% This initial validation is necessary to accurately display the valid
% options in the error message
validateattributes(frames, {'numeric', 'char', 'string'}, {'nonempty'});

% No necessity to perform any specific checks for string as it
% would have been converted into character vectors before this
% private helper is called.
if ischar(frames)
    validatestring(frames,{'all'}, '', 'Frames');
else
    validateattributes(frames,{'numeric'},{'nonempty','vector'},'','Frames');
end
end