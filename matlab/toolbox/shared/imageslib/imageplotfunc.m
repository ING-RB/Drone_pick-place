function varargout = imageplotfunc(action,fname,inputnames,inputvals)
% IMAGEPLOTFUNC
%   This is an undocumented function and may be removed in a future release.

% IMAGEPLOTFUNC  Support function for Plot Picker component. The function
% may change in future releases.

% Copyright 2009-2023 The MathWorks, Inc.

% Determine if IPT functions should be enabled
if strcmp(action,'defaultshow')
    
    n = length(inputvals);
    toshow = false;
    
    switch lower(fname)
        
        case "imageviewer"
            
            if n == 1 || n == 2
                
                I = inputvals{1};
                
                % a filename is a string containing a '.'.  We put this
                % check in first so that we can bail out on non-filename
                % strings before calling EXIST which will hit the file
                % system.
                isStringContainingDot = ischar(I) && numel(I) > 2 && ...
                    contains(I(2:end-1),'.');
                
                isfile = false;
                if isStringContainingDot

                    dotLoc = strfind(I,'.');
                    fileExt = I( (dotLoc+1) : end);
                    
                    [~,extNames] = parseSharedImageFormats;
                    
                    % Check to see whether file extention matches any of
                    % the valid IPT file extentions
                    isValidExtention = false;
                    for i = 1:length(extNames)
                        if any(strcmp(fileExt,extNames{i}))
                            isValidExtention = true;
                            break;
                        end
                    end
                    
                    % If string is filename with a valid image file
                    % extention, do final most exensive operation of
                    % hitting filesystem to see whether this file exists.
                    if isValidExtention
                        isfile = exist(which(I),'file');
                    end
                end
                          
                is2d = ismatrix(I);
                is3d = ndims(I) == 3;
                isntVector = min(size(I)) > 1;
                
                % define image types
                isgrayscale = ~isfile && isnumeric(I) && is2d && isntVector;
                isindexed = isgrayscale && isinteger(I);
                istruecolor = ~isfile && isnumeric(I) && is3d && ...
                    isntVector && size(I,3) == 3;
                isbinary = ~isfile && islogical(I) && is2d && isntVector;
                
                toshow = isfile || isgrayscale || isindexed || ...
                    istruecolor || isbinary;
                
                % if 2 variables are selected...
                if toshow && n == 2
                    
                    arg2 = inputvals{2};
                    
                    iscolormap = ismatrix(arg2) && size(arg2,2) == 3 && ...
                        all(arg2(:) >= 0 & arg2(:) <= 1);
                    isdisplayrange = isnumeric(arg2) && isvector(arg2) && ...
                        length(arg2) == 2 && arg2(2) > arg2(1);
                    
                    if isindexed && iscolormap
                        % imshow(X,map)
                        toshow = true;
                        
                    elseif isgrayscale && isdisplayrange
                        % imshow(I,[low high])
                        toshow = true;
                        
                    else
                        toshow = false;
                        
                    end
                    
                end
                
            end
            
        case "implay"
            
            if n == 1 || n == 2
                
                I = inputvals{1};
                
                % a filename is a string containing a '.avi'.  We put this
                % check in first so that we can bail out on non-filename
                % strings before calling EXIST which will hit the file
                % system.
                
                % an AVI file
                isAviFile = ischar(I) && numel(I) > 4 && ...
                    strcmpi(I(end-3:end),'.avi') && exist(which(I),'file');
                
                % a struct returned from IMMOVIE
                isMovieStruct = isstruct(I) && ...
                    isequal(fieldnames(I),{'cdata','colormap'}');
                
                [is3d, is4d] = deal(false);
                if isnumeric(I) || islogical(I)
                    is3d = ndims(I) == 3;
                    is4d = ndims(I) == 4;
                end
                
                % logical must be MxNxK or MxNx1xK
                isValidLogicalStack = islogical(I) && ...
                    (is3d || ...
                    (is4d && size(I,3) == 1));
                
                % numeric stacks must be MxNxK or MxNx[1|3]xK
                isValidNumericStack = isnumeric(I) && ...
                    (is3d || ...
                    (is4d && (size(I,3) == 1 || size(I,3) == 3)));
                
                toshow = isAviFile || isMovieStruct || ...
                    isValidLogicalStack || isValidNumericStack;
                
                % if 2 variables are selected, second should be FPS (frames/sec)
                if toshow && n == 2
                    
                    fps = inputvals{2};
                    
                    if isscalar(fps) && isnumeric(fps)
                        toshow = true;
                    else
                        toshow = false;
                    end
                end
                
            end
            
    end
    varargout{1} = toshow;
    
elseif strcmp(action,'defaultdisplay')
    % Determine custom execution text for IPT functions. Default execution text
    % is not generated here.
    
    dispStr = '';
    switch lower(fname)
        
        % Suppress the appended figure(gcf) for imtool & implay
        case "imageviewer"
            switch(numel(inputnames))
                case 1
                    dispStr = "imageViewer(" + inputnames{1} + ");";
                case 2
                    dispStr = "imageViewer(" + inputnames{1} + ...
                                        ",Colormap=" + inputnames{2} + ");";
                otherwise
                    assert( false, "Invalid Number of Input Args");
            end

            dispStr = char(dispStr);
            
        case "implay"
            inputNameArray = [inputnames(1:end-1);repmat({','},1,length(inputnames)-1)];
            dispStr = ['implay(' inputNameArray{:} inputnames{end} ');'];
            
    end
    
    varargout{1} = dispStr;
    
end

