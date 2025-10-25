function varargout = signalplotfunc(action,fname,inputnames,inputvals)
%PLOTPICKERFUNC  Support function for Plot Picker component.

% Copyright 2009-2024 The MathWorks, Inc.

% Default display functions for MATLAB plots
if strcmp(action,'defaultshow')
    n = length(inputvals);
    toshow = false;
    % A single empty should always return false
    if isempty(inputvals) ||  isempty(inputvals{1}) 
        varargout{1} = false;
        return
    end
    
    if ~unsupportedObjectSelection(inputvals, n)
      switch lower(fname)
          % Either a sigwin object or one or more windows vectors specified using winname
        case 'wvtool'
          x = inputvals{1};
          if n==1
            toshow = isa(x,'sigwin.window') || ...
              (isnumeric(x) && isvector(x) && ~isscalar(x));
          else
            toshow = all(cellfun(@(x) isnumeric(x) && isvector(x) && ~isscalar(x),...
              inputvals));
          end
          % A numeric vector or matrix. Optionally add either a positive integer
          % or between 2 and 3 positive scalars.
        case 'strips'
          x = inputvals{1};
          toshow = isnumeric(x) && ~isscalar(x) && ismatrix(x);
          if toshow && n > 1
            if n > 4
              toshow = false;
            elseif n == 2
              n1 = inputvals{2};
              toshow = isnumeric(n1) && isscalar(n1) && round(n1)==n1;
            else
              sd = inputvals{2};
              fs = inputvals{3};
              toshow = isnumeric(sd) && isnumeric(fs) && isscalar(sd) && ...
                isscalar(fs) && sd>0 && fs>0;
              if n==4 && toshow
                scale = inputvals{4};
                toshow = isnumeric(scale) && isscalar(scale) && ...
                  scale>0;
              end
            end
          end
          
          % A pair of numerator-denominator vectors followed by either: i.) a frequency
          % vector with 2 or more entries; or ii.) a real scalar value indicating
          % the number of frequency points.
        case 'freqs'
          if n==3
            num = inputvals{1};
            den = inputvals{2};
            w = inputvals{3};
            toshow = isnumeric(num) && isnumeric(den) && isvector(num) && ...
              isvector(den) && isnumeric(w) && isvector(w);
          end
          % Numerator or A pair of numerator-denominator vectors. Optionally add a
          % scalar or vector of integers and a positive scalar.
          % Either a dfilt object, digitalFilter or supported DSP system Object
        case {'impz','stepz','freqz'}
           if n == 1
            num = inputvals{1};
            toshow = isValidFilterInput(fname,num);
           elseif n<=4
            num = inputvals{1};
            den = inputvals{2};
            toshow = isValidFilterInput(fname,num,den);
            if toshow && n>=3
              n1 = inputvals{3};
              toshow = isnumeric(n1) && isvector(n1) && all(n1==round(n1));
              if toshow && n==4
                fs = inputvals{4};
                toshow = isnumeric(fs) && isscalar(fs) && fs>0;
              end
            end
          end
          % A pair of numerator-denominator vectors. Optionally add a
          % real scalar or vector and a positive scalar.
        case {'grpdelay','phasedelay','phasez'}
           if n == 1
            num = inputvals{1};
            toshow = isValidFilterInput(fname,num);
           elseif n<=4
            num = inputvals{1};
            den = inputvals{2};
            toshow = isValidFilterInput(fname,num,den);
            if toshow && n>=3
              w = inputvals{3};
              toshow = isnumeric(w) && isvector(w);
              if toshow && n==4
                fs = inputvals{4};
                toshow = isnumeric(fs) && isscalar(fs) && fs>0;
              end
            end
          end
          % A pair of numerator-denominator vectors. Optionally add
          % real scalar or vector.
        case 'zerophase'
          if n == 1
            num = inputvals{1};
            toshow = isValidFilterInput(fname,num);
          elseif n<=3
            num = inputvals{1};
            den = inputvals{2};
            toshow = isValidFilterInput(fname,num,den);
            if toshow && n>=3
              w = inputvals{3};
              toshow = isnumeric(w) && isvector(w);
            end
          end
          % A pair row vectors or column vectors or a
          % dfilt object
        case 'zplane'
          if n==1
            toshow = isValidFilterInput(fname,inputvals{1});
          elseif n==2
            z = inputvals{1};
            p = inputvals{2};
            toshow = isnumeric(z) && isnumeric(p) && isvector(z) && ...
              isvector(p) && ((size(z,1)==1 && size(p,1)==1) || ...
              (size(z,2)==1 && size(p,2)==1));
            toshow = toshow || isValidFilterInput(fname,inputvals{1},inputvals{2});
          end
          % A pair of matrices of the same dimensions. Optionally add a scalar
          % or numeric vector and a positive integer.
        case {'cpsd','mscohere'}
          if n>=2 && n<=3
            x = inputvals{1};
            y = inputvals{2};
            toshow = isnumeric(x) && isnumeric(y) && ismatrix(x) && ...
              ismatrix(y) && ~isscalar(x) && ...
              (isvector(x) && isvector(y) && length(x)==length(y) || ...
              isequal(size(x),size(y)));
            if toshow && n>=3
              window = inputvals{3};
              toshow = isnumeric(window) && isvector(window);
              if toshow && n==4
                nooverlap = inputvals{4};
                toshow = isnumeric(nooverlap) && isscalar(nooverlap) && ...
                  nooverlap>0 && round(nooverlap)==nooverlap;
              end
            end
          end
          % A numeric matrix.  Optionally add in order:
          %    i.) a positive time-bandwidth product
          %   ii.) a positive sample rate
        case 'pmtm'
          if n>=1 && n<=3
            x = inputvals{1};
            toshow = isnumeric(x) && ~isscalar(x) && ismatrix(x);
            if n>1
              p = inputvals{2};
              toshow = toshow && isscalar(p) && isnumeric(p) && p>0;
            end
            if n>2
              fs = inputvals{3};
              toshow = toshow && isscalar(fs) && isnumeric(fs) && fs>0;
            end
          end
          % A numeric vector.  Optionally add in order:
          %     i.) an integer number of complex sinusoids
          %    ii.) a positive sample rate
        case {'peig','pmusic'}
          if n>=1 && n<=3
            x = inputvals{1};
            toshow = isnumeric(x) && ~isscalar(x) && isvector(x);
            if n>1
              p = inputvals{2};
              toshow = toshow && isscalar(p) && isnumeric(p) && ...
                round(p)==p;
            end
            if n>2
              fs = inputvals{3};
              toshow = toshow && isscalar(fs) && isnumeric(fs) && fs>0;
            end
          end
          % A numeric matrix.  Optionally add in order:
          %     i.) an integer order of the autoregressive model
          %    ii.) a positive sample rate
        case {'pburg','pcov','pmcov','pyulear'}
          if n>=1 && n<=3
            x = inputvals{1};
            toshow = isnumeric(x) && ~isscalar(x) && ismatrix(x);
            if n>1
              p = inputvals{2};
              toshow = toshow && isscalar(p) && isnumeric(p) && ...
                round(p)==p;
            end
            if n>2
              fs = inputvals{3};
              toshow = toshow && isscalar(fs) && isnumeric(fs) && fs>0;
            end
          end
          % A numeric matrix.  Optionally add a positive sample rate
        case {'periodogram_psd','periodogram_power','pwelch_psd','pwelch_power'}
          if n>=1 && n<=2
            x = inputvals{1};
            toshow = isnumeric(x) && ~isscalar(x) && ismatrix(x);
          end
          if n>1
            fs = inputvals{2};
            toshow = toshow && isscalar(fs) && isnumeric(fs) && fs>0;
          end
          
          % A numeric vector. Optionally add in order:
          %     i.) a numeric vector
          %    ii.) a numeric vector or integer>1
          %   iii.) a numeric scalar nonnegative integer
          %   iiii.) a numeric scalar positive integer
          case 'spectrogram'
              if n >= 1 && n <= 4
                  % Case: spectrogram(x)
                  x = inputvals{1};
                  toshow = isnumeric(x) && ~isscalar(x) && isvector(x);
                  % Case: spectrogram(x,window)
                  if toshow && n >= 2
                      w = inputvals{2};
                      toshow = ((isnumeric(w) && isvector(w) && ~isscalar(w)) || ...
                          (isscalar(w) && round(w) == w && w > 1));
                      % Case: spectrogram(x,window,noverlap)
                      if toshow && n >= 3
                          noOvrl = inputvals{3};
                          toshow = isnumeric(noOvrl) && isscalar(noOvrl) && noOvrl >= 0 && floor(noOvrl) == noOvrl;
                          % Case: spectrogram(x,window,noverlap,nfft)
                          if toshow && n == 4
                              nfft = inputvals{4};
                              toshow = isnumeric(nfft) && isscalar(nfft) && nfft > 0 && floor(nfft) == nfft;
                          end
                      end
                  end
              end
          % A pair of matrices of the same dimension. Optionally add in order:
          % i.) a numeric vector or integer>1
          % ii.) 1 or 2 positive integers
          % iii.) a numeric scalar
        case 'tfestimate'
          if n>=2 && n<=5
            x = inputvals{1};
            y = inputvals{2};
            toshow = isnumeric(x) && ~isscalar(x) && ismatrix(x) && ...
              isnumeric(y) && ismatrix(y) && ...
              (isvector(x) && isvector(y) && length(x)==length(y) || ...
              isequal(size(x),size(y)));
            if toshow && n>=3
              nooverlap = inputvals{3};
              toshow = isnumeric(nooverlap) && isscalar(nooverlap) && ...
                round(nooverlap)==nooverlap && nooverlap>0;
              if toshow && n>=4
                nfft = inputvals{4};
                toshow = isnumeric(nfft) && isscalar(nfft) && ...
                  round(nfft)==nfft && nfft>0;
                if toshow && n==5
                  fs = inputvals{5};
                  toshow = isnumeric(fs) && isscalar(fs) && ...
                    fs>0;
                end
              end
            end
          end
      end
    end
    varargout{1} = toshow;
elseif strcmp(action,'defaultdisplay')
    dispStr = '';
    switch lower(fname)
        case {'freqz','phasez','grpdelay','phasedelay','impz','stepz','zplane','zerophase'}
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];
            dispStr = [fname '(' inputNameArray{1:end-1}];
            if ~ismethod(inputvals{1},fname)
                dispStr = [dispStr ',''ctf'''];
            end
            dispStr = [dispStr ');'];
        case 'wvtool'
            inputNameArray = [inputnames(:)';repmat({','},1,length(inputnames))];
            dispStr = ['wvtool(' inputNameArray{1:end-1} ');'];
        case {'pburg','pcov','pmcov','pmtm','pyulear'}
            if isscalar(inputnames)
               dispStr = sprintf('%s(%s, 4);figure(gcf)',fname,inputnames{1});
            elseif length(inputnames)==2
               dispStr = sprintf('%s(%s,%s);figure(gcf)',fname,inputnames{1},...
                   inputnames{2});
            elseif length(inputnames)==3
               dispStr = sprintf('%s(%s,%s,[],%s);figure(gcf)',fname,inputnames{1},...
                   inputnames{2},inputnames{3});
            end 
        case {'peig','pmusic'}    
            if isscalar(inputnames)
               dispStr = sprintf('%s(%s,8);figure(gcf)',fname,inputnames{1});
            elseif length(inputnames)==2
               dispStr = sprintf('%s(%s,%s);figure(gcf)',fname,inputnames{1},...
                   inputnames{2});
            elseif length(inputnames)==3
               dispStr = sprintf('%s(%s,%s,[],%s);figure(gcf)',fname,inputnames{1},...
                   inputnames{2},inputnames{3});
            end
        case {'periodogram_psd','periodogram_power'}
            suffixStr = powerSuffix(fname);          
            if isscalar(inputnames)
               dispStr = sprintf('periodogram(%s%s);figure(gcf)',inputnames{1},suffixStr);
            elseif length(inputnames)==2
               dispStr = sprintf('periodogram(%s,[],[],%s%s);figure(gcf)',inputnames{1},inputnames{2},suffixStr);
            end
        case {'pwelch_psd','pwelch_power'}
            suffixStr = powerSuffix(fname);          
            if isscalar(inputnames)
               dispStr = sprintf('pwelch(%s%s);figure(gcf)',inputnames{1},suffixStr);
            elseif length(inputnames)==2
               dispStr = sprintf('pwelch(%s,[],[],[],%s%s);figure(gcf)',inputnames{1},inputnames{2},suffixStr);
            end
    end
    varargout{1} = dispStr;   
elseif strcmp(action,'defaultlabel')   
    lblStr = '';
    switch lower(fname)  
        case {'pburg','pcov','pmcov','pmtm','pyulear'}
            if isscalar(inputnames)
               lblStr = sprintf('%s(%s,4);',fname,inputnames{1});
            elseif length(inputnames)==2
               lblStr = sprintf('%s(%s,%s);',fname,inputnames{1}, inputnames{2});
            elseif length(inputnames)==3
               lblStr = sprintf('%s(%s,%s,[],%s);',fname,inputnames{1},inputnames{2},inputnames{3});
            end
        case {'peig','pmusic'}
            if isscalar(inputnames)
               lblStr = sprintf('%s(%s,8);',fname,inputnames{1});
            elseif length(inputnames)==2
               lblStr = sprintf('%s(%s,%s);',fname,inputnames{1}, inputnames{2});
            elseif length(inputnames)==3
               lblStr = sprintf('%s(%s,%s,[],%s);',fname,inputnames{1},inputnames{2},inputnames{3});
            end
        case {'periodogram_psd','periodogram_power'}
            suffixStr = powerSuffix(fname);
            if isscalar(inputnames)
               lblStr = sprintf('periodogram(%s%s);',inputnames{1},suffixStr);
            elseif length(inputnames)==2
               lblStr = sprintf('periodogram(%s,[],[],%s%s);',inputnames{1}, inputnames{2}, suffixStr);
            end
        case {'pwelch_psd','pwelch_power'}
            suffixStr = powerSuffix(fname);
            if isscalar(inputnames)
               lblStr = sprintf('pwelch(%s%s);',inputnames{1},suffixStr);
            elseif length(inputnames)==2
               lblStr = sprintf('pwelch(%s,[],[],[],%s%s);',inputnames{1}, inputnames{2}, suffixStr);
            end
    end
    varargout{1} = lblStr;
end
end

function suffixStr = powerSuffix(fname)
if strcmpi(fname(end-4:end),'power')
  suffixStr = ',''power''';
else
  suffixStr = '';
end
end

% function returns true if an unsupported type like datetime, duration or
% calendarDuration is selected in the Workspace Browser
function unsupportedObject = unsupportedObjectSelection(inputvals, n)
unsupportedObject = false;
for k = 1:n
    if isdatetime(inputvals{k}) || isduration(inputvals{k}) || iscalendarduration(inputvals{k})
        unsupportedObject = true;
    end
end
end

function toshow = isValidFilterInput(fname,num,den)
if nargin < 3
    toshow = ismethod(num,fname) || ...
        (isreal(num) && isnumeric(num) && ismatrix(num));
else
    toshow = all(den(:,1)~=0) && ...
        allfinite(num) && allfinite(den) && ...
        isnumeric(num) && isnumeric(den);
    if toshow && (ismatrix(num) || ismatrix(den))
        % If either num and den are not scalar, then they both need to be
        % vectors or matrices with same height.
        toshow = isscalar(num) || isscalar(den) || (isvector(num) && isvector(den)) || height(num) == height(den);
    end
end
end
