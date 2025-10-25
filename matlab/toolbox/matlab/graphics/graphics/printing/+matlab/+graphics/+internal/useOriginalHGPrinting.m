function useOrig = useOriginalHGPrinting( varargin ) 
% This undocumented helper function is for internal use.

%USEORIGINALHGPRINTING checks for HG objects and isSLorSF to see whether to 
% use "Original" or "Latest" printing
%
%   Ex:
%      useOriginal = USEORIGINALHGPRINTING();
%
%   See also PRINT, PRINTOPT, INPUTCHECK, VALIDATE.

%   Copyright 2008-2020 The MathWorks, Inc.

    if nargin && ~isempty(varargin{1})
        % if given something to print, check it
        % only HG objects go through new print pipeline. 
        % Stateflow, even with a figure that use the new MATLAB graphics 
        %   system introduced in Release 2014b, goes through their own 
        %   printing pipeline.
        %   the figure itself isn't printed; there's a "portal" object that 
        %   holds a reference to a chart that is.
        check.Handles = varargin(1);
        if ~all(ishghandle(varargin{1})) || matlab.graphics.internal.isSLorSF(check)
           useOrig = true;
        else
           useOrig = false;
        end 
    else
        % no args, or an empty arg list
        useOrig = false;
    end
end
