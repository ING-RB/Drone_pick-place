function h = imagesc(varargin)
%IMAGESC Display image with scaled colors
%   IMAGESC(...) is the same as IMAGE(...) except the data is scaled
%   to use the full colormap.
%
%   IMAGESC(...,CLIM) where CLIM = [CLOW CHIGH] can specify the
%   scaling.
%
%   See also IMSHOW, IMAGE, COLORBAR, IMREAD, IMWRITE.

%   Copyright 1984-2023 The MathWorks, Inc.

import matlab.graphics.internal.isCharOrString;

clim = [];
if nargin == 0
    % Really no args.  Just add CDataMapping.
    hh = image('CDataMapping', 'scaled');
else
    checkArgs = varargin;
    % Check to see if the first argument is a handle.
    if nargin >= 1 && isa(varargin{1}, 'matlab.graphics.Graphics')
        % Remove this arg for the sake of examining inputs.
        checkArgs(1) = [];
    end
    nCheckArgs = numel(checkArgs);
    if nCheckArgs > 1
        % Determine if last input is clim
        if isequal(size(checkArgs{end}),[1 2])
            % Last input is 1x2 vector.  Might be clims.
            
            % Look for param/value pairs.
            str = false(nCheckArgs,1);
            for n=1:length(checkArgs)
                str(n) = isCharOrString(checkArgs{n});
            end
            str = find(str);
            if ~(isempty(str) && nCheckArgs == 3)
                % We are not in the imagesc(x, y, C) case.
                if isempty(str) || (rem(nCheckArgs-min(str),2)==0)
                    % There were no param / value pairs, or there were and
                    % the last arg was not part of one.
                    % Remove clims from original arg list.
                    clim = varargin{end};
                    varargin(end) = []; % Remove last cell
                end
            end
        end
    end
    
    hh = image(varargin{:}, 'CDataMapping', 'scaled');
end

% Get the parent Axes of the image
cax = ancestor(hh,'axes');

if ~isempty(clim)
    set(cax,'CLim',clim)
elseif any(strcmpi(cax.NextPlot,{'replaceall','replace'}))
    set(cax,'CLimMode','auto')
end

if nargout > 0
    h = hh;
end
