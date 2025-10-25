function [parent, args] = peelFirstArgParent(args, allowDoubleAxesHandle)
% This function is undocumented and may change in a future release.

%   Copyright 2021-2022 The MathWorks, Inc.

%peelFirstArgParent finds potential parents for chart objects in args{1}
%   [parent, args] = peelFirstArgParent(args) for a cell array args, finds
%   potential parents for chart objects in args{1}, returns them in parent,
%   and removes them from the returned args.
%
%   A potential parent is anything that is a matlab.graphics.Graphics.
%
%   If no parent is specified an empty double is returned for parent. Note 
%   that this should be considered distinct to an empty graphics object,
%   which refers to an explicitly specified empty parent.
%
%   peelFirstArgParent(args, true) will also allow scalar double axes handle 
%   parents. This is intended for compatibility only and should not be used
%   for new functions.


arguments
    % Cell-array of inputs provided by the user.
    args cell = {}

    % For compatibility only, treat scalar double axes handles as valid
    % parents. New functions should not accept double handles as parents.
    allowDoubleAxesHandle (1,1) logical = false
end

parent = [];
if isempty(args)
    return
end

if isa(args{1}, 'matlab.graphics.Graphics')
    parent = args{1};
    args(1) = [];
elseif isa(args{1}, 'double') && isscalar(args{1}) && isgraphics(args{1}, 'matlab.graphics.axis.Axes')
    if allowDoubleAxesHandle
        % This should be used for compatibility only. New functions should
        % not accept double handles as parents.
        parent = handle(args{1});
        args(1) = [];
    else
        % This function does not accept double handles as parents, but the above
        % conditional identifies double handles that are of any axes type so
        % that an appropriate error message can be displayed to the user.
        err = MException(message('MATLAB:graphics:chart:DoubleHandleParentNotSupported'));
        throwAsCaller(err)
    end
end

end
