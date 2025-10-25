function updatelims(h,varargin)
%UPDATELIMS  Builtin limit picker.
%
%   UPDATELIMS(H) implements the default limit management (LimitManager='builtin').
%   This limit manager
%     1) Finds common auto limits for axes in auto mode, in accordance
%        with the limit sharing settings defined by XLimSharing and
%        YLimSharing
%     2) Ensures axes in manual mode comply with the LimSharing settings.
%   Only visible axes are included in the auto limit computation.
%
%   UPDATELIMS(H,XLIMMODE,YLIMMODE) adjusts the limits for the limit mode
%   settings XLIMMODE and YLIMMODE.  Custom limit managers can use this option
%   to apply the default manager to only a subset of the axes group. Set
%   XLimMode='manual' or YLimMode='manual' to exclude particular axes from the
%   auto limit picking.

%   Author(s): P. Gahinet
%   Copyright 1986-2017 The MathWorks, Inc.

ni = nargin;
if isvisible(h)
    % No updating if global mode is manual or custom (unless called directly)
    ax = h.Axes2d;
    [nr,nc] = size(ax);
    
    % Visible axes
    vis = reshape(strcmp(get(ax,'Visible'),'on'),[nr nc]);  % 1 for visible axes
    indrow = find(any(vis,2))';  % row with visible axes
    indcol = find(any(vis,1));   % columns with visible axes
    
    % Turn off backdoor listeners
    LimitMgrEnable = h.LimitManager;  % can be 'off' in call with 3 inputs
    h.LimitManager = 'off';
    
    % X and Y limit modes
    if ni==3 & ~isempty(varargin{1})
        XLimMode = varargin{1};
    else
        XLimMode = h.XLimMode;  % Use current settings
    end
    if ni==3 & ~isempty(varargin{2})
        YLimMode = varargin{2};
    else
        YLimMode = h.YLimMode;  % Use current settings
    end
    
    % Switch to auto mode for visible axes with XLimMode=auto
    xauto = strcmp(XLimMode,'auto');
    if length(xauto)==1
        xauto = repmat(xauto,[nr nc]);
    else
        xauto = repmat(xauto',[nr 1]);
    end
    set(ax(vis & xauto),'XlimMode','auto')
    
    % Switch to auto mode for visible axes with YLimMode=auto
    yauto = strcmp(YLimMode,'auto');
    if length(yauto)==1
        yauto = repmat(yauto,[nr nc]);
    else
        yauto = repmat(yauto,[1 nc]);
    end
    set(ax(vis & yauto),'YlimMode','auto')
    
    % equalizeLims is used to compute the min/max limits across an array of
    % axes (row/column, all or peer). The computed limits are then applied
    % to the axes. This avoids triggering an update traversal while
    % querying the limits of each individual axis.
    
    % Update X limits
    switch h.XLimSharing
        case 'column'
            xLimitsForColumns = cell(1,nc);
            % Compute shared limits
            for ct=indcol
                xLimitsForColumns{1,ct} = h.equalizeLims(ax(indrow,ct),'Xlim','XScale');
            end
            % Apply shared limits
            for ct = indcol
                arrayfun(@(k) set(ax(k,ct),'XLim',xLimitsForColumns{1,ct}),indrow);
            end
        case 'all'
            xLimitsForAll = h.equalizeLims(ax(vis),'Xlim','XScale');
            set(ax(vis),'XLim',xLimitsForAll);
        case 'peer'
            stride = h.Size(4);
            xLimitsForPeer = cell(1,stride);
            % Compute shared limits
            for ct=1:stride
                subax = ax(:,ct:stride:nc);
                subvis = vis(:,ct:stride:nc);
                xLimitsForPeer{ct} = h.equalizeLims(subax(subvis),'Xlim','XScale');
            end
            % Apply shared limits
            for ct = 1:stride
                subax = ax(:,ct:stride:nc);
                subvis = vis(:,ct:stride:nc);
                set(subax(subvis),'XLim',xLimitsForPeer{ct});
            end
    end
    
    % Update Y limits
    switch h.YLimSharing
        case 'row'
            yLimitsForRows = cell(nr,1);
            % Compute shared limits
            for ct=indrow
                yLimitsForRows{ct,1} = h.equalizeLims(ax(ct,indcol),'Ylim','YScale');
            end
            % Apply limits
            for ct = indrow
                arrayfun(@(k) set(ax(ct,k),'YLim',yLimitsForRows{ct,1}),indcol);
            end
        case 'all'
            yLimitsForAll = h.equalizeLims(ax(vis),'Ylim','YScale');
            set(ax(vis),'YLim',yLimitsForAll);
        case 'peer'
            stride = h.Size(3);
            yLimitsForPeer = cell(stride,1);
            % Compute shared limits
            for ct=1:stride
                subax = ax(ct:stride:nr,:);
                subvis = vis(ct:stride:nr,:);
                yLimitsForPeer{ct} = h.equalizeLims(subax(subvis),'Ylim','YScale');
            end
            % Apply shared limits
            for ct = 1:stride
                subax = ax(ct:stride:nr,:);
                subvis = vis(ct:stride:nr,:);
                set(subax(subvis),'YLim',yLimitsForPeer{ct});
            end
    end
    % Turn backdoor listeners back on
    h.LimitManager = LimitMgrEnable;
end
