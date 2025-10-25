function [isaxarray,outarr]=objArrayDispatch(func,varargin)
% This function is undocumented and may change in a future release.

% Dispatches a function to multiple axes
%   Copyright 2019-2023 The MathWorks, Inc.

    outarr=gobjects;
    isaxarray=false;
    args=varargin;
    if isempty(args) || isempty(args{1}) || isscalar(args{1})
        return
    end
    isAllowed=@(obj)isa(obj,'matlab.graphics.mixin.CurrentAxes') || ...
                    isa(obj,'matlab.graphics.layout.Layout') || ...
                    isa(obj,'matlab.graphics.illustration.Legend') || ...
                    isa(obj,'matlab.graphics.illustration.ColorBar');

    axarr=args{1};
    args(1)=[];

    % For validation, use a copy of axarr which is converted to handle if 
    % axarr is a double
    haxarr = axarr;
    if isa(axarr,'double')
        if any(isgraphics(axarr), 'all')
            haxarr = handle(axarr);
        else
            return
        end
    end

    % All items in the list should be in the allowed list
    if all(~arrayfun(isAllowed,haxarr),'all')
        return
    end

    isaxarray=true;
    
    % Error for heterogeneous arrays
    isHomogeneous=all(arrayfun(@(x)strcmp(class(x),class(haxarr)),haxarr), 'all');
    if ~isHomogeneous
        throwAsCaller(MException(message('MATLAB:rulerFunctions:MixedAxesVector')))
    end
        
    % Loop over axarr
    if nargout>1
        % the calling function has an output
        outarr=gobjects(size(axarr));
        for i = 1:numel(axarr)
            try
                outarr(i)=func(axarr(i),args{:});
            catch me
                throwAsCaller(me)
            end
        end
    else
        for i = 1:numel(axarr)
            try
                func(axarr(i),args{:});
            catch me
                throwAsCaller(me)
            end
        end
    end
end
