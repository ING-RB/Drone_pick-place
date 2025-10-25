function varargout = plotpickerfunc(action,fname,inputnames,inputvals)
%PLOTPICKERFUNC  Support function for Plot Picker component.

% Copyright 2009-2024 The MathWorks, Inc.
import matlab.graphics.chart.primitive.internal.findMatchingDimensions
% Default display functions for MATLAB plots
if strcmp(action,'defaultshow')
    n = length(inputvals);
    toshow = false;
    % A single empty should always return false
    if isempty(inputvals) ||  isempty(inputvals{1})
        varargout{1} = false;
        return
    end
    switch lower(fname)
        % A single matrix or a vector and matrix of compatible size.
        % Either choice with an optional scalar bar width
        case {'bar','barh','bar3','bar3h'} 
            x = inputvals{1};
            if n==1                
                toshow = (isnumeric(x) || islogical(x)) && ~isscalar(x) && ...
                    isBasicMatrix(x) && (isBasicVector(x) || isreal(x));
                toshow = toshow || (isduration(x) && ~isscalar(x) && ismatrix(x));
                
            elseif n==2 || n==3
                toshow = localBarNonNumArgFcn(inputvals);
                if strcmp(fname, 'bar3') || strcmp(fname, 'bar3h')
                    toshow = toshow && isvector(x); 
                end

                % Check for unique bins if time performance allows 
                if toshow && isBasicVector(x) && length(x)<=1000
                    toshow = min(diff(sort(x(:))))>0;
                end
                if toshow && n==3
                    p = inputvals{3};
                    toshow = isnumeric(p) && isscalar(p);
                end
            elseif n>3
                toshow = false;
            end
        case {'barstacked','barhstacked'} 
            % A single matrix or a vector and matrix of compatible size.
            % Either choice with an optional scalar bar width
            x = inputvals{1};
            if n==1                
                toshow = (isnumeric(x) || islogical(x)) && ~isscalar(x) && ...
                    isBasicMatrix(x) && ~isBasicVector(x);
            elseif n==2 || n==3
                toshow = localAreaArgFcn(inputvals);
                if isBasicVector(inputvals{2}) % Stacked should not show for single bar plots
                    toshow = false;
                end
                % Check for unique bins if time performance allows 
                if toshow && isBasicVector(x) && length(x)<=1000
                    toshow = min(diff(sort(x(:))))>0;
                end
                if toshow && n==3
                    p = inputvals(3);
                    toshow = isnumeric(p) && isscalar(p);
                end
            elseif n>3
                toshow = false;
            end
        % A matrix/vector or 2 vectors/matrices of compatible size with an
        % optional linespec
        case 'plot'
            if n==1
                x = inputvals{1};
                if isnumeric(x) || islogical(x)
                     toshow =  ~isscalar(x) && ndims(x)<=2;
                elseif isa(x,'timeseries')
                     toshow =  x.TimeInfo.Length>1;
                elseif isa(x,'fints') || isdatetime(x) || isduration(x) ||...
                        iscategorical(x)
                     toshow = true;
                elseif isa(x, 'Simulink.SimulationData.Dataset')
                    % For Simulink Dataset, we enable plotting of the object if
                    % it is non-empty
                     toshow = x.numElements() > 0;
                elseif isa(x, 'Simulink.SimulationOutput')
                    % For SimulationOutput, we enable plotting if the object is
                    % non-empty
                     toshow = numel(x.who()) > 0;
                end
            elseif n==2
                toshow = localPlotArgFcn(inputvals);  
            elseif n==3
                toshow = localPlotArgFcn(inputvals(1:2));
                toshow = toshow && (ischar(inputvals{3}) || isstring(inputvals{3}));
            elseif n>3
                toshow = false;
            end
         case 'graph'
            if n==1
                x = inputvals{1};
                toshow = isa(x,'graph');
            else
                toshow = false;
            end
         case 'digraph'
            if n==1
                x = inputvals{1};
                toshow = isa(x,'digraph');
            elseif n>1
                toshow = false;
            end
        case 'plot_multiseriesfirst'
            if n>=3
               x = inputvals{1};
               toshow = (isnumeric(x) || isdatetime(x) || isduration(x)) && ~isscalar(x);
                   % cases : d,x1,...xn; x,d1,...,dn; d1,d2,...dn;
                   % case 1: if x = datetime/duration, then xn's should not be
                   % duration/datetime
                   % case 2: if x = numeric, then xn's should either be all
                   % datetime or all duration or all numerics
                   % case 1
                   if (isdatetime(x) || isduration(x))
                       % all the subsequent ones should either be
                       % datetime/duration or numeric
                       % if second is the same type as the first
                       if cellfun('isclass', inputvals(1:2), class(x))
                           % then all the subsequent ones should be same
                           % type
                           if ~all(cellfun('isclass',inputvals(2:end),class(inputvals{2})))
                               toshow = false;
                           end 
                       elseif isnumeric(inputvals{2})
                           % then all the subsequent ones should be numeric
                           if ~all(cellfun('isclass', inputvals(2:end), class(inputvals{2})))
                               toshow = false;
                           end
                       else
                           toshow = false;
                       end
                                               
                   % case 2
                    elseif ~(isduration(x) || isdatetime(x))
                        
                        % if the first one is numeric
                        if isnumeric(x)
                            % if second value is duration/datetime then all
                            % should be duration/datetime
                            if isduration(inputvals{2}) || isdatetime(inputvals{2})
                                if ~all(cellfun('isclass', inputvals(2:end), class(inputvals{2})))
                                    toshow = false;
                                end
                            % if second value is not datetime/duration then none of 
                            % them should be datetime/duration    
                            else
                                if any(cellfun('isclass', inputvals(2:end),'datetime')) || ... 
                                    any(cellfun('isclass', inputvals(2:end),'duration')) 
                                    toshow = false;
                                end
                            end
                        end
                   end
                 
                   % check the dimensions are the same
                   for k=2:length(inputvals) 
                        xn = inputvals{k};
                        if ~((isnumeric(xn) || islogical(xn) || isdatetime(xn) || isduration(xn)) && isvector(xn) && ...
                           length(xn)==length(x))
                           toshow = false;
                           break;
                        end
                   end
                   
            end
        % A matrix/vector or 2 vectors/matrices of compatible size with an
        % optional linespec
        case {'stem','stairs'}
            if n==1
                x = inputvals{1};
                toshow =  (isnumeric(x) || islogical(x)) && ~isscalar(x) && ...
                    ndims(x)<=2 && (isBasicVector(x) || isreal(x));
                toshow = toshow || ((isdatetime(x)  || isduration(x) || iscategorical(x))...
                    && ~isscalar(x) && ndims(x)<=2 && isvector(x));
            elseif n==2
                toshow = localAreaArgFcn(inputvals) || localAreaTimeArgFcn(inputvals);  
                toshow = toshow || localAreaCategoricalArgFcn(inputvals);
                toshow = toshow || (iscategorical(inputvals{1}) && iscategorical(inputvals{2})...
                    && isequal(size(inputvals{1}),size(inputvals{2})));
            elseif n==3
                toshow = localAreaArgFcn(inputvals(1:2)) || localAreaTimeArgFcn(inputvals(1:2));
                toshow = toshow && (ischar(inputvals{3}) || isstring(inputvals{3}));
            elseif n>3
                toshow = false;
            end
        case 'plot_multiseries'
            if n>=2
               x = inputvals{1};
               toshow = (isnumeric(x) || isdatetime(x) || isduration(x)) && ~isscalar(x) && isvector(x) && (~isobject(x) || isdatetime(x) || isduration(x));
               for k=2:length(inputvals)
                   xn = inputvals{k};
                   % datetime against duration and vice versa cannot be
                   % plotted
                   if ~((isnumeric(xn) || islogical(xn) || isdatetime(xn) || isduration(xn)) && isvector(xn) &&...
                       (~isobject(x) || isdatetime(x) || isduration(x)) && ...
                           length(xn)==length(x)) 
                       toshow = false;
                       break;
                   end                       
               end
               
               % 2 special cases : 
               % case 1 : show plot if all are datetimes or all are
               % durations
               % case 2 : show plot if there are alternating
               % datetimes/duration objects. These are plotted as pairs
               allTimeObjects = 0; 
               plotPairs = 0;
               
               if toshow && (any(cellfun('isclass',inputvals,'datetime')) || ... 
                   any(cellfun('isclass',inputvals,'duration')))
                   if isdatetime(inputvals{1}) || isduration(inputvals{1}) 
                        allTimeObjects = all(cellfun('isclass', inputvals, class(inputvals{1})));
                   end
                    if ~(allTimeObjects) && n > 2 && mod(length(inputvals),2) == 0
                        plotPairs = localPlotPairs(inputvals);
                    end
                    
                    if allTimeObjects == 0
                        if ~(plotPairs == 1) 
                            toshow = false;
                        end
                    end                 
                end
            end                       
        % A matrix/vector or 2 vectors/matrices of compatible size with an
        % optional base value
        case 'area'
            if n==1
                x = inputvals{1};
                toshow =  (isnumeric(x) || islogical(x)) && ~isscalar(x) && ...
                    ndims(x)<=2 && (isBasicVector(x) || isreal(x));
                toshow = toshow || (( isduration(x))...
                    && ~isscalar(x) && ndims(x)<=2 && isvector(x));                
            elseif n==2
                toshow = localAreaArgFcn(inputvals) || localAreaTimeArgFcn(inputvals);                  
                toshow = toshow || localAreaCategoricalArgFcn(inputvals);              
                toshow = toshow && ~(isdatetime(inputvals{1}) && isdatetime(inputvals{2}));
                toshow = toshow && ~(iscategorical(inputvals{1}) && iscategorical(inputvals{2}));
            elseif n==3
                toshow = localAreaArgFcn(inputvals(1:2)) || localAreaTimeArgFcn(inputvals(1:2));  
                toshow = toshow || localAreaCategoricalArgFcn(inputvals(1:2));  
                toshow = toshow && isnumeric(inputvals{3}) && isscalar(inputvals{3});
            elseif n>3
                toshow = false;
            end
        % A vector/matrix with optional cell array of labels or
        % explosion parameter
        case 'pie3' 
            if n==1
                x = inputvals{1};
                toshow = isnumeric(x) && ~isscalar(x) && isBasicMatrix(x) && isreal(x) && ...
                    isfloat(x);
            elseif n==2
                x = inputvals{1};
                y = inputvals{2};
                toshow = isnumeric(x) && ~isscalar(x) && isBasicMatrix(x) && isfloat(x);
                toshow = toshow && ((iscell(y) && isequal(size(y),size(x)) && ...
                    all(cellfun('isclass',y,'char'))) || (isnumeric(y) && isequal(size(y),size(x))));
            elseif n>2
                toshow = false;
            end
        case {'piechart','donutchart'}
            if n==1
                x = inputvals{1};
                toshow = ~isscalar(x) && isvector(x) && ((~isobject(x) && isnumeric(x) && isreal(x) && all(x>0)) || ...
                    islogical(x) || iscategorical(x) || isduration(x));
            elseif n==2
                x = inputvals{1};
                y = inputvals{2};
                toshow = ~isscalar(x) && isvector(x) && ((~isobject(x) && isnumeric(x) && isreal(x) && all(x>0)) || isduration(x));
                toshow = toshow && (isvector(y) && (iscellstr(y) || isstring(y)) && isequal(numel(y),numel(x)));
            elseif n>2
                toshow = false;
            end
        % An array with optional scalar or monotonic vector bin parameter
        case 'histogram' 
            if n==1
                x = inputvals{1};
                toshow = (isnumeric(x) && ~isscalar(x) && isreal(x)) || ...
                    islogical(x) && ~isscalar(x) || ...
                    iscategorical(x) || isdatetime(x) || isduration(x);
            elseif n==2
                x = inputvals{1};
                y = inputvals{2};                
                toshow = isnumeric(x) && ~isscalar(x) && isreal(x) && ...
                    isnumeric(y) && isreal(y);
                toshow = toshow && (isscalar(y) || ...
                        (isBasicVector(y) && issorted(y)));
                toshow = toshow || ((iscategorical(x)&& numel(x) == numel(unique(x)))...
                    && isvector(y) && ((iscategorical(y) && numel(y) == numel(unique(y)))...
                    || (iscell(y) && all(cellfun('isclass',y,'char')))));
                toshow = toshow || ((isdatetime(x) || isduration(x)) && ...
                    ((isscalar(y) && isnumeric(y) && isreal(y)) || ...
                    (isequal(class(x),class(y)) && isvector(y) && issorted(y))));
            elseif n>2
                toshow = false;
            end
        % Two equally sized matrices and a vector of max size 2  
        case 'histogram2'
            if n == 2 || n == 3
               x = inputvals{1};
               y = inputvals{2};
               toshow = isnumeric(x) && isnumeric(y) && isreal(x) && isreal(y) && isequal(size(x),size(y));             
              if n == 3
                  p = inputvals{3};
                  toshow = toshow && isnumeric(p) && isBasicVector(p) && (numel(p) == 1 || numel(p) == 2);
              end
            elseif n>3
                toshow = false;
            end
        % A matrix or 3 vectors/matrices of compatible size with an optional scalar/vector of
        % contour levels or linespec
        case {'contour','contourf','contour3'} 
            if n==1
                x = inputvals{1};
                %Exclude datetime and duration until supported
                toshow = isnumeric(x) && localIsMatrix(x);
            elseif n==2
                x = inputvals{1};
                v = inputvals{2};
                toshow = isnumeric(v) && localIsMatrix(x);
                if isscalar(v)
                    toshow = toshow && isscalar(v) && round(v)==v;
                elseif isBasicVector(v)
                    toshow = toshow && issorted(v);
                elseif ischar(v)
                    toshow = true;
                else
                    toshow = false;
                end              
            elseif n==3
                x = inputvals{1};
                y = inputvals{2};
                z = inputvals{3};
                
                % dateteime and duration not supported
                isDateInput = (isdatetime(x) || isduration(x) ||...
                    isdatetime(y) || isduration(y) ||...
                    isdatetime(z) || isduration(z));
                
                if ~isDateInput
                    if localIsMatrix(x)
                        toshow = localIsMatrix(y) && localIsMatrix(z) && ...
                            isequal(size(x),size(z)) && isequal(size(x),size(y));
                    elseif localIsVector(x)
                        toshow = localIsVector(y) && localIsMatrix(z) && ...
                            length(y)==size(z,1) && length(x)==size(z,2);
                    end
                end
                
            elseif n==4
                x = inputvals{1};
                y = inputvals{2};
                z = inputvals{3};
                v = inputvals{4};
                toshow = isscalar(v) && isnumeric(v) && round(v)==v; 
                
                % dateteime and duration not supported
                if (isdatetime(x) || isduration(x) ||...
                    isdatetime(y) || isduration(y) ||...
                    isdatetime(z) || isduration(z))
                    toshow = false;
                end 
                
                if toshow
                    if localIsMatrix(x) 
                        toshow = localIsMatrix(y) && localIsMatrix(z) && ...
                            isequal(size(x),size(z)) && isequal(size(x),size(y));
                    elseif localIsVector(x)
                        toshow = localIsVector(y) && localIsMatrix(z) && ...
                            length(y)==size(z,1) && length(x)==size(z,2);
                    end
                end                 
            elseif n>4
                toshow = false;
            end
        % 1 to 4 x,y,z, and color matrices of compatible size. x and y 
        % matrices may optionally replaced by compatible vectors.
        case {'surf','mesh','surfc','meshc','meshz','waterfall'}
            if n==1
                x = inputvals{1};
                toshow = isnumeric(x) && localIsMatrix(x);
                
                % datetime and duration only supported in surf and mesh
                if strcmp(fname, 'surf') || strcmp(fname, 'mesh')
                    toshow = toshow || (isdatetime(x) || isduration(x) || ...
                        iscategorical(x)) && ismatrix(x) && ~isvector(x);
                end
                
            elseif n==2
                x = inputvals{1};
                y = inputvals{2};
                toshow = isnumeric(x) && isnumeric(y) && isBasicMatrix(x)...
                    && min(size(x))>1 && isequal(size(x),size(y));
                % datetime and duration only supported in surf and mesh
                if strcmp(fname, 'surf') || strcmp(fname, 'mesh')
                    toshow = toshow || (isdatetime(x) || isduration(x) ||...
                        iscategorical(x))&& ismatrix(x) && isnumeric(y) &&...
                        min(size(x))>1 && isequal(size(x),size(y));
                end                
            elseif n==3 || n==4
                x = inputvals{1};
                y = inputvals{2};
                z = inputvals{3};
                toshow = isnumeric(x) && isnumeric(y) && isnumeric(z);
                
                hasDatetimeArg = false;
                
                % datetime and duration only supported in surf and mesh
                if strcmp(fname, 'surf') || strcmp(fname, 'mesh')
                    toshow = (isnumeric(x) || isdatetime(x) || isduration(x) || iscategorical(x))...
                        && (isnumeric(y) || isdatetime(y) || isduration(y) || iscategorical(y))...
                        && (isnumeric(z) || isdatetime(z) || isduration(z) || iscategorical(z));
                    % At least one of my arguments is a datetime or duration
                    hasDatetimeArg = toshow;
                end
                
                % If one of my arguments is a datetime or duration, do not
                % use the local isBasicMatrix functions as they always
                % return false for datetime/duration objects
                if hasDatetimeArg
                    if toshow
                        toshow = (ismatrix(x) && min(size(x))>1 && isequal(size(x),size(y)) && isequal(size(x),size(z))) || ...
                            (ismatrix(z) && isvector(x) && isvector(y) && length(x)==size(z,2) && length(y)==size(z,1));
                    end
                else
                    if toshow
                        toshow = (isBasicMatrix(x) && min(size(x))>1 && isequal(size(x),size(y)) && isequal(size(x),size(z))) || ...
                            (isBasicMatrix(z) && isBasicVector(x) && isBasicVector(y) && length(x)==size(z,2) && length(y)==size(z,1));
                    end
                end
                if n==4 && toshow
                    c = inputvals{4};
                    toshow = isnumeric(c) && isequal(size(z),size(x));
                end
                
            elseif n>4
                toshow = false;
            end
        % A matrix, 2 vectors and a matrix, or 3 matrices of compatible
        % size. The number of rows and columns of matrix inputs must be >=3.
        case 'surfl'
            if n==1
                x = inputvals{1};
                toshow = isnumeric(x) && localIsMatrix(x) && min(size(x))>=3;
            elseif n==3
                x = inputvals{1};
                y = inputvals{2};
                z = inputvals{3};
                toshow = isnumeric(x) && isnumeric(y) && isnumeric(z) && min(size(z))>=3;
                if toshow
                   toshow = (isBasicMatrix(x) && min(size(x))>1 && isequal(size(x),size(y)) && isequal(size(x),size(z))) || ...
                     (isBasicMatrix(z) && isBasicVector(x) && isBasicVector(y) && length(x)==size(z,2) && length(y)==size(z,1));
                end
            elseif n>3
                toshow = false;
            end
        % A vector/matrix or 2 vectors/matrices of the compatible size with
        % an optional linespec parameter
        case {'semilogx','semilogy','loglog'} 
            if n==1
                x = inputvals{1};
                toshow = (isnumeric(x) || islogical(x)) && ~isscalar(x) && isBasicMatrix(x);
                
                % datetime and duration only supported in semilogx and
                % semilogy
                if strcmp(fname, 'semilogx') 
                    toshow = toshow || (isdatetime(x) || isduration(x) || iscategorical(x))...
                        && ~isscalar(x) && ismatrix(x);
                end
                
                 if strcmp(fname, 'semilogy')
                    toshow = toshow || (isduration(x))...
                        && ~isscalar(x) && ismatrix(x);                     
                 end
                
            elseif n==2
                toshow = localAreaArgFcn(inputvals);
                % datetime and duration only supported in semilogx and
                % semilogy
                if strcmp(fname, 'semilogx') || strcmp(fname, 'semilogy')
                    toshow = toshow || localAreaTimeArgFcn(inputvals) || ...
                        iscategorical(inputvals{1}) || iscategorical(inputvals{2});
                    
                    if toshow && strcmp(fname, 'semilogx')
                        toshow = toshow && isnumeric(inputvals{1});
                    end
                    
                    if toshow && strcmp(fname, 'semilogy')
                        toshow = toshow && isnumeric(inputvals{2});
                    end
                end
            elseif n==3
                toshow = localAreaArgFcn(inputvals(1:2));
                % datetime and duration only supported in semilogx and
                % semilogy
                if strcmp(fname, 'semilogx') || strcmp(fname, 'semilogy')
                    toshow = toshow || localAreaTimeArgFcn(inputvals(1:2));
                    if toshow && strcmp(fname, 'semilogx')
                        toshow = toshow && isnumeric(inputvals{1});
                    end
                    
                    if toshow && strcmp(fname, 'semilogy')
                        toshow = toshow && isnumeric(inputvals{2});
                    end
                end
                toshow = toshow && (ischar(inputvals{3}) || isstring(inputvals{3}));
            elseif n>3
                toshow = false;
            end
        case {'errorbar','errorbarhorz'} %Between 2, 3, 4, or 6 vectors or matrices with compatible sizes
            if n==2
                x = inputvals{1};
                y = inputvals{2};
                toshow = isBasicMatrix(x) && isnumeric(x) && ...
                    isBasicMatrix(y) && (isnumeric(y) || islogical(y));
                if toshow
                    % Check toshow at this point to verify that x & y are 
                    % valid datatypes to send to findMatchingDimensions.
                    err = findMatchingDimensions(x,y);
                    toshow = toshow && isempty(err);
                end
            elseif n==3
                x = inputvals{1};
                y = inputvals{2};
                l = inputvals{3};
                toshow = isBasicMatrix(x) && isnumeric(x) && ...
                    isBasicMatrix(y) && (isnumeric(y) || islogical(y));
                toshow = toshow && isBasicMatrix(l) && (isnumeric(l) || islogical(l));
                if toshow
                    % Check toshow at this point to verify that x & y are 
                    % valid datatypes to send to findMatchingDimensions.
                    err = findMatchingDimensions(x,y,l);
                    toshow = toshow && isempty(err);
                end
            elseif n==4
                x = inputvals{1};
                y = inputvals{2};
                l = inputvals{3};
                u = inputvals{4};
                toshow = isBasicMatrix(x) && isnumeric(x) && isBasicMatrix(y) && ...
                    (isnumeric(y) || islogical(y));
                toshow = toshow && isBasicMatrix(l) && (isnumeric(l) || islogical(l));
                toshow = toshow && isBasicMatrix(u) && (isnumeric(u) || islogical(u));
                 if toshow
                    % Check toshow at this point to verify that x & y are 
                    % valid datatypes to send to findMatchingDimensions.
                    err = findMatchingDimensions(x,y,l,u);
                    toshow = toshow && isempty(err);
                end
            elseif n==6 && strcmpi(fname, 'errorbar') % 6 only allowed for vertical
                x = inputvals{1};
                y = inputvals{2};
                yneg = inputvals{3};
                ypos = inputvals{4};
                xneg = inputvals{5};
                xpos = inputvals{6};
                toshow = isBasicMatrix(x) && isnumeric(x) && isBasicMatrix(y) && ...
                    (isnumeric(y) || islogical(y));
                toshow = toshow && isBasicMatrix(yneg) && (isnumeric(yneg) || islogical(yneg));
                toshow = toshow && isBasicMatrix(ypos) && (isnumeric(ypos) || islogical(ypos));
                toshow = toshow && isBasicMatrix(xneg) && (isnumeric(xneg) || islogical(xneg));
                toshow = toshow && isBasicMatrix(xpos) && (isnumeric(xpos) || islogical(xpos));
                 if toshow
                    % Check toshow at this point to verify that x & y are 
                    % valid datatypes to send to findMatchingDimensions.
                    err = findMatchingDimensions(x,y,yneg,ypos,xneg,xpos);
                    toshow = toshow && isempty(err);
                end
            elseif n>6
                toshow = false;
            end
        case {'plot3','stem3'} %3 vectors or matrices of compatible size with an optional 4th linespec
            if n==3
                x = inputvals{1};
                y = inputvals{2};
                z = inputvals{3};
                allVectors = localIsVector(x) && localIsVector(y) && localIsVector(z) && ...
                    length(x)==length(y) && length(x)==length(z);
                allMatrices = localIsMatrix(x) && localIsMatrix(y) && localIsMatrix(z) && ...
                    isequal(size(x),size(y)) && isequal(size(x),size(z));                
                toshow = allVectors || allMatrices;
                % dateteime and duration only supported in plot3
                if strcmp(fname, 'stem3') && (isdatetime(x) || isduration(x) ||...
                        iscategorical(x) || isdatetime(y) || isduration(y) || iscategorical(y)...
                        || isdatetime(z) || isduration(z) || iscategorical(z))
                    toshow = false;
                end
            elseif n==4
                x = inputvals{1};
                y = inputvals{2};
                z = inputvals{3};
                c = inputvals{4};
                allVectors = localIsVector(x) && localIsVector(y) && localIsVector(z) && ...
                    length(x)==length(y) && length(x)==length(z);
                allMatrices = localIsMatrix(x) && localIsMatrix(y) && localIsMatrix(z) && ...
                    isequal(size(x),size(y)) && isequal(size(x),size(z));
                toshow = (allVectors || allMatrices) && ischar(c);
                % dateteime and duration only supported in plot3
                if strcmp(fname, 'stem3') && (isdatetime(x) || isduration(x) ||...
                        iscategorical(x) || isdatetime(y) || isduration(y) || iscategorical(y)...
                        || isdatetime(z) || isduration(z) || iscategorical(z))
                    toshow = false;
                end
            elseif n>4
                toshow = false;
            end
        case 'comet' %1 or 2 vectors of the same size with optional additional tail length
            if n==1
                x = inputvals{1};
                toshow = isBasicVector(x) && (isnumeric(x) || islogical(x)) && ...
                    ~isscalar(x) && isreal(x);
            elseif n==2
                x = inputvals{1};
                y = inputvals{2};
                toshow = isBasicVector(x) && isnumeric(x) && ~isscalar(x) ;
                toshow = toshow && (isBasicVector(y) || islogical(y)) && isnumeric(y)  && length(x)==length(y);
            elseif n==3
                x = inputvals{1};
                y = inputvals{2};
                p = inputvals{3};
                toshow =isBasicVector(x) && isnumeric(x) && ~isscalar(x) ;
                toshow = toshow && isBasicVector(y) && (isnumeric(y) || islogical(y)) && ...
                    length(x)==length(y);
                toshow = toshow && isnumeric(p) && isscalar(p);
            elseif n>3
                toshow = false;
            end
        case 'pareto' %A vector and a cell array of labels or 2 vectors of the same size
            if n==1
                x = inputvals{1};
                toshow = isBasicVector(x) && isnumeric(x) && ~isscalar(x) && isfloat(x);
            elseif n==2
                x = inputvals{1};
                y = inputvals{2};
                toshow = isBasicVector(x) && isnumeric(x) && ~isscalar(x) && isfloat(x) && ...
                    isfloat(y);
                toshow = toshow && ((isnumeric(y) && isBasicVector(y) && length(x)==length(y)) || ...
                    (iscell(y) && length(y)==length(x) && all(cellfun('isclass',y,'char'))));
            elseif n>2
                toshow = false;
            end
        % 1 or 2 matrices with the same number of rows either with an
        % optional linespec
        case 'plotmatrix' 
            if n==1
                x = inputvals{1};
                toshow = (isnumeric(x) || islogical(x)) && isBasicMatrix(x) && ...
                    min(size(x))>=2 && isreal(x);
            elseif n==2
                x = inputvals{1};
                y = inputvals{2};
                toshow = (isnumeric(x) || islogical(x)) && (ischar(y) || ...
                    (size(x,1)==size(y,1) && size(x,1)>1 && ...
                    size(x,2)>1 && size(y,2)>1 && isBasicMatrix(x) && isBasicMatrix(y))) && ...
                    isreal(x) && isreal(y);
            elseif n==3
                x = inputvals{1};
                y = inputvals{2};
                l = inputvals{3};
                toshow = (isnumeric(x) || islogical(x)) && ischar(l) && ...
                    size(x,1)==size(y,1) && size(x,1)>1 && ...
                    size(x,2)>1 && size(y,2)>1 && isBasicMatrix(x) && isBasicMatrix(y) && ...
                    isreal(x) && isreal(y);
            elseif n>3
                toshow = false;
            end
        case {'scatter' 'swarmchart'}
            % Valid x & y inputs for scatter & swarmchart's Plot Gallery entries:
            % (1) A 2-column matrix (x is first column, y is second column)
            % (2) 2 vectors of the same size
            % (3) 2 matrices of the same size
            % (4) 1 column vector and 1 matrix which have the same size in
            %       the first dimension
            % (5) 1 scalar and 1 vector
            % For all of the above: optional size, color and linespec parameters
            
            if n>=1
                x = inputvals{1};
                xvalid = ismatrix(x) && (isnumeric(x) || islogical(x) || ...
                    iscategorical(x) || isdatetime(x) || isduration(x));
            end
            
            if n == 1
                % This is the 2-column matrix cases where x is taken to be
                % the first column and y the second.
                toshow = xvalid && size(x,2)==2;
            end
            
            if n>=2
                y = inputvals{2};
                yvalid = ismatrix(y) && (isnumeric(y) || islogical(y) || ...
                    iscategorical(y) || isdatetime(y) || isduration(y));
                toshow = xvalid && yvalid;
                if toshow
                    % Check toshow at this point to verify that x & y are 
                    % valid datatypes to send to findMatchingDimensions.
                    err = findMatchingDimensions(x,y);
                    toshow = toshow && isempty(err);
                end
            end
            
            if n>=3
                s = inputvals{3};
                svalid = ismatrix(s) && isnumeric(s) && all(s(~isnan(s))>0);
                toshow = toshow && svalid;
                if toshow
                    % Check toshow at this point to verify that x,  y & s 
                    % are valid datatypes to send to findMatchingDimensions.
                    err = findMatchingDimensions(x,y,s);
                    szScalar = isscalar(s);
                    szEmpty = isempty(s);
                    toshow = toshow && (szScalar || szEmpty || isempty(err));
                end
            end
            
            if n == 4
                c = inputvals{4};
                % For simplicity, this logic intentionally does not account
                % for valid cases where the size input is the one causing
                % multiple objects to be created, e.g.:
                %       scatter(3,3,[1:5],parula(5))
                cRGBMat = isBasicMatrix(c) && width(c) == 3 && ...
                    height(c) > 1 && isnumeric(c) && ...
                    all(0<=c & c<=1,'all');
                cRGBSingle = isBasicMatrix(c) && all(size(c) == [1,3]) && ...
                    isnumeric(c) && all(0<=c & c<=1,'all');
                cVec = isBasicVector(c) && isnumeric(c);
                cNamed = false;
                if isstring(c) || ischar(c)
                    [~, c, ~,~] = colstyle(c);
                    cNamed = ~isempty(c);
                end
                cRGBMatMatchHeight = cRGBMat && height(c) == height(x) && ...
                    height(c) == height(y);
                cVecXYVec = cVec && isvector(x) && isvector(y) &&  ...
                    isvector(s) && numel(c) == numel(x);
                toshow = toshow && (cRGBSingle || cNamed || ...
                    cRGBMatMatchHeight || cVecXYVec);
            elseif n>4
                toshow = false;
            end

        %3 vectors of the same size with an optional area parameter or linespec       
        case {'scatter3' 'swarmchart3'}
            if n==3
                x = inputvals{1};
                y = inputvals{2};
                z = inputvals{3};
                xnumeric = isnumeric(x) || islogical(x) || iscategorical(x);
                ynumeric = isnumeric(y) || islogical(y) || iscategorical(y);
                znumeric = isnumeric(z) || islogical(z) || iscategorical(z);
                toshow = isBasicVector(x) && xnumeric && isBasicVector(y) && ...
                    ynumeric && isBasicVector(z) && znumeric && ...
                    length(x)==length(y) && length(y)==length(z);
                toshow = toshow || ((isdatetime(x) || isdatetime(y) || isdatetime(z))...
                    &&  length(x)==length(y) && length(y)==length(z));
            elseif n==4
                x = inputvals{1};
                y = inputvals{2};
                z = inputvals{3};
                s = inputvals{4};
                xnumeric = isnumeric(x) || islogical(x) || iscategorical(x);
                ynumeric = isnumeric(y) || islogical(y) || iscategorical(y);
                znumeric = isnumeric(z) || islogical(z) || iscategorical(z);
                toshow = isBasicVector(x) && xnumeric && isBasicVector(y) && ...
                    ynumeric && isBasicVector(z) && znumeric && ...
                    length(x)==length(y) && length(y)==length(z); 
                toshow = toshow || ((isdatetime(x) || isdatetime(y) || isdatetime(z))...
                    &&  length(x)==length(y) && length(y)==length(z));
                toshow = toshow && (ischar(s) || (isnumeric(s) && isscalar(s)));
            elseif n>4
                toshow = false;
            end
        case {'bubblechart','polarbubblechart'}
            if n==1
                % bubblechart(x(:,1),x(:,2),x(:,3))
                x = inputvals{1};
                toshow = (isnumeric(x) || islogical(x)) && ~isscalar(x) && size(x,1)>1 && ...
                    size(x,2)==3;
            elseif n==3
                % bubblechart(x,y,s)
                x = inputvals{1};
                y = inputvals{2};
                s = inputvals{3};
                xvalidtype = isnumeric(x) || islogical(x) || iscategorical(x) || isdatetime(x) || isduration(x);
                yvalidtype = isnumeric(y) || islogical(y) || iscategorical(y) || isdatetime(y) || isduration(y);
                svalidtype = isnumeric(s) || islogical(y);
                
                sizevalid = isvector(x) && isvector(y) && isvector(s) && ...
                    numel(x) == numel(y) && numel(x) == numel(s);

                toshow = xvalidtype && yvalidtype && svalidtype && sizevalid;
            elseif n==4
                % bubblechart(x,y,s,clr)
                % note that color can be a char/rgb (one color) or a vector/rgb array
                x = inputvals{1};
                y = inputvals{2};
                s = inputvals{3};
                c = inputvals{4};
                xvalidtype = isnumeric(x) || islogical(x) || iscategorical(x) || isdatetime(x) || isduration(x);
                yvalidtype = isnumeric(y) || islogical(y) || iscategorical(y) || isdatetime(y) || isduration(y);
                svalidtype = isnumeric(s) || islogical(s);
                
                sizevalid = isvector(x) && isvector(y) && isvector(s) && ...
                    numel(x) == numel(y) && numel(x) == numel(s);
                
                cvalid = (ischar(c) || isstring(c)) || ...                  % colorspec
                    (isvector(c) && numel(c)==numel(x)) || ...              % colormapped vector
                    (width(c)==3 && (height(c)==1 || height(c)==numel(x))); % RGB scalar/array
                         
                toshow = xvalidtype && yvalidtype && svalidtype && ...
                    sizevalid && cvalid;
            elseif n>4
                toshow = false;
            end
        %3 vectors of the same size with an optional area parameter or linespec       
        case 'bubblechart3'
            if n==4
                % bubblechart3(x,y,z,s)
                x = inputvals{1};
                y = inputvals{2};
                z = inputvals{3};
                s = inputvals{4};

                xvalidtype = isnumeric(x) || islogical(x) || iscategorical(x) || isdatetime(x) || isduration(x);
                yvalidtype = isnumeric(y) || islogical(y) || iscategorical(y) || isdatetime(y) || isduration(y);
                zvalidtype = isnumeric(z) || islogical(z) || iscategorical(z) || isdatetime(z) || isduration(z);
                svalidtype = isnumeric(s) || islogical(s);
                
                sizevalid = isvector(x) && isvector(y) && isvector(z) && isvector(s) && ...
                    numel(x) == numel(y) && numel(x) == numel(s) && numel(x) == numel(z);

                toshow = xvalidtype && yvalidtype && zvalidtype && svalidtype && sizevalid;
            elseif n==5
                % bubblechart3(x,y,z,s,c)
                x = inputvals{1};
                y = inputvals{2};
                z = inputvals{3};
                s = inputvals{4};
                c = inputvals{5};

                xvalidtype = isnumeric(x) || islogical(x) || iscategorical(x) || isdatetime(x) || isduration(x);
                yvalidtype = isnumeric(y) || islogical(y) || iscategorical(y) || isdatetime(y) || isduration(y);
                zvalidtype = isnumeric(z) || islogical(z) || iscategorical(z) || isdatetime(z) || isduration(z);
                svalidtype = isnumeric(s) || islogical(s);
                
                sizevalid = isvector(x) && isvector(y) && isvector(z) && isvector(s) && ...
                    numel(x) == numel(y) && numel(x) == numel(s) && numel(x) == numel(z);

                cvalid = (ischar(c) || isstring(c)) || ...                  % colorspec
                    (isvector(c) && numel(c)==numel(x)) || ...              % colormapped vector
                    (width(c)==3 && (height(c)==1 || height(c)==numel(x))); % RGB scalar/array

                toshow = xvalidtype && yvalidtype && zvalidtype && svalidtype && sizevalid && cvalid;
            elseif n>5
                toshow = false;
            end
        case 'bubblecloud'
            if n>=1
                sz = inputvals{1};
                toshow = isnumeric(sz) && ~isscalar(sz) && isvector(sz) && ~any(sz<0);
            end
            if n>=2
                lbl = inputvals{2};
                toshow = toshow && ...
                    (isstring(lbl) || iscellstr(lbl)) && isvector(lbl) && ...
                    numel(sz)==numel(lbl);
            end
            
            if n==3
                gp = inputvals{3};
                toshow = toshow && iscategorical(gp) && isvector(gp) && ...
                    numel(sz)==numel(gp);
            end
            
            if n>3
                toshow = false;
            end
            
        % 1 vector or matrix with optional scalar/string marker size and linespec arguments       
        case 'spy' 
            if n==1
                s = inputvals{1};
                toshow = (isnumeric(s) || islogical(s)) && ~isscalar(s) && isBasicMatrix(s);
            elseif n==2
                s = inputvals{1};
                l = inputvals{2};
                toshow = (isnumeric(s) || islogical(s)) && ~isscalar(s) && isBasicMatrix(s);
                toshow = toshow && (ischar(l) || (isnumeric(l) && isscalar(l)));
            elseif n==3
                s = inputvals{1};
                l = inputvals{2};
                m = inputvals{3};
                toshow = (isnumeric(s) || islogical(s)) && ~isscalar(s) && isBasicMatrix(s);
                toshow = toshow && (ischar(l) || (isnumeric(l) && isscalar(l)));
                toshow = toshow && (ischar(m) || (isnumeric(m) && isscalar(m)));
            elseif n>3
                toshow = false;
            end
        case 'polarhistogram' %1 or 2 vectors of the same size
            if n==1
                x = inputvals{1};
                toshow = isBasicVector(x) && (isnumeric(x) || islogical(x)) && ...
                    ~isscalar(x) && isreal(x);
            elseif n==2
                x = inputvals{1};
                y = inputvals{2};
                toshow = isBasicVector(x) && (isnumeric(x) || islogical(x)) && ~isscalar(x);
                toshow = toshow && isBasicVector(y) && isnumeric(y) && length(x)==length(y);
            elseif n>2
                toshow = false;
            end
        case 'polarplot' %2 vectors or matrices of the same size with optional linepsec string
            if n==1
                rho = inputvals{1};
                toshow = ndims(rho)<=2 && isnumeric(rho)  && ~isscalar(rho);
            elseif n==2 || n==3
                theta = inputvals{1};
                rho = inputvals{2};
                toshow = ndims(theta)<=2 && isnumeric(theta) && ~isscalar(theta) && ...
                    isnumeric(rho) && isequal(size(theta),size(rho));
                if toshow && n==3
                toshow = ischar(inputvals{3}) || isstring(inputvals{3});
                end
            elseif n>3
                toshow = false;
            end
        case 'polarscatter' %2 vectors or matrices of the same size with optional 3rd input that is scalar or same size as vectors
            if n==2 || n==3
                theta = inputvals{1};
                rho = inputvals{2};
                toshow = ndims(theta)<=2 && isnumeric(theta) && ~isscalar(theta) && ...
                    isnumeric(rho) && isequal(size(theta),size(rho));
                if toshow && n==3
                    s = inputvals{3};
                    toshow = isnumeric(s) && (isscalar(s) || isequal(size(s),size(rho)));
                end
            elseif n>3
                toshow = false;
            end
        case 'compassplot' % One or two scalars, vectors, or matrices, or a table followed by a pair of table variable indices
            if n==1
                u = inputvals{1};
                toshow = isfloat(u) && (isBasicMatrix(u) || isscalar(u));
            elseif n==2
                u = inputvals{1};
                v = inputvals{2};
                toshow = isnumeric(u) && isnumeric(v);
                toshow = toshow && ((isscalar(u) && isscalar(v)) || ...
                    (isBasicVector(u) && isBasicVector(v) && length(u)==length(v)) || ...
                    (isBasicMatrix(u) && isBasicMatrix(v) && isequal(size(u),size(v))) || ...
                    ((isBasicVector(u) && isBasicMatrix(v) && (length(u)==size(v,1) || length(u)==size(v,2))) || ...
                    (isBasicVector(v) && isBasicMatrix(u) && (length(u)==size(v,1) || length(u)==size(v,2)))));
            elseif n==3
                tbl = inputvals{1};
                thetavar = inputvals{2};
                rhovar = inputvals{3};
                toshow = istable(tbl) && (...
                    ((ischar(thetavar) || isstring(thetavar) || isscalar(thetavar))...
                    && (ischar(rhovar) || isstring(rhovar) || isscalar(rhovar)))...
                    || (isBasicVector(thetavar) && isBasicVector(rhovar) && length(thetavar)==length(rhovar)));
            elseif n>3
                toshow = false;
            end
        case 'geoplot'
            if n == 2
                % geoplot(lat, lon)
                lat = inputvals{1};
                lon = inputvals{2};
                toshow = isGeoCoordinates(lat, lon);
            elseif n == 3
                % geoplot(lat, lon, linespec)
                lat = inputvals{1};
                lon = inputvals{2};
                lspec = inputvals{3};
                toshow = isGeoCoordinates(lat, lon) && (ischar(lspec) || isstring(lspec));
            elseif n>3
                toshow = false;
            end
        case 'geoscatter'
            if n == 2
                % geoscatter(lat, lon)
                lat = inputvals{1};
                lon = inputvals{2};
                toshow = isGeoCoordinates(lat, lon);
            elseif n == 3
                % geoscatter(lat, lon, sizedata)
                % geoscatter(lat, lon, colorspec)
                lat = inputvals{1};
                lon = inputvals{2};
                s = inputvals{3};
                if isGeoCoordinates(lat, lon)
                    toshow = (isnumeric(s) && length(s) == length(lat)) || ischar(s) || isstring(s) ;
                else
                    toshow = false;
                end
            elseif n == 4
                % geoscatter(lat, lon, sizedata, colordata)
                % geoscatter(lat, lon, sizedata, colorspec)
                lat = inputvals{1};
                lon = inputvals{2};
                s = inputvals{3};
                c = inputvals{4};
                if isGeoCoordinates(lat, lon)
                    toshow = isnumeric(s) && length(s) == length(lat);
                    toshow = toshow && (ischar(c) ...
                        || (isnumeric(c) && length(c) == length(lat)));
                else
                    toshow = false;
                end
            elseif n>4
                toshow = false;
            end
        case 'geobubble'
            if n == 2
                % geobubble(lat, lon)
                lat = inputvals{1};
                lon = inputvals{2};
                toshow = isGeoCoordinates(lat, lon);
            elseif n == 3
                if isa(inputvals{1}, 'tabular')
                    % When 'geobubble' is called with a table as the
                    % first input argument, the next two arguments are
                    % required and must be subscripts into the table.
                    % The subscripts can be in the form of strings,
                    % character vectors, cellstrs, numeric, logical,
                    % or one of the table subscript objects. That
                    % checking is being done by
                    % isScalarTableSubscript.
                    %
                    % geobubble(tbl, latvar, lonvar)
                    
                    tbl = inputvals{1};
                    latvar = inputvals{2};
                    lonvar = inputvals{3};
                    if isScalarTableSubscript(tbl, latvar) && ...
                            isScalarTableSubscript(tbl, lonvar)
                        % geobubble(tbl, latvar, lonvar)
                        toshow = true;
                    else
                        % One of the input arguments is not a valid table
                        % subscript, or refers to more than one column in
                        % the table.
                        toshow = false;
                    end
                else
                    % geobubble(lat, lon, sizedata)
                    lat = inputvals{1};
                    lon = inputvals{2};
                    s = inputvals{3};
                    if isGeoCoordinates(lat, lon)
                        toshow = isnumeric(s) && length(s) == length(lat);
                    else
                        toshow = false;
                    end
                end
            elseif n == 4
                % geobubble(lat, lon, sizedata, colordata)
                lat = inputvals{1};
                lon = inputvals{2};
                s = inputvals{3};
                c = inputvals{4};
                if isGeoCoordinates(lat, lon)
                    toshow = isnumeric(s) && length(s) == length(lat);
                    toshow = toshow && iscategorical(c) && ...
                        length(c) == length(lat);
                else
                    toshow = false;
                end
            elseif n>4
                toshow = false;
            end
        case {'image','imagesc'} %1 color array or 2 vectors and an color array of compatible size
            if n==1
                x = inputvals{1};
                if (isnumeric(x) || islogical(x)) && min(size(x))>1
                    if isBasicMatrix(x)
                        toshow = true;
                    elseif ndims(x)==3 && size(x,3)==3
                        if isfloat(x)
                            toshow = (max(x(:))<=1 && min(x(:))>=0);
                        elseif isinteger(x)
                            toshow =  isa(x,'uint8') || isa(x,'uint16');
                        end
                    else
                        toshow = false;
                    end
                end
            elseif n==3
                x = inputvals{1};
                y = inputvals{2};
                C = inputvals{3};
                if isBasicVector(x) && isnumeric(x) && isBasicVector(y) && ...
                       isnumeric(y) && (isnumeric(C) || islogical(C))
                    if isBasicMatrix(C)
                        toshow = true;
                    elseif ndims(C)==3 && size(C,3)==3
                        if isfloat(C)
                            toshow = (max(C(:))<=1 && min(C(:))>=0);
                        elseif isinteger(x)
                            toshow =  isa(C,'uint8') || isa(C,'uint16');
                        end
                    else
                        toshow = false;
                    end
                end
            elseif n>3
                toshow = false;
            end
        case 'pcolor' %1 color array or 2 vectors and an color array of compatible size
            if n==1
                x = inputvals{1};
                if isnumeric(x)  && min(size(x))>1
                    if isBasicMatrix(x)
                        toshow = true;
                    elseif ndims(x)==3 && size(x,3)==3
                        toshow = max(x(:))<=1 && min(x(:))>=0;
                    else
                        toshow = false;
                    end
                end
            elseif n==3
                x = inputvals{1};
                y = inputvals{2};
                C = inputvals{3};
                if isBasicVector(x) && isnumeric(x) && isBasicVector(y) && ...
                       isnumeric(y) && isnumeric(C)
                    if isBasicMatrix(C) && size(C,1)==length(y) && size(C,2)==length(x)
                        toshow = true;
                    elseif ndims(C)==3 && size(C,3)==3
                        toshow = max(C(:))<=1 && min(C(:))>=0;
                    else
                        toshow = false;
                    end
                end
            elseif n>3
                toshow = false;
            end
        case 'heatmap'
            if (n == 3 || n == 4) && isa(inputvals{1}, 'tabular')
                % When 'heatmap' is called with a table as the first input
                % argument, the next two arguments are required and must be
                % subscripts into the table. The subscripts can be in the
                % form of strings, character vectors, cellstrs, numeric,
                % logical, or one of the table subscript objects. That
                % checking is being done by isScalarTableSubscript.
                %
                % Valid syntaxes:
                % table + 2 subscripts: heatmap(tbl, xvar, yvar)
                % table + 3 subscripts: heatmap(tbl, xvar, yvar, 'ColorVariable', cvar)
                
                tbl = inputvals{1};
                xvar = inputvals{2};
                yvar = inputvals{3};
                if isScalarTableSubscript(tbl, xvar) && isScalarTableSubscript(tbl, yvar)
                    % Check if the 4th input is a valid ColorVariable.
                    if n == 4
                        % heatmap(tbl, xvar, yvar, 'ColorVariable', cvar)
                        toshow = isScalarTableSubscript(tbl, inputvals{4});
                    else
                        % heatmap(tbl, xvar, yvar)
                        toshow = true;
                    end
                else
                    % One of the input arguments is not a valid table
                    % subscript, or refers to more than one column in the
                    % table.
                    toshow = false;
                end
            elseif n == 1 && isnumeric(inputvals{1}) && ismatrix(inputvals{1}) && ~isvector(inputvals{1})
                % heatmap(cdata)
                toshow = true;
            elseif n == 3 && isnumeric(inputvals{3}) && ismatrix(inputvals{3})
                % heatmap(xdata, ydata, cdata)
                xdata = inputvals{1};
                ydata = inputvals{2};
                cdata = inputvals{3};
                
                % XData can be numeric, string, cellstr, or categorical.
                toshow = isstring(xdata) || iscellstr(xdata) || isnumeric(xdata) || iscategorical(xdata);
                
                % YData can be numeric, string, cellstr, or categorical.
                toshow = toshow && (isstring(ydata) || iscellstr(ydata) || isnumeric(ydata) || iscategorical(ydata));
            
                % The size of XData/YData must match the ColorData.
                toshow = toshow && numel(xdata) == size(cdata,2) && numel(ydata) == size(cdata,1);
            else
                toshow = false;
            end

       case 'imshow'
            
            if n == 1 || n == 2
                
                I = inputvals{1};
                
                % a filename is a string containing a '.'.  We put this
                % check in first so that we can bail out on non-filename
                % strings before calling EXIST which will hit the file
                % system.
                isStringContainingDot = ischar(I) && numel(I) > 2 && ...
                    ~isempty(strfind(I(2:end-1),'.'));
                
                isfile = false;
                if isStringContainingDot

                    dotLoc = strfind(I,'.');
                    fileExt = I( (dotLoc+1) : end);
                    
                    [~,extNames] = parseSharedImageFormats;
                    
                    % Check to see whether file extention matches any of
                    % the valid IPT file extentions
                    isValidExtention = false;
                    for i = 1:length(extNames)
                        if any(strcmp(fileExt,extNames{i}))
                            isValidExtention = true;
                            break;
                        end
                    end
                    
                    % If string is filename with a valid image file
                    % extention, do final most exensive operation of
                    % hitting filesystem to see whether this file exists.
                    if isValidExtention
                        isfile = exist(which(I),'file');
                    end
                end
                          
                is2d = ndims(I) == 2; %#ok<*ISMAT>
                is3d = ndims(I) == 3;
                isntVector = min(size(I)) > 1;
                
                % define image types
                isgrayscale = ~isfile && isnumeric(I) && is2d && isntVector;
                isindexed = isgrayscale && isinteger(I);
                istruecolor = ~isfile && isnumeric(I) && is3d && ...
                    isntVector && size(I,3) == 3;
                isbinary = ~isfile && islogical(I) && is2d && isntVector;
                
                toshow = isfile || isgrayscale || isindexed || ...
                    istruecolor || isbinary;
                
                % if 2 variables are selected...
                if toshow && n == 2
                    
                    arg2 = inputvals{2};
                    
                    iscolormap = ndims(arg2) == 2 && size(arg2,2) == 3 && ...
                        all(arg2(:) >= 0 & arg2(:) <= 1);
                    isdisplayrange = isnumeric(arg2) && isvector(arg2) && ...
                        length(arg2) == 2 && arg2(2) > arg2(1);
                    
                    if isindexed && iscolormap
                        % imshow(X,map)
                        toshow = true;
                        
                    elseif isgrayscale && isdisplayrange
                        % imshow(I,[low high])
                        toshow = true;
                        
                    else
                        toshow = false;
                        
                    end
                    
                end             
            elseif n>2
                toshow = false;
            end
        case 'ribbon' %1 matrix with 2 matrices or vectors of the same size with an optional scalar width parameter
            if n==1
                % Case: ribbon(Z)
                Z = inputvals{1};
                % Validate Z as a numeric matrix with more than one row and column
                toshow = isnumeric(Z) && isBasicMatrix(Z) && size(Z, 1) > 1 && size(Z, 2) > 1;

            elseif n==2
                % Case: ribbon(Y, Z)
                Y = inputvals{1};
                Z = inputvals{2};
                % Validate Y and Z as numeric matrices of the same size or vectors of the same length
                % If a combo, of a matrix and vector, check the size or length depending on the order
                if isnumeric(Y) && isnumeric(Z) && ~isscalar(Y) && ~isscalar(Z)
                    toshow = (isBasicVector(Y) && isBasicVector(Z) && isequal(length(Y), length(Z))) || ...
                        (isequal(size(Y), size(Z))) || ...
                        (isBasicVector(Y) && isBasicMatrix(Z) && isequal(length(Y), size(Z, 1))) || ...
                        (isBasicMatrix(Y) && isBasicVector(Z) && isequal(size(Y), size(Z)));
                else
                    toshow = false;
                end
            elseif n==3
                % Case: ribbon(Y, Z, width)
                Y = inputvals{1};
                Z = inputvals{2};
                w = inputvals{3};
                % Width must be a scalar value
                % Validate Y and Z as numeric matrices of the same size or vectors of the same length
                % If a combo, of a matrix and vector, check the size or length depending on the order
                if isnumeric(w) && isscalar(w) && ~isscalar(Y) && ~isscalar(Z)
                    toshow = (isBasicVector(Y) && isBasicVector(Z) && isequal(length(Y), length(Z))) || ...
                        (isequal(size(Y), size(Z))) || ...
                        (isBasicVector(Y) && isBasicMatrix(Z) && isequal(length(Y), size(Z, 1))) || ...
                        (isBasicMatrix(Y) && isBasicVector(Z) && isequal(size(Y), size(Z)));
                end
            else
                % More than 3 inputs are not supported
                toshow = false;
            end
        case 'fplot'
        % fplot(function)
        % fplot(function,range)
        % fplot(function,function)
        % fplot(function,function,range)
            if n==1
                toshow = isFunctionOrSym(inputvals{1},1);
            elseif n==2
                fcn = inputvals{1};
                x = inputvals{2};
                toshow = isFunctionOrSym(fcn,1) && ...
                  (isRangeVector(x) || isFunctionOrSym(x,1));
            elseif n==3
                fcn1 = inputvals{1};
                fcn2 = inputvals{2};
                x = inputvals{3};
                toshow = isFunctionOrSym(fcn1,1) && ...
                  isFunctionOrSym(fcn2,1) && ...
                  isRangeVector(x);
            elseif n>3
                toshow = false;
            end
        case 'fplot3' % 3 univariate function handles with an optional domain range vector
            if n==3
               fcnx = inputvals{1};
               fcny = inputvals{2};
               fcnz = inputvals{3};
               toshow = isFunctionOrSym(fcnx,1) && isFunctionOrSym(fcny,1) && isFunctionOrSym(fcnz,1);
            elseif n==4
               fcnx = inputvals{1};
               fcny = inputvals{2};
               fcnz = inputvals{3};
               range = inputvals{4};
               toshow = isFunctionOrSym(fcnx,1) && isFunctionOrSym(fcny,1) && isFunctionOrSym(fcnz,1);
               toshow = toshow && isRangeVector(range);
            elseif n>4
                toshow = false;
            end
        case 'fpolarplot' % A function handle followed by an optional polar angle interval (as a two-element vector) and an optional LineSpec string
            if n==1
                fcn = inputvals{1};
                toshow = isa(fcn,'function_handle') && nargin(fcn)==1;
            elseif n==2
                fcn = inputvals{1};
                % The second input must be either valid range or valid linespec
                toshow = isa(fcn,'function_handle') && nargin(fcn)==1;
                if ~ischar(inputvals{2}) && ~isstring(inputvals{2})
                    theta = inputvals{2};
                    toshow = toshow && isnumeric(theta) && isBasicVector(theta) && ...
                        length(theta)==2 && theta(2)>theta(1);
                end
            elseif n==3
                fcn = inputvals{1};
                theta = inputvals{2};
                linespec = inputvals{3};
                toshow = isa(fcn,'function_handle') && nargin(fcn)==1 && ...
                    isnumeric(theta) && isBasicVector(theta) && ...
                    length(theta)==2 && theta(2)>theta(1);
                toshow = toshow && (ischar(linespec) || isstring(linespec));
            elseif n>3
                toshow = false;
            end
        case {'fcontour','fimplicit'} % A 2-input function handle with an optional 2 or 4 element range
             if n==1
                toshow = isFunctionOrSym(inputvals{1},2);
             elseif n==2
                fcn = inputvals{1};
                domain = inputvals{2};
                toshow = isFunctionOrSym(fcn,2) && ...
                  (isRangeVector(domain) || isRangeVector4(domain));
             elseif n>2
                toshow = false;
            end
        case 'fimplicit3' % A 3-input function handle with an optional 2 or 6 element range
             if n==1
                toshow = isFunctionOrSym(inputvals{1},3);
             elseif n==2
                fcn = inputvals{1};
                domain = inputvals{2};
                toshow = isFunctionOrSym(fcn,3) && ...
                  (isRangeVector(domain) || isRangeVector6(domain));
             elseif n>2
                toshow = false;
            end
        case {'fsurf','fmesh'} % One or three 2-input functions with an optional 2 or 4 element range
             if n==1
                toshow = isFunctionOrSym(inputvals{1},2);
             elseif n==2
                fcn = inputvals{1};
                domain = inputvals{2};
                toshow = isFunctionOrSym(fcn,2) && ...
                  (isRangeVector(domain) || isRangeVector4(domain));
             elseif n==3
                fcnx = inputvals{1};
                fcny = inputvals{2};
                fcnz = inputvals{3};
                toshow = isFunctionOrSym(fcnx,2) && ...
                  isFunctionOrSym(fcny,2) && ...
                  isFunctionOrSym(fcnz,2);
             elseif n==4
                fcnx = inputvals{1};
                fcny = inputvals{2};
                fcnz = inputvals{3};
                domain = inputvals{4};
                toshow = isFunctionOrSym(fcnx,2) && ...
                  isFunctionOrSym(fcny,2) && ...
                  isFunctionOrSym(fcnz,2) && ...
                  (isRangeVector(domain) || isRangeVector4(domain));
             elseif n>4
                toshow = false;
            end
        case 'slice' % 3 dimensional array with 3 vectors defining slice planes
            if n==4
                V = inputvals{1};
                sx = inputvals{2};
                sy = inputvals{3};
                sz = inputvals{4};
                toshow = isnumeric(V) && ndims(V)==3 && isnumeric(sx) && ...
                    isBasicVector(sx) && isnumeric(sy) && isBasicVector(sy) && ...
                    isnumeric(sz) && isBasicVector(sz);
            elseif n>4
                toshow = false;
            end
        case 'feather' % A numeric array or 2 numeric arrays of the same size
             if n==1
                Z = inputvals{1};
                toshow = (isnumeric(Z) || islogical(Z)) && ~isscalar(Z) && isfloat(Z);
             elseif n==2
                U = inputvals{1};
                V = inputvals{2};
                toshow = (isnumeric(U) || islogical(U)) && (isnumeric(V) || islogical(V)) && ...
                    ~isscalar(U) && isfloat(U) && isfloat(V) && isequal(size(U),size(V));
             elseif n>2
                toshow = false;
            end
        case 'quiver' % 2 or 4 numeric arrays of the same size
            if n==2
                u = inputvals{1};
                v = inputvals{2};
                toshow = (isnumeric(u) || islogical(u)) && ~isscalar(u) && ...
                    (isnumeric(v) || islogical(v)) && isequal(size(u),size(v));
            elseif n==4
                x = inputvals{1};
                y = inputvals{2};
                u = inputvals{3};
                v = inputvals{4};
                numericx = (isnumeric(x) || islogical(x));
                numericy = (isnumeric(y) || islogical(y));
                numericu = (isnumeric(u) || islogical(u));
                numericv = (isnumeric(v) || islogical(v));
                toshow = numericu && ~isscalar(u) && numericv && ...
                    numericx && numericy && isequal(size(u),size(v)) && ...
                    isequal(size(x),size(u)) && isequal(size(y),size(u));
            elseif n>4
                toshow = false;
            end
        case 'quiver3' % 4 numeric arrays of the same size
           if n==4
                z = inputvals{1};
                u = inputvals{2};
                v = inputvals{3};
                w = inputvals{4};
                numericz = (isnumeric(z) || islogical(z));
                numericu = (isnumeric(u) || islogical(u));
                numericv = (isnumeric(v) || islogical(v));
                numericw = (isnumeric(w) || islogical(w));
                toshow = numericz && ~isscalar(z) && numericu && ...
                    numericv && numericw && isequal(size(z),size(u)) && ...
                    isequal(size(z),size(v)) && isequal(size(z),size(w));
           elseif n>4
                toshow = false;
            end
        case 'stackedplot'
            if n==1 && (size(inputvals{1},1)>1) % To check if the number of rows is greater than 1
                y = inputvals{1};

                toshow = isa(y, 'tabular') || isnumeric(y) || ...
                    islogical(y) || isdatetime(y) || ...
                    isduration(y) || iscategorical(y);
            elseif n>=2 && isa(inputvals{1},"tabular") % multiple timetable or multiple table stackedplot
                alltimetable = true;
                alltable = true;
                for ii = 1:numel(inputvals)
                    alltimetable = alltimetable && isa(inputvals{ii},"timetable");
                    alltable = alltable && isa(inputvals{ii},"table");
                end
                toshow = alltimetable || alltable;
            elseif n==2
                x = inputvals{1};
                y = inputvals{2};

                toshow = (isvector(x) && (isnumeric(x) || ...
                    islogical(x) || isdatetime(x) || ...
                    isduration(x))) && (isnumeric(y) || ...
                    islogical(y) || isdatetime(y) || ...
                    isduration(y) || iscategorical(y)) && length(x) == size(y,1);
            elseif n>2
                toshow = false;
            end
        case 'streamslice' % Either 2 or 4 3-dimensional arrays of the same size
            if n==2 
                u = inputvals{1};
                v = inputvals{2};
                toshow = (isnumeric(u) || islogical(u))  && ~isscalar(u) && ...
                    (isnumeric(v) || islogical(v)) && ndims(u)==3 && ...
                    isequal(size(u),size(v));
            elseif n==4
                x = inputvals{1};
                y = inputvals{2};
                u = inputvals{3};
                v = inputvals{4};
                toshow = (isnumeric(u) || islogical(u)) && ~isscalar(u) && ...
                    (isnumeric(v) || islogical(v)) && ...
                    isnumeric(x) && isnumeric(y) && ndims(x)==3 && isequal(size(u),size(v)) && ...
                    isequal(size(x),size(u)) && isequal(size(y),size(u));
            elseif n>4
                toshow = false;
            end 
        case 'streamline' 
            % Cell array of double vertex arrays produced by stream2 or stream3
            % Necessary condition is that the cell array is a vector
            % containing 2 or 3 column matrices of vertices.
            if n==1 && ~isempty(inputvals{1}) && iscell(inputvals{1}) && isBasicVector(inputvals{1}) && ...
                    all(cellfun('ndims',inputvals{1})==2) && all(cellfun('isclass',inputvals{1},'double'))
                  colCount = cellfun('size',inputvals{1},2);
                  toshow = all(colCount>=2 & colCount<=3);
            elseif n>2
                toshow = false;
            end
        case 'wordcloud'
            % Wordcloud accepts inputs of type categorical, cellstr, string
            % char and the wordcoutner type as single inputs. The same are
            % accepted as the first argument when provided 2 inputs 
            % but at least one input is a size array of doubles of the same
            % length as the first array. The combination of wordlist object
            % and size array also works when 2 inputs provided
             if n==1
                inputs = inputvals{1};
                
                toshow = (iscategorical(inputs) || iscellstr(inputs) || ...
                    isstring(inputs)) || ischar(inputs) || ...
                    isa(inputs, 'wordCounter');
             elseif n==2
                 words = inputvals{1};
                 sizes = inputvals{2};
                 
                 toshow = isvector(words) && isvector(sizes) && ...
                     length(words) == length(sizes) && ...
                     isnumeric(sizes) && ...
                     (iscategorical(words) || isstring(words) ||...
                     iscellstr(words));
                 
                 if isa(words, 'wordCounter')
                     toshow = isvector(sizes) && isnumeric(sizes) && ...
                         (length(words.Vocabulary) == length(sizes));
                 end
             elseif n>2
                toshow = false;
            end
        case 'scatterhistogram'
            if (n == 3 || n == 4) && isa(inputvals{1}, 'tabular')
                % When 'scatterhistogram' is called with a table as the
                % first input argument, the next two arguments are required
                % and must be subscripts into the table. The subscripts can
                % be in the form of strings, character vectors, cellstrs,
                % numeric, logical, or one of the table subscript objects.
                % That checking is being done by isScalarTableSubscript.
                %
                % Valid syntaxes:
                % table + 2 subscripts: scatterhistogram(tbl, xvar, yvar)
                % table + 3 subscripts: scatterhistogram(tbl, xvar, yvar, 'GroupVariable', cvar)
                
                tbl = inputvals{1};
                xvar = inputvals{2};
                yvar = inputvals{3};
                if isScalarTableSubscript(tbl, xvar) && isScalarTableSubscript(tbl, yvar)
                    % Check if the 4th input is a valid GroupVariable.
                    if n == 4
                        % scatterhistogram(tbl, xvar, yvar, 'GroupVariable', grpvar)
                        toshow = isScalarTableSubscript(tbl, inputvals{4});
                    else
                        % scatterhistogram(tbl, xvar, yvar)
                        toshow = true;
                    end
                else
                    % One of the input arguments is not a valid table
                    % subscript, or refers to more than one column in the
                    % table.
                    toshow = false;
                end
            elseif (n == 2 || n == 3) && (isnumeric(inputvals{1}) || iscategorical(inputvals{1}))...
                    && (isnumeric(inputvals{2}) || iscategorical(inputvals{2}))
                % scatterhistogram(xdata, ydata)
                xdata = inputvals{1};
                ydata = inputvals{2};
                
                if isvector(xdata) && isvector(ydata) && (length(xdata) == length(ydata))
                    if n==2
                        toshow = true;
                    else
                        gdata = inputvals{3};
                        toshow = (isnumeric(gdata) || iscategorical(gdata) || isstring(gdata)...
                            || iscellstr(gdata) || ischar(gdata) || islogical(gdata)) &&...
                            (length(gdata) == length(xdata));
                    end
                else
                    toshow = false;
                end
            else
                toshow = false;
            end
        case 'parallelplot'
            % Parallelplot accepts inputs of type table or numeric matrix.
            % In both cases only 1 input is required. The rest are passed
            % in as Name-Value pairs.
            toshow = false;
            if ((n==1 || n==2) && (size(inputvals{1},1) >1) )  % To check if the number of rows is greater than 1
                inputs = inputvals{1};
                
                if isa(inputs,'tabular')
                    if n==2
                        toshow = isScalarTableSubscript(inputs, inputvals{2});
                    else
                        toshow = true;
                    end                    
                elseif isnumeric(inputs) && ismatrix(inputs)
                    if n==2
                        gdata = inputvals{2};
                        toshow = (isnumeric(gdata) || iscategorical(gdata) || isstring(gdata)...
                            || iscellstr(gdata) || ischar(gdata) || islogical(gdata)) &&...
                            (length(gdata) == size(inputs,1));
                    else
                        toshow = true;
                    end                    
                end
            elseif n>2
                toshow = false;
            end
         case 'boxchart'
             toshow = false;
             if n == 1
                % boxchart(ydata)
                toshow = isnumeric(inputvals{1}) && (isvector(inputvals{1}) || ismatrix(inputvals{1}));             
             elseif n == 2 && ~(ischar(inputvals{1}) || isstring(inputvals{1}))
                 % boxchart(xgroupdata,ydata)
                 x = inputvals{1};
                 y = inputvals{2};

                toshow = isnumeric(y) && isvector(y);
                toshow = toshow && (isvector(x) && (isnumeric(x) || iscategorical(x)));
                % Ensure length of ydata and xgroupdata is equal
                toshow = toshow && (length(x)==length(y));
             elseif n == 3 && ~(ischar(inputvals{1}) || isstring(inputvals{1})) && length(inputvals{1})==length(inputvals{3})
                 % boxchart(xgroupdata, ydata, 'GroupByColor',cgroupdata)
                x = inputvals{1}; % xgroupdata
                y = inputvals{2}; % ydata
                
                % x and y input validation:
                toshow = isnumeric(y) && isvector(y);
                toshow = toshow && (isvector(x) && (isnumeric(x) || iscategorical(x)) && ...
                    (length(x)==length(y)));
                % Color grouping and compatibility:
                cgrp = inputvals{3};
                toshow = toshow && ((isvector(cgrp) && (isnumeric(cgrp) || iscategorical(cgrp) || islogical(cgrp))) || isstring(cgrp) || iscell(cgrp));
             elseif n>3
                toshow = false;
             end
        case 'violinplot'
            toshow = false;
            if n == 1
                % violinplot(ydata)
                toshow = isnumeric(inputvals{1}) && (isvector(inputvals{1}) || ismatrix(inputvals{1}));
            elseif n == 2 && ~(ischar(inputvals{1}) || isstring(inputvals{1}))
                % violinplot(xgroupdata,ydata)
                x = inputvals{1}; % xgroupdata
                y = inputvals{2}; % ydata

                toshow = isnumeric(y) && (isvector(y) || ismatrix(y));
                toshow = toshow && (( isnumeric(x) && (isvector(x) || ismatrix(x)) ) ||...
                    ( iscategorical(x) && isvector(x) ));
                % Ensure compatibility of ydata and xgroupdata:
                toshow = toshow && (...
                    ( isvector(y) && (isscalar(x) || (isvector(x) && numel(y)==numel(x)) || (ismatrix(x) && size(x,1)==numel(y))) ) || ...
                    ( ismatrix(y) && (isvector(x) && (numel(x)==size(y,1) || numel(x)==size(y,2))) ||...
                                     (ismatrix(x) && isequal(size(x),size(y))) ));
            elseif n == 3 && ~(ischar(inputvals{1}) || isstring(inputvals{1})) && length(inputvals{2})==length(inputvals{3})
                % violinplot(xgroupdata, ydata, 'GroupByColor',cgroupdata)
                x = inputvals{1};
                y = inputvals{2};
                
                % x and y input validation:
                toshow = isnumeric(y) && isvector(y);
                toshow = toshow && ( isvector(x) && (isnumeric(x) || iscategorical(x)) && ...
                    (length(x)==length(y)) );
                % Color grouping and compatibility:
                cgrp = inputvals{3};
                toshow = toshow && ((isvector(cgrp) && (isnumeric(cgrp) || iscategorical(cgrp) || islogical(cgrp))) || isstring(cgrp) || iscell(cgrp));
             elseif n>3
                toshow = false;
            end
    end
    varargout{1} = toshow;
% Default execution strings for MATLAB plots
elseif strcmp(action,'defaultdisplay') 
    n = length(inputnames);
    appendedInputs = repmat({','},1,2*n-1);
    appendedInputs(1:2:end) = inputnames;
    inputStr = cat(2,appendedInputs{:});  
    linkCode = '';
    pt = internal.matlab.plotstab.PlotsTabState.getInstance();        
    shouldLink =  pt.AutoLinkData;
    if (shouldLink)
        if (n == 1)
            linkCode = sprintf(',YDataSource = ''%s''', inputnames{n});
        elseif (n > 1)
            linkCode = sprintf(',XDataSource = ''%s'',YDataSource = ''%s''', inputnames{1}, inputnames{2});
        end
    end
    dispStr = '';
    holdStr = 'hold on;';
    switch lower(fname)
        case {'plot','semilogx','semilogy','loglog','stem',...
                'stairs'}
            if (n==1 && (isBasicVector(inputvals{1}) || isa(inputvals{1},'timeseries') || ...
                    isa(inputvals{1},'fints') || isdatetime(inputvals{1})  )) || ... 
                    (n>=2 && isvector(inputvals{2})) || isa(inputvals{1}, 'Simulink.SimulationData.Dataset') 
                dispStr =  [lower(fname) '(' inputStr linkCode ')'];              
            elseif isa(inputvals{1}, 'Simulink.SimulationOutput')
                % Plot the SimulationOutput object in the sdi viewer
                dispStr = ['Simulink.sdi.internal.openVariable('''  inputStr ''', ' inputStr ')'];
            else
                dispStr =  [lower(fname) '(' inputStr ',''DisplayName'',''' ...
                  inputnames{n} '''' linkCode ')']; 
            end
            
        case {'area','bar','barh'}
            if (n==1 && (isBasicVector(inputvals{1}) || isa(inputvals{1},'timeseries') || ...
                    isa(inputvals{1},'fints') || isdatetime(inputvals{1})))
                dispStr =  [lower(fname) '(' inputStr linkCode ')'];
            elseif (n==2 && (isvector(inputvals{2}) && isdatetime(inputvals{2}) ||...
                    isduration(inputvals{2})))
                % If the second argument is a datetime, swap them since
                % area, bar and barh expect datetimes as first argument                
                dispStr =  [lower(fname) '(' inputnames{2} ',' inputnames{1}...
                    ',''DisplayName'',''' inputnames{1} '''' linkCode ')'];                
            else
                dispStr =  [lower(fname) '(' inputStr ',''DisplayName'',''' ...
                    inputnames{n} '''' linkCode ')'];
            end
        case {'graph','digraph'}
            dispStr =  ['plot(' inputStr ')'];
        case {'scatter', 'swarmchart'}
           if n==1
               % if the selection has parens, i.e. it is a subselect
               % Parse the string to find the rows and columns so
               % we can plot them as column vectors
               idx = regexpi(inputnames{1},'\((?!.*\().*\)');
               if length(idx)==1
                   % Cell array selection start with cell2mat
                   isCellSelection = startsWith(inputnames{1}, 'cell2mat(');
                   
                   % Get the name of the variable to plot
                   if isCellSelection
                       varName = char(extractBetween(inputnames{1}, 'cell2mat(', '('));
                   else
                       varName = char(extractBefore(inputnames{1}, idx));
                   end
                   hasReshape = contains(inputnames{1}, 'reshape');
                   if hasReshape
                        varName = strrep(varName, 'reshape(', '');
                        commaVals = strsplit(inputnames{1},",");
                        reshapeRowlength = char(commaVals(end-1));
                   end
                   
                   % extractBetween will get the logicl indices for us to
                   % parse
                   args = extractBetween(inputnames{1}, [varName '('], ')');
                   
                   % Seperate the row indices from the columns
                   % e.g. [1,3],[2,end]
                   if length(strfind(string(args),"[")) > 1
                       rowArgs = extractBetween(args, '[', '],', 'Boundaries', 'inclusive');
                       rowArgs = char(rowArgs{1});
                       rowArgs = char(strip(rowArgs, "right", ','));
                       rowArgs = [char(extractBefore(args,'[')) rowArgs];
                       colArgs = char(extractAfter(args, '],'));
                   else
                       rowSep = strfind(string(args),",");
                       leftBracketLocation = strfind(string(args),"[");
                       if isempty(leftBracketLocation)
                           leftBracketLocation = -inf;
                       end
                       colonLocation = min(strfind(string(args),":"));

                       if leftBracketLocation < colonLocation
                           bracketLocation = strfind(string(args),"]");
                           if isempty(bracketLocation)
                               bracketLocation = min(strfind(string(args),":"));
                               if isempty(bracketLocation)
                                   bracketLocation = 0;
                               end
                           end
                       else
                           bracketLocation = colonLocation;
                       end
                       if ~isscalar(rowSep)
                           rowSep = min(rowSep(rowSep > bracketLocation));
                       end

                       rowArgs = char(extractBefore(args, rowSep));
                       colArgs = char(extractAfter(args, rowSep));
                   end

                   % Find the individual columns 
                   caBefore = '';
                   caAfter = '';
                   if contains(colArgs, ']')
                       [cols, ~] = strsplit(char(extractBetween(colArgs, '[', ']')), {',', ':'});
                       if isempty(cols{1}) && isempty(cols{2})
                           cols{1} = '1';
                           cols{2} = '2';
                       end
                       caBefore = extractBefore(colArgs, '[');
                       caAfter = extractAfter(colArgs, ']');
                   elseif contains(colArgs, ':')
                       colIdx = strfind(colArgs, ':');
                       commaLocations = strfind(string(colArgs),",");
                       commaBefore = max(commaLocations(commaLocations<colIdx));
                       commaAfter = min(commaLocations(commaLocations>colIdx));
                       caBefore = '';
                       caAfter = '';
                       if isempty(commaBefore)
                           commaBefore = 0;
                       else
                           caBefore = colArgs(1:commaBefore);
                       end
                       if isempty(commaAfter)
                           commaAfter = length(colArgs)+1;
                       else
                           caAfter = colArgs(commaAfter:end);
                       end

                       colText = char(extractBetween(colArgs, commaBefore+1, commaAfter-1));
                       if colText == ':'
                           cols{1} = '1';
                           cols{2} = '2';
                       else
                           [cols, ~] = strsplit(colText, {',', ':'});
                       end
                   else
                       [cols, ~] = strsplit(char(colArgs), ',');
                   end

                   % If the columns are contiguous e.g. 2:3
                   if isempty(cols{1})
                       cols = strsplit(colArgs, {',', ':'});
                       
                       % If it is empty at this point I have the special
                       % case where I only have 2 columns in my array
                       if isempty(cols{1}) && isempty(cols{2})
                           cols{1} = '1';
                           cols{2} = '2';
                       end
                   end
                   
                   % Build the code gen string
                   vectorStr1 = [varName '(' rowArgs ',' caBefore cols{1} caAfter ')'];
                   vectorStr2 = [varName '(' rowArgs ',' caBefore cols{2} caAfter ')'];

                   if hasReshape
                       vectorStr1 = ['squeeze(' vectorStr1 ')'];
                       vectorStr2 = ['squeeze(' vectorStr2 ')'];
                   end
                    if (shouldLink)   
                        linkCode = sprintf(',XDataSource = ''%s'',YDataSource = ''%s''', vectorStr1, vectorStr2);
                    end

                   if isCellSelection % TODO: fix this for linking
                       dispStr = [lower(fname) '(cell2mat(' vectorStr1 '),cell2mat(' vectorStr2 '))'];
                   else
                       dispStr = [lower(fname) '(' vectorStr1 ',' vectorStr2 linkCode ')'];
                   end
               else
                   xdata = [inputnames{1} '(:,1)'];
                   ydata = [inputnames{1} '(:,2)'];
                    if (shouldLink)   
                        linkCode = sprintf(',XDataSource = ''%s'',YDataSource = ''%s''', xdata, ydata);
                    end
                   dispStr =  [lower(fname) '(' xdata ',' ydata linkCode ')'];
               end
           else
                dispStr = [lower(fname) '(' inputStr linkCode ')'];
            end
        case 'bubblechart'
            if n==1
                dispStr = [lower(fname) '(' inputnames{1} '(:,1),' inputnames{1} '(:,2),' inputnames{1} '(:,3)' '' linkCode ')'];
            else
                dispStr = ['bubblechart(' inputStr linkCode ');'];
            end
        case 'barstacked'
             dispStr =  ['bar(' inputStr ',''stacked'',''DisplayName'',''' inputnames{1} '''' linkCode ')'];
        case 'barhstacked'
             dispStr =  ['barh(' inputStr ',''stacked'',''DisplayName'',''' inputnames{1} '''' linkCode ')'];
        case 'errorbarhorz'
             if (shouldLink)
                 if (n == 2)
                    linkCode = sprintf(' ,YDataSource = ''%s''', inputnames{1});
                 elseif (n > 2)
                    linkCode = sprintf(' ,XDataSource = ''%s'',YDataSource = ''%s''', inputnames{1}, inputnames{2});
                 end
             end
             dispStr =  ['errorbar(' inputStr ',''horizontal''',linkCode, ')'];
        case 'heatmap'
            if n == 4
                % heatmap(tbl, xvar, yvar, 'ColorVariable', cvar)
                dispStr =  ['heatmap(' inputnames{1} ',' inputnames{2} ',' inputnames{3} ',''ColorVariable'',' inputnames{4} ');'];
            else
                % heatmap(cdata)
                % heatmap(xdata, ydata, cdata)
                % heatmap(tbl, xvar, yvar)
                dispStr =  ['heatmap(' inputStr ');'];
            end
        case 'geoplot'
                dispStr =  ['geoplot(' inputStr ')'];
        case 'geoscatter'
                dispStr =  ['geoscatter(' inputStr ')'];
        case 'geobubble'
                % geobubble(tbl, latvar, lonvar)
                % geobubble(lat, lon)
                % geobubble(lat, lon, sizedata)
                % geobubble(lat, lon, sizedata, colordata)
                dispStr =  ['geobubble(' inputStr ');'];
        case 'plot as multiple series' 
            % if alternate ones are datetimes/duration objects then the
            % plot action command has to be in pairs.
            % Eg: (t1,x1,t2,x2,t3,x3) -> (t1,x1)(t2,x2)(t3,x3)
            isSpecialCase = 0;
            if n > 2 && mod(length(inputvals),2) == 0
                isSpecialCase = localPlotPairs(inputvals);
            end
            if isSpecialCase == 1
                if (shouldLink)                  
                    linkCode = sprintf(',XDataSource = ''%s'',YDataSource = ''%s''', inputnames{1}, inputnames{2});
                end
                dispStr = [dispStr sprintf('plot(%s,%s,''DisplayName'',''%s''%s);', ...
                    inputnames{1},inputnames{2},inputnames{2},linkCode) holdStr];
                for k=3:2:length(inputnames)
                    if (shouldLink)                  
                        linkCode = sprintf(',XDataSource = ''%s'',YDataSource = ''%s''', inputnames{k}, inputnames{k+1});
                    end
                    dispStr = [dispStr sprintf('plot(%s,%s,''DisplayName'',''%s''%s);',inputnames{k},inputnames{k+1},inputnames{k+1},linkCode)]; %#ok<AGROW>
                end
                dispStr = [dispStr,'hold off;'];
            else
                if (shouldLink)
                    linkCode = sprintf(',YDataSource = ''%s''', inputnames{1});
                end
                dispStr = [dispStr sprintf('plot(%s,''DisplayName'',''%s''%s);', ...
                    inputnames{1},inputnames{1}, linkCode) holdStr];
                for k=2:length(inputnames)
                    if shouldLink
                       linkCode = sprintf(',YDataSource = ''%s''', inputnames{k}); 
                    end
                    dispStr = [dispStr sprintf('plot(%s,''DisplayName'',''%s''%s);',inputnames{k},inputnames{k},linkCode)]; %#ok<AGROW>
                end
                dispStr = [dispStr,'hold off;'];
            end
        case 'plot as multiple series vs. first input'
            if length(inputnames)>=2
                for k=2:length(inputnames)
                    if (shouldLink)                  
                        linkCode = sprintf(',XDataSource = ''%s'',YDataSource = ''%s''', inputnames{1}, inputnames{k});
                    end
                    dispStr = [dispStr sprintf('plot(%s,%s,''DisplayName'',''%s''%s);',inputnames{1},inputnames{k},inputnames{k},linkCode)]; %#ok<AGROW>
                    if k==2
                        dispStr = [dispStr, holdStr]; %#ok<AGROW>
                    end
                end
                dispStr = [dispStr,'hold off;'];    
            end
        case 'plot selected columns'
              dispStr =  ['plot(' inputnames{1} linkCode ')'];
        case 'stackedplot'
              dispStr =  ['stackedplot(' inputStr ');'];             
        case 'wordcloud'
              dispStr =  ['wordcloud(' inputStr ');'];
        case 'scatterhistogram'
            if isa(inputvals{1},'tabular')
                if length(inputnames) == 3
                    dispStr =  ['scatterhistogram(' inputStr ');'];
                else
                    dispStr = ['scatterhistogram(' inputnames{1} ',' inputnames{2} ',' inputnames{3} ...
                        ',''GroupVariable'',' inputnames{4} ');'];
                end
            else
                if length(inputnames) == 3
                    dispStr = ['scatterhistogram(' inputnames{1} ',' inputnames{2} ',''GroupData'',' inputnames{3} ');'];
                else
                    dispStr = ['scatterhistogram(' inputnames{1} ',' inputnames{2} ');'];
                end
            end
        case 'parallelplot'
            if length(inputnames) == 1
                dispStr =  ['parallelplot(' inputStr ');'];
            else
                if isa(inputvals{1},'tabular')
                    dispStr = ['parallelplot(' inputnames{1} ',''GroupVariable'',' inputnames{2} ');'];
                else
                    dispStr = ['parallelplot(' inputnames{1} ',''GroupData'',' inputnames{2} ');'];
                end
            end
        case 'boxchart'
            if length(inputnames) == 1
                dispStr = ['boxchart(' inputnames{1} ');'];
            elseif length(inputnames) == 2
                dispStr = ['boxchart(' inputnames{1} ',' inputnames{2} ');'];
            elseif length(inputnames) == 3
                dispStr = ['boxchart(' inputnames{1} ',' inputnames{2} ',''GroupByColor'',' inputnames{3} ');'];
            end
        case 'violinplot'
            if length(inputnames) == 1
                dispStr = ['violinplot(' inputnames{1} ');'];
            elseif length(inputnames) == 2
                dispStr = ['violinplot(' inputnames{1} ',' inputnames{2} ');'];
            elseif length(inputnames) == 3
                dispStr = ['violinplot(' inputnames{1} ',' inputnames{2} ',''GroupByColor'',' inputnames{3} ');'];
            end
    end                    
    varargout{1} = dispStr;
elseif strcmp(action,'defaultlabel')
    n = length(inputnames);       
    lblStr = '';
    switch lower(fname)
        case 'plot'            
            if n==1 
                varname = inputnames{1};
                vardata = inputvals{1};
                if ismatrix(vardata) && (~isobject(vardata) || isdatetime(vardata) || isduration(vardata)) 
                    if length(regexpi(varname,'\(.*\)'))==1   
                        lblStr = getString(message('MATLAB:codetools:plotpickerfunc:PlotSelectedColumns'));
                    elseif min(size(vardata))>1
                        lblStr = getString(message('MATLAB:codetools:plotpickerfunc:PlotAllColumns'));
                    else
                        lblStr = [fname '(' varname ')'];
                    end
                else
                    lblStr = '';
                end
            else
                lblStr = '';
            end
        case 'scatter'
            if n==1 
                vardata = inputvals{1};
                varname = inputnames{1};
                if isBasicMatrix(vardata) && size(vardata,2)==2
                    if length(regexpi(varname,'\(.*\)'))==1  
                        lblStr = getString(message('MATLAB:codetools:plotpickerfunc:ScatterPlotForSelectedColumns'));
                    else
                        lblStr = [fname '(' varname '(:,1), ' varname '(:,2)' ')'];
                    end
                else
                    lblStr = '';
                end
            else
                lblStr = '';
            end
        case 'plot_multiseriesfirst'
            lblStr = getString(message('MATLAB:codetools:plotpickerfunc:PlotAsMultipleSeriesVsFirstInput'));
        case 'plot_multiseries' 
            lblStr = getString(message('MATLAB:codetools:plotpickerfunc:PlotAsMultipleSeries'));
    end
    varargout{1} = lblStr;
% Return all the class names for the specified object
elseif strcmp(action,'getclassnames')
    h = inputvals;
    
    % Cache the lasterror state
    errorState = lasterror; %#ok<LERR,NASGU>
    
    try
        % Try mcos first
        if isobject(h)
           varargout{1} = [class(h);superclasses(h)];
           return;
        end

        % Now try UDD
        try 
            classH = classhandle(h);
        catch %#ok<CTCH>
            varargout{1} = {};
            return;
        end

        % There is no multiple inheritance in udd, so just ascend the class
        % hierarchy
        classArray = classH;
        while ~isempty(classH.Superclasses)
            classArray = [classArray;classH.Superclasses]; %#ok<AGROW>
            classH = classH.Superclasses;
        end
        classNames = get(classArray,{'Name'}); 
        for k=1:length(classArray)
            if ~isempty(classArray(k).Package)
                classNames{k} = sprintf('%s.%s',classArray(k).Package.Name,classNames{k});
            end
        end
        varargout{1} = classNames;
    catch %#ok<CTCH>
        % Prevent drooling of the lasterror state
        lasterror(errorstate); %#ok<LERR>
        varargout{1} = {};
    end
    
%end plotpickerfunc
end

function isUnique = isUniqueCategorical(x)
isUnique = false;

if iscategorical(x)
    uniqueCat = unique(x);
    if length(uniqueCat) == length(x)
        isUnique = true;
    end
end

function status = localIsVector(x)
status = (isnumeric(x) || islogical(x)) && ~isscalar(x) && isvector(x) && ~isobject(x);
if (isdatetime(x) || isduration(x))
    status = status || (~isscalar(x) && isvector(x));
end

function status = localIsMatrix(x)
status = (isnumeric(x) || islogical(x)) && ~isscalar(x) && ismatrix(x) && ...
     ~isobject(x) && min(size(x))>1;
if (isdatetime(x) || isduration(x) || iscategorical(x))
    status = status || (~isscalar(x) && ismatrix(x) && min(size(x))>1);
end

function toshow = localPlotArgFcn(inputvals)

x = inputvals{1};
y = inputvals{2};
toshow =  (isnumeric(x) && ~isscalar(x) && ndims(x)<=2 && isreal(x)) ||...
    isdatetime(x) || isduration(x) || iscategorical(x);
toshow =  toshow && (isnumeric(y) || islogical(y) || isdatetime(y) ||...
    iscategorical(y) || isduration(y)) && ~isscalar(y) && ...
    ndims(y)<=2 && xor(isreal(y),(isdatetime(y) || isduration(y) || iscategorical(y)));
% case where x is datetime and y is duration or vice versa is not valid 
toshow = toshow && ~(isdatetime(x) && isduration(y)) && ~(isdatetime(y) && isduration(x));
if toshow && (isdatetime(x) || isduration(x) || ~isBasicVector(x)) && (isdatetime(y) || isduration(y) || ~isBasicVector(y))
    toshow = any(ismember(size(x), size(y)));
elseif toshow && (isdatetime(x) || isduration(x) || ~isBasicVector(x))
    toshow = any(ismember(length(y), size(x)));
elseif toshow && (isdatetime(y) || isduration(y) || ~isBasicVector(y))
    toshow = any(ismember(length(x), size(y)));
elseif toshow
    toshow = length(x)==length(y);
end

function toshow = localAreaArgFcn(inputvals)

x = inputvals{1};
y = inputvals{2};
toshow =  isnumeric(x) && ~isscalar(x) && ndims(x)<=2 && isreal(x);
toshow =  toshow && (isnumeric(y) || islogical(y)) && ~isscalar(y) && ndims(y)<=2 && isreal(y);
if toshow && ~isBasicVector(x)
    toshow = isequal(size(x),size(y));
elseif toshow && isBasicVector(x)
    toshow = any(length(x)==size(y));
end

function toshow = localAreaCategoricalArgFcn(inputvals)

x = inputvals{1};
y = inputvals{2};
toshow = iscategorical(x) && ~isscalar(x) && ndims(x)<=2;
toshow = toshow && (isnumeric(y) || islogical(y)) &&...
    ~isscalar(y) && ndims(y)<=2 && isreal(y);
if toshow && ~isBasicVector(x)
    toshow = isequal(size(x),size(y));
elseif toshow && isBasicVector(x)
    toshow = any(length(x)==size(y));
end

function toshow = localAreaTimeArgFcn(inputvals)

x = inputvals{1};
y = inputvals{2};
toshow =  isnumeric(x) && ~isscalar(x) && ndims(x)<=2 && isreal(x) ||...
    ((isdatetime(x) || isduration(x) || isUniqueCategorical(x)) &&...
    ~isscalar(x) && ndims(x)<=2 );
toshow =  toshow && (isnumeric(y) || islogical(y)) && ~isscalar(y) &&...
    ndims(y)<=2 && isreal(y) ||...
    ((isdatetime(y) || isduration(y)) &&...
    ~isscalar(y) && ndims(y)<=2 );
if toshow && isdatetime(x) || isduration(x) || iscategorical(x)
    if toshow && ~isvector(x)
        toshow = isequal(size(x),size(y));
    elseif toshow && isvector(x)
        toshow = any(length(x)==size(y));
    end
else
    if toshow && ~isBasicVector(x)
        toshow = isequal(size(x),size(y));
    elseif toshow && isBasicVector(x)
        toshow = any(length(x)==size(y));
    end
end

function toshow = localBarNonNumArgFcn(inputvals)
x = inputvals{1}; % x can be numeric, datetime, duration, categorical, or a string array
y = inputvals{2}; % y can be numeric or duration
isXValid = ((isnumeric(x) && isreal(x)) || ...
    (isdatetime(x) || isduration(x) || isUniqueCategorical(x)|| isstring(x))) && ...
    ~isscalar(x) && ismatrix(x);
isYValid = ((isnumeric(y) && isreal(y)) || isduration(y)) && ...
    ~isscalar(y) && ismatrix(y);

% Ensure x and y have the same size or length
isSameSize = (numel(x) == numel(y)) || ...
    (size(x, 1) == size(y, 1) && size(y, 2) == 1) || ... % y is a column vector
    (size(y, 1) == size(x, 1) && size(x, 2) == 1) || ... % x is a column vector
    (size(x, 2) == size(y, 2) && size(y, 1) == 1) || ... % y is a row vector
    (size(y, 2) == size(x, 2) && size(x, 1) == 1);       % x is a row vector

toshow = isXValid && isYValid && isSameSize;

function plotPairs = localPlotPairs(inputvals)
% if the first entry is datetime or duration
if isdatetime(inputvals{1}) || isduration(inputvals{1})
    plotPairs = all(cellfun('isclass', inputvals(1:2:end),class(inputvals{1})));
    plotPairs = plotPairs && ~(any(cellfun('isclass', inputvals(2:2:end), 'datetime')));
    plotPairs = plotPairs && ~(any(cellfun('isclass', inputvals(2:2:end), 'duration')));
    % if the second entry is datetime or duration
elseif isdatetime(inputvals{2}) || isduration(inputvals{2})
    plotPairs = all(cellfun('isclass', inputvals(2:2:end),class(inputvals{2})));
    plotPairs = plotPairs && ~(any(cellfun('isclass', inputvals(1:2:end), 'datetime')));
    plotPairs = plotPairs && ~(any(cellfun('isclass', inputvals(1:2:end), 'duration')));
else
    plotPairs = 0;
end

function isgeocoords = isGeoCoordinates(latinputval, loninputval)
% Check if the inputs for latitude and longitude
% are a valid vector coordinate pair.

vectorInput = isBasicVector(latinputval) && isBasicVector(loninputval);

if isnumeric(latinputval) && isnumeric(loninputval) && vectorInput
    latinrange = max(latinputval) < 90 && min(latinputval) > -90;
    loninrange = max(loninputval) < 360 && min(loninputval) > -360;
    lengthsequal = length(latinputval) == length(loninputval);
    
    isgeocoords = latinrange && loninrange && lengthsequal;
else
    isgeocoords = false;
end

function isbasicmatrix = isBasicMatrix(inputval)
isbasicmatrix = ismatrix(inputval) && ~isobject(inputval);

function isbasicvector = isBasicVector(inputval)
isbasicvector = isvector(inputval) && ~isobject(inputval);

function isfn = isFunctionOrSym(inputval, nargs)
isfn = (isa(inputval,'function_handle') && nargin(inputval)==nargs) || ...
    (isa(inputval,'sym') && numel(symvar(inputval))==nargs);

function isrange = isRangeVector(range)
isrange = isnumeric(range) && isBasicVector(range) && ...
    length(range)==2 && range(2)>range(1);

function isrange = isRangeVector4(range)
isrange = isnumeric(range) && isBasicVector(range) && ...
    length(range)==4 && range(2)>range(1) && range(4)>range(3);

function isrange = isRangeVector6(range)
isrange = isnumeric(range) && isBasicVector(range) && ...
    length(range)==6 && range(2)>range(1) && range(4)>range(3) && range(6)>range(5);

function issubscript = isScalarTableSubscript(tbl, subscript)
% Check if 'subscript' is a valid table subscript which refers to a single
% column in 'tbl'.

issubscript = ~isempty(matlab.graphics.chart.internal.validateTableSubscript(tbl, subscript));
