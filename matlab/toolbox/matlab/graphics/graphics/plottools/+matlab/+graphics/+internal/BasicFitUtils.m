classdef BasicFitUtils

    %   Copyright 2024 The MathWorks, Inc.

    methods (Static)
        function eqntxtH = bfitcreateeqntxt(digits,axesh,dataH,fitsshowing)
            % BFITCREATEEQNTXT Create text equations for Basic Fitting GUI.

            %   Copyright 1984-2011 The MathWorks, Inc.

            eqntxtH = [];
            coeffcell = getappdata(double(dataH),'Basic_Fit_Coeff');
            guistate = getappdata(double(dataH),'Basic_Fit_Gui_State');
            resultsState = getappdata(dataH,'Basic_Fit_Results_State');
            normalized = guistate.normalize;

            % If normalized, we will use "z" instead of "x" in the equation text except
            % if the only fits showing are the interpolants.
            if ~any(fitsshowing>2)
                normalized = false;
            end

            n = length(fitsshowing);
            if normalized
                eqns = cell(n+2,1);
            else
                eqns = cell(n+1,1);
            end
            eqns{1,:} = ' ';
            for i = 1:n
                % get fit type
                currentInd = fitsshowing(i);
                fittype = currentInd - 1;
                % add string to matrix
                eqns{i+1,:} = eqntxtstring(dataH,fittype,coeffcell{currentInd},digits,axesh,normalized,resultsState);
            end
            if normalized  && any(cellfun(@(str) ~isempty(str) && ischar(str) && strlength(deblank(str))>0, eqns))
                normalizers = getappdata(double(dataH),'Basic_Fit_Normalizers');
                format = ['where z = (x - %0.', num2str(digits), 'g)/%0.', num2str(digits), 'g'];
                eqns{n+2,:} = sprintf(format, normalizers);
            end
            if ~isempty(eqns) && n > 0
                eqntxtH = text(.05, .95, eqns,'parent',axesh, ...
                    'tag', 'equations', ...
                    'verticalalignment','top', ...);
                    'units', 'normalized');
                %handle code generation for this text object in bfitMCodeConstructor.m
                b = hggetbehavior(eqntxtH,'MCodeGeneration');
                set(b, 'MCodeIgnoreHandleFcn', 'true');
            end
        end

        function legendH = createaxislegend(axesH, datahandles,legH, bfitlistenFcn, bfitlistenonFcn, bfitlistenoffFcn, createdatalegendFcn)

            allH = []; allM = [];

            % get legend info
            if isempty(legH)
                l = legend('-find',handle(axesH));
            else
                l = legH;
            end
            legh=[];
            oldhandles=[];
            oldstrings=[];
            if ~isempty(l)
                legh=l;
                % Using _I properties to avoid triggering an update traversal here
                % since BasicFitting is doing a version of legend AutoUpdate.
                oldhandles = l.PlotChildren_I(ishghandle(l.PlotChildren_I));
                % Don't call l.String_I since it infers the value from l.Entries which
                % may be empty if l.PlotChildren has been set, but the
                % update has not happened since get.String_I uses
                % l.Entries. Instead look at the display names. This should
                % always be accurate since setting l.String will fan out to
                % the object DisplayNames and this is what will always be
                % returned from l.String_I after after the update
                oldstrings = get(oldhandles,{'DisplayName'});
            end
            if ~isempty(legh)
                % for each handle in legend put in legend entry
                % If it's a datahandle, create a legend for it.
                bfit = zeros(length(oldhandles),1);
                for i=1:length(oldhandles)
                    if ishghandle(oldhandles(i)) % could be a deleted handle
                        appdata = getappdata(double(oldhandles(i)),'bfit');
                        bfit(i) = ~isempty(appdata);
                        if bfit(i)
                            % if datahandle, then create legend for it.
                            % otherwise, it was created by basic fit, so ignore:
                            % it will get recreated with it's datahandle legend.
                            if ~isempty(datahandles) && any(oldhandles(i) == datahandles)
                                [tmpH, tmpM] = feval(createdatalegendFcn,oldhandles(i));
                                allH = [allH, tmpH]; %#ok<AGROW>
                                allM = strvcat(allM,tmpM);
                            end
                        else % not bfit
                            allH = [allH, oldhandles(i)];
                            allM = strvcat(allM,oldstrings{i});
                        end
                    end
                end
            end

            % Check for any data not in a legend
            for i=1:length(datahandles)
                if isempty(oldhandles) || all(oldhandles ~= datahandles(i))
                    [tmpH, tmpM] = feval(createdatalegendFcn,datahandles(i));
                    allH = [allH, tmpH]; %#ok<AGROW>
                    allM = strvcat(allM,tmpM);
                end
            end
            if length(oldstrings) > length(oldhandles)
                allM = strvcat(allM, oldstrings{(length(oldhandles)+1):end});
            end

            if ~isempty(allH)
                fig = ancestor(axesH,'figure');
                if isempty(legh)
                    feval(bfitlistenoffFcn,fig);
                    legh = legend(axesH, allH, allM);
                    feval(bfitlistenonFcn,fig);
                    feval(bfitlistenFcn,legh);
                else
                    feval(bfitlistenoffFcn,fig);
                    % Avoid transposing legh children which triggers a doUpdate and temprarilty
                    % sets the legh String_I property to [] causing later calls to this method
                    % to error when trying to access legh.String_I and getting this empty state (g3355148)
                    %leg.PlotChildren=l(1:2);leg.String={'aa','bb'};leg.String_I
                    legh.PlotChildren = allH(:);
                    legh.PlotChildrenSpecified = allH(:);

                    if ~iscell(allM)
                        allM = cellstr(allM);
                    end
                    legh.String_I = allM;
                    drawnow;
                    feval(bfitlistenonFcn,fig);
                end
                legendH = legh;
            else
                legend(axesH,'off');
                legendH = [];
            end
        end


        function r2 = computeR2Value(datahandle,fitnum,normalized,pp)

            % This function compute r2 value for a particular fit given if it is
            % normalized. For spline and shape-preserving, we do not display numeric
            % results.
            % Copyright 2019-2021 The MathWorks, Inc.

            ydata = double(get(datahandle,'YData'));
            xdata = double(get(datahandle,'XData'));

            if normalized
                normalized = getappdata(datahandle,'Basic_Fit_Normalizers');
                meanx = normalized(1);
                stdx = normalized(2);
                xdata  = (xdata - meanx)./(stdx);
            end

            % for spline and shape-preserving
            if fitnum < 2
                y_fit = ppval(pp,xdata);
            else
                % rest of the fits
                y_fit = polyval(pp,xdata);
            end
            % Account for the case where user has small ydata
            if isscalar(ydata)
                r2 = 1;
            else
                r = corrcoef(ydata,y_fit);
                r2 = r(1,2).^2;
            end


        end
    end
end

function s = eqntxtstring(dataH,fitnum,pp,digits,axesh,normalized,resultsState)

op = '+-';
if normalized
    format1 = ['%s %0.',num2str(digits),'g*z^{%s} %s'];
else
    format1 = ['%s %0.',num2str(digits),'g*x^{%s} %s'];
end
format2 = ['%s %0.',num2str(digits),'g'];
s = [];
xl = get(axesh,'xlim');
fitTypes = ['MATLAB:datamanager:basicfit:SplineFit',...
    message('MATLAB:datamanager:basicfit:ShapeFit'),...
    message('MATLAB:datamanager:basicfit:LinearFit'), ...
    message('MATLAB:datamanager:basicfit:QuadraticFit'), ...
    message('MATLAB:datamanager:basicfit:CubicFit'),...
    message('MATLAB:graph2d:bfit:DisplayNameNthDegree',4),...
    message('MATLAB:graph2d:bfit:DisplayNameNthDegree',5),...
    message('MATLAB:graph2d:bfit:DisplayNameNthDegree',6),...
    message('MATLAB:graph2d:bfit:DisplayNameNthDegree',7),...
    message('MATLAB:graph2d:bfit:DisplayNameNthDegree',8),...
    message('MATLAB:graph2d:bfit:DisplayNameNthDegree',9),...
    message('MATLAB:graph2d:bfit:DisplayNameNthDegree',10)];
if isequal(fitnum,0)
    s = getString(message('MATLAB:graph2d:bfit:CubicSplineInterpolant'));
elseif isequal(fitnum,1)
    s = getString(message('MATLAB:graph2d:bfit:ShapePreservingInterpolant'));
elseif resultsState.showEquations(fitnum+1)
    fit = fitnum - 1;
    s = sprintf('%s:  ',fitTypes(fitnum+1));
    s = [s sprintf('y =')];
    th = text(xl*[.95;.05],1,s,'parent',axesh, 'vis','off');
    if pp(1) < 0
        s = [s ' -'];
    end
    for i = 1:fit
        sl = length(s);
        if ~isequal(pp(i),0) % if exactly zero, skip it
            s = sprintf(format1,s,abs(pp(i)),num2str(fit+1-i), op((pp(i+1)<0)+1));
        end
        if (i==fit) && ~isequal(pp(i),0), s(end-5:end-2) = []; end % change x^1 to x.
        set(th,'string',s);
        et = get(th,'extent');
        if et(1)+et(3) > xl(2)
            s = [s(1:sl) sprintf('\n     ') s(sl+1:end)];
        end
    end
    if ~isequal(pp(fit+1),0)
        sl = length(s);
        s = sprintf(format2,s,abs(pp(fit+1)));
        set(th,'string',s);
        et = get(th,'extent');
        if et(1)+et(3) > xl(2)
            s = [s(1:sl) sprintf('\n     ') s(sl+1:end)];
        end
    end
    delete(th);
end

% delete last '+' if one is left hanging on the end
if ~isempty(s) && isequal(s(end),'+')
    s(end-1:end) = []; % there is always a space before the +.
end

% If the equation is of the form y = "
if ~isempty(s) && isequal(s(end),'=')
    s = sprintf(format2,s,0);
end

if fitnum > 1 && resultsState.showR2(fitnum+1)
    if isempty(s)
        s = [s sprintf('%s: ',fitTypes(fitnum+1))];
    else
        s = [s sprintf('\n            ')];
    end
    r2String = sprintf("%0."+digits+"g",matlab.graphics.internal.BasicFitUtils.computeR2Value(dataH,fitnum,normalized,pp));
    s = [s sprintf('R^2 = %s',r2String)];
end

if fitnum > 1 && resultsState.showRMSE(fitnum+1)
    if isempty(s)
        s = [s sprintf('%s: ',fitTypes(fitnum+1))];
    else
        s = [s sprintf('\n            ')];
    end
    residuals = getappdata(double(dataH),'Basic_Fit_Resids');
    resid = residuals{fitnum+1};
    rmsString = sprintf("%0."+digits+"g",norm(resid(~isnan(resid))));
    s = [s sprintf([getString(message('MATLAB:datamanager:basicfit:NormOfResidualsLabel')), ' = %s'],rmsString)];
end

end
