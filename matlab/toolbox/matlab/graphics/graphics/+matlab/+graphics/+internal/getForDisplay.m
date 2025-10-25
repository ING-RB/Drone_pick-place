function getForDisplay(varname, varargin)
    % This is an undocumented function and may be removed in a future release.

    % Copyright 2014-2022 The MathWorks, Inc.
    if nargin == 1
         s = getString(message('MATLAB:graphicsDisplayText:FooterLinkFailureMissingVariable',varname));
         disp(s)
    else
        obj = varargin{1};
        classname = varargin{2};
        if ~isa(obj,classname)
            dots = strfind(classname,'.');
            if ~isempty(dots)
                classname = classname(dots(end)+1:end);
            end
            s = getString(message('MATLAB:graphicsDisplayText:FooterLinkFailureClassMismatch',varname, classname));
            disp(s)
        elseif ~isvalid(obj)
            s = getString(message('MATLAB:graphicsDisplayText:FooterLinkFailureDeleted',varname));
            disp(s)
        elseif ~isscalar(obj)
            s = getString(message('MATLAB:graphicsDisplayText:FooterLinkFailureNonScalar',varname));
            disp(s)
        else
            try
                get(obj)
            catch e
                s = getString(message('MATLAB:graphicsDisplayText:FooterLinkFailureUnknown',varname));
                s = [s ' ' e.message];
                matlab.internal.display.printWrapped(s);
            end
        end
    end
end