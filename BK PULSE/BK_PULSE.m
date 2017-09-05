%
%  BK_PULSE.m
%
%  Created by Léa Strobino
%  Copyright 2017 hepia. All rights reserved.
%

classdef BK_PULSE < matlab.mixin.SetGet
  
  properties (SetAccess = private)
    App
    Version
    Project
    ConfigurationOrganiser
    MeasurementOrganiser
    FunctionOrganiser
    DisplayOrganiser
    TaskOrganiser
    Template
    Setup
  end
  
  methods
    
    function this = BK_PULSE()
      try
        this.App = COM.Pulse_Labshop_Application('server','','IDispatch');
        set(this.App,'WindowState','bkWindowStateMaximize','Visible',true);
      catch e
        switch e.identifier
          case 'MATLAB:COM:servercreationfailed'
            [~,~] = dos('taskkill /F /IM Pulse.exe');
            error('BK_PULSE:LicenseNotFound','No license found for Brüel & Kjær PULSE LabShop.');
          otherwise
            rethrow(e);
        end
      end
    end
    
    function delete(this)
      try %#ok<TRYNC>
        delete(this.App);
      end
    end
    
    function v = get.Version(this)
      v = regexp(this.App.Name,'Version ([\d\.]+)','tokens','once');
      v = v{1};
    end
    
    function o = get.Project(this)
      o = this.App.Project;
    end
    
    function o = get.ConfigurationOrganiser(this)
      o = this.Project.ConfigurationOrganiser;
    end
    
    function o = get.MeasurementOrganiser(this)
      o = this.Project.MeasurementOrganiser;
    end
    
    function o = get.FunctionOrganiser(this)
      o = this.Project.FunctionOrganiser;
    end
    
    function o = get.DisplayOrganiser(this)
      o = this.Project.DisplayOrganiser;
    end
    
    function o = get.TaskOrganiser(this)
      o = this.Project.TaskOrganiser;
    end
    
    function o = get.Template(this)
      o = invoke(this.MeasurementOrganiser,'GetActiveMeasurementTemplate');
    end
    
    function o = get.Setup(this)
      o = get(this.Template,'Setup');
    end
    
    function openProject(this,filename,ForceOpen)
      [path,name,ext] = fileparts(filename);
      if isempty(path)
        path = cd();
      end
      if isempty(ext)
        ext = '.pls';
      end
      filename = fullfile(path,[name ext]);
      h = fopen(filename);
      if h > 0
        fclose(h);
        if nargin == 3 && ~ForceOpen
          try %#ok<TRYNC>
            if strcmpi(this.Project.FullName,filename)
              return
            end
          end
        end
        invoke(this.App,'OpenProject',filename,true,false);
      else
        error('BK_PULSE:FileNotFound','"%s": no such file.',filename);
      end
    end
    
    function closeProject(this)
      invoke(this.App,'CloseProject',true);
    end
    
    function newProject(this,ForceClose)
      if nargin < 2
        ForceClose = true;
      end
      invoke(this.App,'NewProject',logical(ForceClose));
    end
    
    function saveProject(this,filename)
      if nargin < 1
        invoke(this.App,'SaveProject');
      else
        [path,name,ext] = fileparts(filename);
        if isempty(path)
          path = cd();
        end
        if ~strcmpi(ext,'.pls')
          ext = [ext '.pls'];
        end
        filename = fullfile(path,[name ext]);
        invoke(this.App,'SaveProjectAs',filename);
      end
    end
    
    function activate(this)
      invoke(this.App,'ActivateTemplate');
    end
    
    function autorange(this)
      invoke(this.App,'Autorange');
    end
    
    function startGenerator(this)
      invoke(this.App,'StartGenerator');
    end
    
    function stopGenerator(this)
      invoke(this.App,'StopGenerator');
    end
    
    function startMeasurement(this)
      invoke(this.App,'Start');
    end
    
    function stopMeasurement(this)
      invoke(this.App,'Stop');
    end
    
    function m = saveMeasurement(this,MeasurementName)
      input = get(this.Template,'Measurement',int32(0));
      if nargin < 2
        invoke(input,'SaveMeasurement');
      else
        m = invoke(input,'SaveNamedMeasurement',MeasurementName);
      end
    end
    
    function m = getMeasurement(this,MeasurementName,FunctionGroupName,FunctionName,filename)
      persistent template environment functions
      try
        if isempty(get(template,'Name'))
          error('MATLAB:COM:E0','');
        end
      catch
        template = this.Template;
        environment = uint8(sprintf('Ambient Pressure:\t%g\r\nTemperature:\t%g\r\nNominal Spacing:\t%g\r\n',...
          get(this.Setup,'AmbientPressure'),get(this.Setup,'Temperature'),get(this.Setup,'NominalSpacing')));
        functions = struct();
      end
      if nargin < 4 || isempty(FunctionName)
        FunctionName = FunctionGroupName;
        FunctionGroupName = int32(1);
      end
      FunctionFullName = matlab.lang.makeValidName(['F' FunctionGroupName FunctionName],'ReplacementStyle','hex');
      if ~isfield(functions,FunctionFullName)
        functions.(FunctionFullName) = get(get(this.FunctionOrganiser,'FunctionGroups',FunctionGroupName),'Functions',FunctionName);
        if ~isempty(MeasurementName)
          try %#ok<TRYNC>
            functions.(FunctionFullName).MeasurementMark = 'Current';
          end
        end
      end
      if ~isempty(MeasurementName)
        if ~ischar(MeasurementName)
          MeasurementName = int32(MeasurementName);
        end
        measurement = get(template,'Measurement',MeasurementName);
        invoke(measurement,'MakeCurrent');
        try
          get(functions.(FunctionFullName),'FunctionData');
        catch
          invoke(measurement,'MakeCurrent');
        end
      end
      tmp = [tempname() '.txt'];
      invoke(functions.(FunctionFullName),'Export',tmp,0);
      h = fopen(tmp,'a');
      fprintf(h,'\r\n%s',environment);
      fclose(h);
      m = read_pulse_file_ascii(tmp);
      if nargin > 4
        [path,name,ext] = fileparts(filename);
        if isempty(path)
          path = cd();
        end
        name = strrep(name,'{MeasurementName}',m.MeasurementName);
        if isempty(ext)
          ext = '.txt';
        end
        filename = fullfile(path,[name ext]);
        movefile(tmp,filename);
      else
        delete(tmp);
      end
    end
    
    function [LowerCentreFrequency,UpperCentreFrequency] = setCPBAnalyzer(this,LowerFrequency,UpperFrequency,analyzer)
      if nargin < 4
        analyzer = 'CPB Analyzer';
      end
      CPBAnalyzer = get(this.Setup,'Instruments',analyzer);
      set(CPBAnalyzer,'LowerCentreFrequency',LowerFrequency);
      set(CPBAnalyzer,'UpperCentreFrequency',UpperFrequency);
      set(CPBAnalyzer,'LowerCentreFrequency',LowerFrequency);
      if nargout > 0
        LowerCentreFrequency = get(CPBAnalyzer,'LowerCentreFrequency');
        if any(LowerCentreFrequency == 'k')
          LowerCentreFrequency = 1E3*sscanf(LowerCentreFrequency,'%f');
        elseif any(LowerCentreFrequency == 'm')
          LowerCentreFrequency = 1E-3*sscanf(LowerCentreFrequency,'%f');
        else
          LowerCentreFrequency = sscanf(LowerCentreFrequency,'%f');
        end
      end
      if nargout > 1
        UpperCentreFrequency = get(CPBAnalyzer,'UpperCentreFrequency');
        if any(UpperCentreFrequency == 'k')
          UpperCentreFrequency = 1E3*sscanf(UpperCentreFrequency,'%f');
        elseif any(UpperCentreFrequency == 'm')
          UpperCentreFrequency = 1E-3*sscanf(UpperCentreFrequency,'%f');
        else
          UpperCentreFrequency = sscanf(UpperCentreFrequency,'%f');
        end
      end
    end
    
    function [CentreFrequency,FrequencySpan] = setGeneratorBandPass(this,frequency,bandwidth,signal)
      if nargin < 4
        signal = 'Generator 1';
      end
      generator = get(get(this.Setup,'Instruments','Generator'),'Signals',signal);
      bandwidth = frequency*(2^(bandwidth/2)-2^-(bandwidth/2));
      [~,i] = min(abs(bandwidth - [3.125 6.25 12.5 25 50 100 200 400 800 1600 3200 6400 12800 25600]));
      FrequencySpan = {'3.125 Hz','6.25 Hz','12.5 Hz','25 Hz','50 Hz','100 Hz','200 Hz','400 Hz','800 Hz','1.6 kHz','3.2 kHz','6.4 kHz','12.8 kHz','25.6 kHz'};
      set(generator,'CentreFrequency',frequency);
      set(generator,'FrequencySpan',FrequencySpan{i});
      if nargout > 0
        CentreFrequency = get(generator,'CentreFrequency');
      end
      if nargout > 1
        FrequencySpan = get(generator,'FrequencySpan');
        if any(FrequencySpan == 'k')
          FrequencySpan = 1E3*sscanf(FrequencySpan,'%f');
        else
          FrequencySpan = sscanf(FrequencySpan,'%f');
        end
      end
    end
    
  end
  
end
