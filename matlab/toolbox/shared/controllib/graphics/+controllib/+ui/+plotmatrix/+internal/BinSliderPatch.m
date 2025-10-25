classdef BinSliderPatch
    %% Bin slider patch for setting continuous group bins
    % This component is to be connected to
    % controllib.ui.plotmatrix.ContinuousGroupGC.m for group bin management.

%   Copyright 2016-2020 The MathWorks, Inc.
    
    % Inputs:
    % TC: controllib.plotmatrix.ui.PlotMatrixUITC
    % From the View object, get the TC by using the following:
    % TC = View.Axes.Parent.UserData.GroupEditor.getPeer
    
    % GV is the grouping variable whose bins are being edited.
    
     %% EXAMPLE
    % load carsmall;
    % cars = table(Horsepower,MPG,Acceleration,Model_Year,Weight,Cylinders,Origin);
    % h = controllib.ui.plotmatrix.internal.View.plotmatrix(cars,'XVariable','Horsepower','YVariable',{'Acceleration','MPG'},'GroupingVariable','Weight')
    % After the figure comes up, launch the Manage Groups dialog using Right
    % Click->Groups->Manage Groups ...
    % TC = h.Axes.Parent.UserData.GroupEditor.getPeer;
    % GV = 'Weight'
    % h = controllib.ui.plotmatrix.internal.BinSliderPatch(TC,GV)
    %%
    properties
        % Figure to parent the bin slider patch to
        % This is temporary. When the slider is added to 'ContinuousGroupsGC', this
        % figure is no longer needed
        Figure
    end
    
    methods
        function this = BinSliderPatch(TC,GV)
            this.Figure = figure(...
                'Visible',          'on', ...
                'MenuBar',          'none', ...
                'Name',             'Bin Slider Patch', ...
                'Tag',              sprintf('fig(%s)','tag'), ...
                'HandleVisibility', 'off', ...
                'Integerhandle',    'off', ...
                'NumberTitle',      'off', ...
                'HitTest',          'off', ...
                'Resize',           'on', ...
                'DockControls',     'on', ...
                'WindowStyle',      'normal', ...
                'Units',            'points');
            
            
            % Axes to parent the ui components to
            hAx(1) = axes(...
                'parent',   this.Figure, ...
                'Position', [0 0 1 1], ...
                'Visible',  'off', ...
                'HitTest',  'off', ...
                'XLim',     [0 1], ...
                'YLim',     [0 1], ...
                'XTick',    [], ...
                'YTick',    [],...
                'Units',    'normalized');
            
            % Pre-defined spacing
            w = 1;
            h = .01;
            
            % Number line for the slider - positioned from before the start of the axes
            % to after the end of the axes (assuming the x-limits of the axes are 0 to
            % 1)
            linePatch = patch(...
                'Parent',    hAx(1), ...
                'LineWidth', 1, ...
                'HitTest',   'on', ...
                'Vertices', [-.1 0.5-h; w+.1 0.5-h; w+.1 0.5+h; -.1 0.5+h], ...
                'Faces', [1 2 3 4]);
            
            set(linePatch(1),'FaceColor',get(this.Figure,'Color'));
            set(linePatch(1),'EdgeColor',get(this.Figure,'Color')*0.9);
            
            % Get the group bins from the TC
            [~,GroupData] = getGroupData(TC, GV);
            GroupBins = cell2mat(GroupData(:,2));
            GroupLabels = GroupData(:,1);
            nBins = size(GroupBins,1);
            
            % Pre-defined spacing for bin edges
            bw = .01;
            bh = h+.02;
            
            % Space between each bin edge - this places the bin edges equidistant from
            % one another
            binSpacing = (w-bw*(nBins-1))/nBins;
            
            for ct =1:nBins-1
                % Create patch object for each bin edge
                Vertices = [binSpacing*ct+(ct-1)*bw, .5-bh;
                    binSpacing*ct+ct*bw,     .5-bh;
                    binSpacing*ct+ct*bw,     .5+bh;
                    binSpacing*ct+(ct-1)*bw, .5+bh;];
                binPatch(ct) = patch(...
                    'Parent',    hAx(1), ...
                    'LineWidth', 1, ...
                    'HitTest',   'on', ...
                    'Vertices', Vertices, ...
                    'Faces', [1 2 3 4]);
                BinLabels(ct) = text((Vertices(1)+Vertices(3))/2,.45,...
                    mat2str(GroupBins(ct,1)), ...
                    'HorizontalAlignment','center', ...
                    'Parent', hAx(1));
                
                set(binPatch(ct),'FaceColor',get(this.Figure,'Color'));
                set(binPatch(ct),'EdgeColor',get(this.Figure,'Color')*.9);
                
                % These are not being used Right now - A good place to put this would
                % be between the bin edges.
                GroupLabelsText(ct) = text(Vertices(1)-(binSpacing/2),0.55,...
                    GroupLabels{ct},'HorizontalAlignment','center');
                %     GroupLabelsText(ct).Parent = hAx(1);
            end
            
           
            % add the last label
            GroupLabelsText(end+1) = text(w-(binSpacing/2),0.55,GroupLabels{end},'HorizontalAlignment','center');
            % GroupLabelsText(end).Parent = hAx(1);
            
            InfLabels(1) = text(0.01,.45,'-Inf');
            InfLabels(1).Parent = hAx(1);
            
            InfLabels(2) = text(w-.03,.45,'Inf');
            InfLabels(2).Parent = hAx(1);
            
            % This logic needs to be revisited:
            
            % For the first bin ([-Inf to GroupBins(1,1), the factor needs to
            % logarithmically increase based on the drag
            
            % For bins 2-nBins-1, Factor needs to be GroupBins(ct-1)/((binPatch(ct).Vertices(1)+binPatch(ct).Vertices(3))/2)
            
            % For the last bin [GroupBins(nBins,1), Inf], the factor needs to
            % logarithmically increase based on the drag.
            
            for ct = 1:nBins-1
                Factor = GroupBins(ct,1)/((binPatch(ct).Vertices(1)+binPatch(ct).Vertices(3))/2);
                
                set(binPatch(ct),'ButtonDownFcn', @(es,ed) dragBin(es,ed,'Start',es,BinLabels(ct),Factor,[GroupLabelsText(ct);GroupLabelsText(ct+1)],binSpacing));
            end
        end
    end
end
function dragBin(es,ed,Mode,BinPatch,BinLabel,Factor,GL,binSpacing)
persistent xoffset1 xoffset2
switch Mode
    case 'Start'
        xoffset1 = BinPatch.Vertices(1,1)-ed.IntersectionPoint(1);
        xoffset2 = BinPatch.Vertices(2,1)-ed.IntersectionPoint(1);
        set(es.Parent.Parent,'WindowButtonMotionFcn', @(es,ed) dragBin(es,ed,'Move',BinPatch,BinLabel,Factor,GL,binSpacing));
        set(es.Parent.Parent,'WindowButtonUpFcn', @(es,ed) dragBin(es,ed,'Stop',BinPatch,BinLabel,Factor,GL,binSpacing));
    case 'Move'
        CP = get(BinPatch.Parent,'CurrentPoint');
        BinPatch.Vertices = [CP(1,1)+xoffset1, BinPatch.Vertices(1,2);
            CP(1,1)+xoffset2, BinPatch.Vertices(2,2);
            CP(1,1)+xoffset2, BinPatch.Vertices(3,2);
            CP(1,1)+xoffset1, BinPatch.Vertices(4,2);];
        BinValue = (BinPatch.Vertices(1)+BinPatch.Vertices(3))/2*Factor;
        BinLabel.Text.String = sprintf('%0.03g',BinValue);
        BinLabel.Position(1) = (BinPatch.Vertices(1)+BinPatch.Vertices(3))/2;
    case 'Stop'
        %         GL(1).Position(1) = BinPatch.Vertices(1)-(binSpacing/2);
        %         GL(2).Position(1) = BinPatch.Vertices(3)+(binSpacing/2);
        % This callback needs to update TC based on new bin values
        set(es,'WindowButtonMotionFcn', []);
        set(es,'WindowButtonUpFcn', []);
end
end
