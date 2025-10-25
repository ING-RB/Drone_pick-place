classdef TSDFUtils < nav.algs.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%TSDFUtils contains visualization and validation helpers for meshtsdf and
%signedDistanceMap3D

%#codegen
    methods (Static)
        function validateTruncationDistance(minEdgeLength,truncDist)
            arguments
                minEdgeLength (1,1) {mustBePositive} %#ok<INUSA>
                truncDist (1,1) {mustBeNumeric, mustBeGreaterThanOrEqual(truncDist,minEdgeLength)} %#ok<INUSA>
            end
        end
        function [h,hBar] = showImpl(obj,voxStruct,nv)
        %showImpl Visualization method common to meshtsdf and signedDistanceMap3D

            % Compute dist limits
            n = numel(voxStruct);
            [dMax,isoRange] = obj.depthInfo(voxStruct,nv.IsoRange);

            % Prep axes and graphic handles
            [ax,cmapAx] = nav.geometry.internal.TSDFUtils.getAx(class(obj),nv.Parent,nv.FastUpdate);
            delete(obj.ThemeListener);
            delete(obj.ScatterHandle(n+1:end));
            obj.ScatterHandle(n+1:end) = [];
            if ~isempty(obj.ScatterHandle)
                hValid = isvalid(obj.ScatterHandle);
            else
                hValid = [];
            end
            nValid = nnz(hValid);
            hTmp = gobjects(n,1);
            hTmp(1:nValid) = obj.ScatterHandle(hValid);

            % Create theme listeners
            fUpdate = @(src,prop,event)nav.geometry.internal.TSDFUtils.updateTSDFPlot(class(obj), ...
                ax,cmapAx,hTmp,voxStruct,dMax,isoRange,nv);
            
            % React to theme change after plotting
            f = ancestor(ax,'figure');
            obj.ThemeListener = addlistener(f,'Theme','PostSet',@(src,prop,event)fUpdate());

            % Display object
            [obj.ScatterHandle,cBar] = fUpdate();
            
            % Move original axes to the top and link
            axes(ax);
            obj.ColorbarLinks = linkprop([ax, cmapAx], ...
                                             {'Position','DataAspectRatioMode','DataAspectRatio', ...
                                              'PlotBoxAspectRatio','InnerPosition','OuterPosition'});

            if nargout > 0
                h = obj.ScatterHandle;
                hBar = cBar;
            end
        end
        function [ax,cmapAx] = getAx(type,parent,fastUpdate)
            % Retrieve ax handle
            if isa(parent,'matlab.graphics.GraphicsPlaceholder')
                ax = gca;
            else
                ax = parent;
            end
            if ~fastUpdate
                ax = newplot(ax);
            end

            % Create new colormap for second axes
            tag = [type '_ColorbarAxes'];
            cmapAx = findobj(ax.Parent,'Type','axes','Tag',tag);

            % To allow custom colormap/colorbar to update alongside
            % changes to the primary axes, we enforce a link
            % between the axes and store the reference.
            if isempty(cmapAx) || ~isvalid(cmapAx)
                cmapAx = axes(ax.Parent,'Tag',tag);
            end
            cmapAx.HitTest="off";
            cmapAx.Visible = 'off';
            view(ax,3);
            view(cmapAx,3);
        end

        function [ctrs,vals] = findValidVoxels(voxInfo,isoRange)
        %findValidVoxels Extract location and distance data in range
            if ~isempty(voxInfo)
                [voxCtrs,voxVals] = deal(voxInfo.Centers,voxInfo.Distances);
                m = voxVals >= isoRange(1) & voxVals <= isoRange(2);
                
                % Create theme-listener
                ctrs = voxCtrs(m,:);
                vals = voxVals(m,:);
            else
                ctrs = zeros(0,3);
                vals = [];
            end
        end

        function cmap = getColormap(cmapSign,nv)
        %getColormap Create or retrieve colormap
            arguments
                cmapSign (1,1) string {mustBeMember(cmapSign,{'Inside','Outside'})} = 'Inside';
                nv.Map = [];
            end
            
            if isempty(nv.Map)
                cOrder2hex = @(cOrderNum)nav.internal.SemanticColor.semanticColor2hex(...
                    nav.internal.SemanticColor.graphicColor(cOrderNum,1));
                switch cmapSign
                    case "Inside"
                        [~,negColor] = cOrder2hex(7);
                        cmap = linspace(1,0.5,124)'.*negColor;
                    otherwise
                        [~,posColor] = cOrder2hex(5);
                        cmap = linspace(0.5,1,124)'.*posColor;
                end
            else
                cmap = nv.Map;
            end
        end

        function [colors,idx] = colorizePoints(negMap,posMap,distLims,vals)
        %colorizePoints Compute colors for 
            mPos = vals > 0;
            mNeg = vals < 0;
            negBins = [-inf linspace(distLims(1),0,size(negMap,1))];
            posBins = [linspace(distLims(1),0,size(negMap,1)) inf];
            nNegBin = size(negMap,1);
            colors = zeros(size(vals,1),3);
            idx = zeros(size(vals,1),1);
            negIdx = discretize(vals(mNeg),negBins,"IncludedEdge","left");
            idx(vals < 0) = negIdx;
            posIdx = discretize(vals(mPos),posBins,"IncludedEdge","right");
            idx(vals > 0) = posIdx+1+nNegBin;
            colors(mNeg,:) = negMap(negIdx,:);
            colors(mPos,:) = posMap(posIdx,:);
        end
        
        function [hScatterSet,hBar] = updateTSDFPlot(type,ax,cmapAx,hScatterSet,voxStruct,dMax,isoRange,nv)
            holdState = ishold(ax);
            fClean = onCleanup(@()hold(ax,holdState));
            hold(ax,"on");

            % Update scatter plots
            n = numel(voxStruct);
            for i = 1:n
                voxSet = voxStruct(i);
                [ctrs,vals] = nav.geometry.internal.TSDFUtils.findValidVoxels(voxSet,isoRange);
                hScatterSet(i) = nav.geometry.internal.TSDFUtils.updateScatter(type,ax,hScatterSet(i),ctrs,vals,isoRange,nv);
            end

            % Create/update colorbar
            hBar = nav.geometry.internal.TSDFUtils.updateColorbar(type,cmapAx,dMax,isoRange,nv);
        end

        function hScatter = updateScatter(type,ax,hScatter,ctrs,vals,distLims,nv)
            % Create colormap
            negMap = nav.geometry.internal.TSDFUtils.getColormap("Inside");
            posMap = nav.geometry.internal.TSDFUtils.getColormap("Outside");
            
            % Convert voxel values to colors
            [colors,cIdx] = nav.geometry.internal.TSDFUtils.colorizePoints(negMap,posMap,distLims,vals);

            if nv.FastUpdate && ~isempty(hScatter) && isvalid(hScatter) && any(ancestor(hScatter,'axes')==ax)
                % Update existing scatter plot
                set(hScatter,XData=ctrs(:,1),YData=ctrs(:,2),ZData=ctrs(:,3),CData=colors);
            else
                % Create new scatter plot
                hScatter = scatter3(ax,ctrs(:,1),ctrs(:,2),ctrs(:,3),[],colors,'.','Tag',[type '_scatter']);
            end
        end

        function hBar = updateColorbar(type,cmapAx,td,distLims,nv)
            % Create colormap
            negMap = nav.geometry.internal.TSDFUtils.getColormap("Inside");
            posMap = nav.geometry.internal.TSDFUtils.getColormap("Outside");
            cmap = [negMap; zeros(1,3); posMap];

            % Update colorbar
            hBar = findobj(cmapAx.Parent,'Type','colorbar','Tag',[type '_Colorbar']);
            ticks = linspace(distLims(1),distLims(2),11);
            tickLabels = string(ticks);

            if ~isempty(hBar) && isvalid(hBar)
                set(hBar,Limits=distLims,Ticks=ticks,TickLabels=tickLabels,Colormap=cmap);
            else
                hBar = colorbar(cmapAx,Limits=distLims,Ticks=ticks,TickLabels=tickLabels,...
                    Tag=[type '_Colorbar'],Colormap=cmap);
            end
            cmapAx.CLim = [-td td];
            hBar.Visible = nv.Colorbar;
        end
    end
end