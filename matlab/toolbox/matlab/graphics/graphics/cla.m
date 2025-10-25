function ret_target = cla(varargin)
%CLA Clear current axes.
%   CLA deletes all children of the current axes with visible handles and resets
%   the current axes ColorOrder and LineStyleOrder.
%
%   CLA RESET deletes all objects (including ones with hidden handles)
%   and also resets all axes properties, except Position and Units, to
%   their default values.
%
%   CLA(AX) or CLA(AX,'reset') clears all axes in the handle or vector of handles AX.
%
%   See also CLF, RESET, HOLD.

%   CLA(..., HSAVE) deletes all children except those specified in
%   HSAVE.

%   Copyright 1984-2024 The MathWorks, Inc.

% Check for an Axes handle.
% 'isgraphics' will catch numeric graphics handles, but will not catch
% deleted graphics handles, so we need to check for both separately.

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

if nargin > 0 && (~isempty(varargin{1}) || isa(varargin{1},'matlab.graphics.axis.AbstractAxes')) ...
        && all(isgraphics(varargin{1},'matlab.graphics.axis.AbstractAxes'),'all')
    % Accept an array of axes of any size (including empty) as the target
    % axes to clear. ~empty is required to support double-handles to axes
    % and isa is required to prevent accepting an empty array of non-axes
    % as a target.
    ax = handle(varargin{1});
    extra = varargin(2:end);
elseif nargin > 0 && isa(varargin{1},'matlab.graphics.axis.AbstractAxes')
    % First input contains handles to deleted graphics objects.
    error(message('MATLAB:cla:InvalidAxesHandle'));
else
    % Default target is current axes
    target = gca;
    % Chart subclass support
    % Invoke cla method on Chart if cla is overloaded and public, else throw
    % unsupported error message
    if isa(target,'matlab.graphics.chart.Chart')
        claInfo = findobj(metaclass(target).MethodList, "Name", "cla");
        if ~isempty(claInfo) && any(claInfo.Access == "public")
            if nargout
                ret_target = target.cla(varargin{:});
            else
                target.cla(varargin{:});
            end
            return
        else
            error(message('MATLAB:Chart:UnsupportedConvenienceFunction', 'cla', target.Type));
        end
    end
    ax = target;
    extra = varargin;
end

% Input must either be all axes (to clear) or all non-axes (to preserve)
n = numel(extra);
if n
    if ~matlab.graphics.internal.isCharOrString(extra{1})
        extra{1} = verifyNotAxesAndNonAxesMixedInput(extra{1});
    end
    if n > 1 && ~matlab.graphics.internal.isCharOrString(extra{2})
        extra{2} = verifyNotAxesAndNonAxesMixedInput(extra{2});
    end
end


for i = 1:numel(ax)
    % Call claNotify to trigger cla related events.
    claNotify(ax(i),extra{:});

    % Call clo on the axes
    clo(ax(i), extra{:});
end

% Return the axes handle if requested
if (nargout ~= 0)
    ret_target = ax;
end
end

function hsave = verifyNotAxesAndNonAxesMixedInput(hsave)
areAxes = isgraphics(hsave,'matlab.graphics.axis.AbstractAxes');
if any(areAxes) && ~all(areAxes)
    throwAsCaller(MException(message('MATLAB:cla:InvalidAxesHandle')));
end
if ~isempty(hsave) && isnumeric(hsave)
    % Convert double handles for clo hsave.
    hsave = handle(hsave);
end
end
