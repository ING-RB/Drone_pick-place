function varargout = commonplotfunc(action,fname,inputnames,inputvals)
%PLOTPICKERFUNC  Support function for Plot Picker component.

% Copyright 2009-2018 The MathWorks, Inc.

% Default display functions for shared toolbox plots
if strcmp(action,'defaultshow')
    n = length(inputvals);
    toshow = false;
    % A single empty should always return false
    if isempty(inputvals) ||  isempty(inputvals{1})
        varargout{1} = false;
        return
    end
    switch lower(fname)
        case {'sfitsurface','sfitpredfunc','sfitpredobs','sfitcontour'}
            if n==1 
                toshow = isa(inputvals{1},'sfit');
            elseif n==3
                xy = inputvals{2};
                z = inputvals{3};
                toshow = isa(inputvals{1},'sfit') && isfloat(xy) && ismatrix(xy) &&...
                    size(xy,2)==2 &&  isfloat(z) && isvector(z) && ...
                    size(z,2)==1 && length(z)==size(xy,1);
            end  
        case {'sfitresiduals'}
            if n==3
                xy = inputvals{2};
                z = inputvals{3};
                toshow = isa(inputvals{1},'sfit') && isfloat(xy) && ismatrix(xy) &&...
                    size(xy,2)==2 &&  isfloat(z) && isvector(z) && ...
                    size(z,2)==1 && length(z)==size(xy,1);
            end 
        case {'cfitfit','cfitpredfunc','cfitpredobs','cfitderiv1','cfitderiv2','cfitintegral'}
            if n==1 
                toshow = isa(inputvals{1},'cfit');
            elseif n==3 || n==4
                xdata = inputvals{2};
                ydata = inputvals{3};
                toshow = isa(inputvals{1},'cfit') && isfloat(xdata) && isvector(xdata) && ...
                    isfloat(ydata) && isvector(ydata) && ...
                    length(xdata) == length(ydata);
            end
            if n==4 && toshow
                if isscalar(inputvals{4})
                    level = inputvals{4};
                    toshow = level>=0 && level<=1;
                else
                    outliers = inputvals{4};
                    toshow =  islogical(outliers) && isvector(outliers) && ...
                        length(outliers) == length(ydata);
                end
            end
        case {'cfitresiduals','cfitstresiduals'}
            if n==3 || n==4
                xdata = inputvals{2};
                ydata = inputvals{3};
                toshow = isa(inputvals{1},'cfit') && isfloat(xdata) && isvector(xdata) && ...
                    isfloat(ydata) && isvector(ydata) && ...
                    length(xdata) == length(ydata);
            end
            if n==4 && toshow
                if isscalar(inputvals{4})
                    level = inputvals{4};
                    toshow = level>=0 && level<=1;
                else
                    outliers = inputvals{4};
                    toshow =  islogical(outliers) && isvector(outliers) && ...
                        length(outliers) == length(ydata);
                end
            end
        case 'cftool'
            if n==2 || n==3 
                x = inputvals{1};
                y = inputvals{2};
                toshow = isfloat(x) && isvector(x) && ...
                    isfloat(y) && isvector(y) && ...
                    length(x) == length(y);
                if n==3
                    w = inputvals{3};
                    toshow = toshow && isvector(w) && isfloat(w) && length(x) == length(w);
                end
            end  
         case 'sftool'
            if n==3 || n==4 
                x = inputvals{1};
                y = inputvals{2};
                z = inputvals{3};
                toshow = isfloat(x) && isvector(x) && ...
                    isfloat(y) && isvector(y) && ...
                    isfloat(z) && isvector(z) && ...
                    length(x) == length(y) && ...
                    length(x) == length(z);
                if n==4
                    w = inputvals{4};
                    toshow = toshow && isvector(w) && isfloat(w) && length(x) == length(w);
                end
            end  
    end
    varargout{1} = toshow;
elseif strcmp(action,'defaultdisplay')
    dispStr = '';
    switch lower(fname)
        case 'sfitsurface'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''style'',''Surface'');'];
        case 'sfitpredfunc' 
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''style'',''PredFunc'');'];
        case 'sfitpredobs'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''style'',''PredObs'');'];
        case 'sfitresiduals' 
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''style'',''Residuals'');'];
        case 'sfitcontour' 
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''style'',''Contour'');'];
        case 'cfitfit' 
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''fit'');'];
        case 'cfitpredfunc' 
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''predfunc'');'];
        case 'cfitpredobs' 
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''predobs'');'];
        case 'cfitresiduals' 
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''residuals'');'];
        case 'cfitstresiduals' 
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''stresiduals'');'];
        case 'cfitderiv1' 
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''deriv1'');'];
        case 'cfitderiv2' 
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''deriv2'');'];
        case 'cfitintegral' 
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))]; 
            dispStr = ['plot(' inputNameArray{:} '''integral'');'];
        case 'cftool' 
            inputNameArray = [inputnames(1:end-1);repmat({','},1,length(inputnames)-1)]; 
            dispStr = ['cftool(' inputNameArray{:} inputnames{end} ');'];
         case 'sftool' 
            inputNameArray = [inputnames(1:end-1);repmat({','},1,length(inputnames)-1)]; 
            dispStr = ['sftool(' inputNameArray{:} inputnames{end} ');'];
    end
    varargout{1} = dispStr;
elseif strcmp(action,'defaultlabel')
    lblStr = '';
    switch lower(fname)
        case 'sfitsurface'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''style'',''Surface'')'];
        case 'sfitpredfunc'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''style'',''PredFunc'')'];
        case 'sfitpredobs'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''style'',''PredObs'')'];
        case 'sfitresiduals'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''style'',''Residuals'')'];
        case 'sfitcontour'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''style'',''Contour'')'];
        case 'cfitfit'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''fit'')'];  
        case 'cfitpredfunc'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''predfunc'')'];
        case 'cfitpredobs'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''predobs'')'];
        case 'cfitresiduals'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''residuals'')'];
        case 'cfitstresiduals'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''stresiduals'')'];
        case 'cfitderiv1'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''deriv1'')'];
        case 'cfitderiv2'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''deriv2'')'];
        case 'cfitintegral'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];            
            lblStr = ['plot(' inputNameArray{:} '''integral'')'];
    end

    varargout{1} = lblStr;
end
end