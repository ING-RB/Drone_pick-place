function updateProps(this,OptionsBox)
% Updates the Java Dialog based on the Data property of the EditBox.

%  Copyright 1986-2011 The MathWorks, Inc.

  
s = internal.getJavaCustomData(OptionsBox.GroupBox);
Data = OptionsBox.Data; PropChanged = fieldnames(Data);
for ct = 1:length(PropChanged)
    switch PropChanged{ct}
        case 'TimeUnits'      
            idx  = find(strcmp(s.ValidTimeUnits,OptionsBox.Data.TimeUnits))-1;
            s.TimeUnits.setSelectedIndex(idx);
        case  'FrequencyUnits'
            idx  = find(strcmp(s.ValidFrequencyUnits,OptionsBox.Data.FrequencyUnits))-1;
            s.FrequencyUnits.setSelectedIndex(idx);
        case  'MagnitudeUnits'
            if strcmpi(OptionsBox.Data.MagnitudeUnits(1),'d')
                Data.MagnitudeScale = 'linear';
                s.MagnitudeScale.setSelectedIndex(strcmpi(Data.MagnitudeScale,'log'));
                s.MagnitudeUnits.setSelectedIndex(0);
                awtinvoke(s.MagnitudeScalePanel,'setVisible(Z)',false);
            else
                s.MagnitudeUnits.setSelectedIndex(1);
                awtinvoke(s.MagnitudeScalePanel,'setVisible(Z)',true);
            end
        case 'PhaseUnits'
            s.PhaseUnits.setSelectedIndex(strcmpi(OptionsBox.Data.PhaseUnits(1),'r'));
        case 'MagnitudeScale'
            s.MagnitudeScale.setSelectedIndex(strcmpi(OptionsBox.Data.MagnitudeScale,'log'));
        case 'FrequencyScale'
            s.FrequencyScale.setSelectedIndex(strcmpi(OptionsBox.Data.FrequencyScale,'log'));
    end
end
OptionsBox.Data = Data;