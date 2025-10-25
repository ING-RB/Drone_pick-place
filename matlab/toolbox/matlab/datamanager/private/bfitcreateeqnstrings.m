function s = bfitcreateeqnstrings(datahandle,fit,pp,resid)
% BFITCREATEEQNSTRINGS Create result strings Basic Fitting GUI.

%   Copyright 1984-2020 The MathWorks, Inc.
sObj = settings;
if sObj.matlab.graphics.showlegacybasicfitapp.ActiveValue
    s = generateEquationForOldJavaApp(datahandle,fit,pp,resid);
else
    guistate = getappdata(datahandle,'Basic_Fit_Gui_State');
    formatStr = "%0."+num2str(guistate.digits)+"g";
    if isequal(guistate.normalize,true)
        normalizedState = true;
        normalized = getappdata(datahandle,'Basic_Fit_Normalizers');
        
        switch fit
            case {0,1}
                normstring = getString(message('MATLAB:graph2d:bfit:MsgCenteredAndScaledVariable', ...
                    sprintf(formatStr,normalized(1)),sprintf(formatStr,normalized(2))));
            otherwise
                normstring = sprintf(", z = (x-%s)/%s",sprintf(formatStr,normalized(1)),sprintf(formatStr,normalized(2)));
        end
    else
        normstring = '';
        normalizedState = false;
    end
    
    switch fit
        case {0,1}
            s = getString(message('MATLAB:graph2d:bfit:MsgNormOfResidualsEqual0',metricResultsText(fit,normalizedState,pp,formatStr),normstring));
        otherwise
            s = sprintf("%s%s",metricResultsText(fit,normalizedState,pp,formatStr),normstring);
            equation = getappdata(datahandle,'Basic_Fit_Equation');
            equation{fit+1} = sprintf('%s%s',eqnstring(fit, normalizedState),normstring);
            % coefficients
            coeff = '';
            for i=1:length(pp)
                coeff = [coeff sprintf('p%g = %s\n',i,num2str(pp(i)))]; %#ok<AGROW>
            end
            coefficients = getappdata(datahandle,'Basic_Fit_Coefficients');
            coefficients{fit+1} = coeff;
            
            % create r2 string
            r2 = computeR2Value(datahandle,fit,guistate.normalize,pp);
            r2Val = getappdata(datahandle,'Basic_Fit_R2');
            r2Val{fit+1} = num2str(r2);
            s(end+1) = sprintf(formatStr,r2);
            
            % create residuals string
            rmse = getappdata(datahandle,'Basic_Fit_RMSE');
            rmse{fit+1} = num2str(resid);
            s(end+1) = string(formatPolynomial(resid,formatStr));
            setappdata(datahandle,'Basic_Fit_Equation', equation);
            setappdata(datahandle,'Basic_Fit_Coefficients', coefficients);
            setappdata(datahandle,'Basic_Fit_R2', r2Val);
            setappdata(datahandle,'Basic_Fit_RMSE', rmse);
    end
end

function s = generateEquationForOldJavaApp(datahandle,fit,pp,resid)
guistate = getappdata(double(datahandle),'Basic_Fit_Gui_State');
if isequal(guistate.normalize,true)
	normalizedState = true;
	normalized = getappdata(double(datahandle),'Basic_Fit_Normalizers');
    switch fit
        case {0,1}
            normstring = getString(message('MATLAB:graph2d:bfit:MsgCenteredAndScaledVariable', ...
                sprintf('%0.5g',normalized(1)), sprintf('%0.5g',normalized(2))));
        otherwise
            normstring = getString(message('MATLAB:graph2d:bfit:MsgZIsCenteredAndScaled', ...
                sprintf('%0.5g',normalized(1)), sprintf('%0.5g',normalized(2))));
    end
else
    normstring = '';
    normalizedState = false;
end

switch fit
case {0,1}
    s = getString(message('MATLAB:graph2d:bfit:MsgNormOfResidualsEqual0', eqnstring(fit, normalizedState), normstring));
otherwise
    s = sprintf('%s%s',eqnstring(fit, normalizedState),normstring);
   
    s = getString(message('MATLAB:graph2d:bfit:MsgCoefficients',s));
    for i=1:length(pp)
    	s=[s sprintf('  p%g = %0.5g\n',i,pp(i))];
    end
    
    s = sprintf(getString(message('MATLAB:graph2d:bfit:MsgNormOfResiduals',s)));
    s = [s '     ' num2str(resid,5) sprintf(newline)];

end

function metricResult = metricResultsText(fitnum, normalizedState, polynomials, formatStr)

if isequal(fitnum,0)
    metricResult = getString(message('MATLAB:graph2d:bfit:DisplaySplineInterpolant'));
elseif isequal(fitnum,1)
    metricResult = getString(message('MATLAB:graph2d:bfit:DisplayShapePreservingInterpolant'));
else
    if normalizedState
        xz = "z";
    else
        xz = "x";
    end
    fit = fitnum - 1;
    metricResult = sprintf("y =");
    for i = 1:fit
        if ~isequal(polynomials(i),0)
            formattedPolynomial = formatPolynomial(polynomials(i),formatStr);
            if formattedPolynomial.startsWith("-") && metricResult.endsWith("+")
                metricResult = extractBefore(char(metricResult),length(char(metricResult)));
            end
            
            if i == fit
                metricResult = sprintf("%s %s%s +",metricResult,formattedPolynomial,xz);
            else
                metricResult = sprintf("%s %s%s^{%s} +",metricResult,formattedPolynomial,xz,num2str(fit+1-i));
            end
            if isequal(mod(i,2),0)
                metricResult = sprintf("%s",metricResult);
            end
        end
    end
    
    formattedPolynomial = formatPolynomial(polynomials(end),formatStr);
    if formattedPolynomial.startsWith("-") && metricResult.endsWith("+")
        metricResult = extractBefore(char(metricResult),length(char(metricResult)));
    end
    
    % If the equation is of the form y = "
    if length(char(metricResult)) == 3
        metricResult = sprintf("%s %d",metricResult,0);
    else
        metricResult = sprintf("%s %s",metricResult,formatPolynomial(polynomials(end),formatStr));
    end
end

%-------------------------------

function s = eqnstring(fitnum, normalizedState)

if isequal(fitnum,0)
    s = getString(message('MATLAB:graph2d:bfit:DisplaySplineInterpolant'));
elseif isequal(fitnum,1)
    s = getString(message('MATLAB:graph2d:bfit:DisplayShapePreservingInterpolant'));
else
    if normalizedState
        xz = 'z';
    else
        xz = 'x';
    end
    fit = fitnum - 1;
    s = sprintf('y =');
    for i = 1:fit
        if i == fit
            s = sprintf('%s p%s*%s +',s,num2str(i), xz);
        else
            s = sprintf('%s p%s*%s^%s +',s,num2str(i),xz,num2str(fit+1-i));
        end
        if isequal(mod(i,2),0)
            s = sprintf('%s\n     ',s);
        end
    end
    s = sprintf('%s p%s ',s,num2str(fit+1));
end

function formattedStr = formatPolynomial(polynomial,formatStr)
formattedStr = sprintf(formatStr,polynomial);