%
% AP2700.m
%
% Created by L�a Strobino
% Copyright 2016 hepia. All rights reserved.
%

classdef AP2700 < matlab.mixin.SetGet
  
  properties (SetAccess = private)
    Anlr
    App
    Aux
    BarGraph
    Bits
    CommA
    CommB
    Compute
    Data
    DCX
    DGen
    Events
    File
    Gen
    Graph
    IEC61937
    Log
    Macro
    Print
    Prompt
    PSIA
    Reg
    S2CDio
    S2CDsp
    Speaker
    Sweep
    SWR
    Sync
    SysType
    TestFile
    Version
  end
  
  properties (Access = private)
    AP
    cache
  end
  
  methods
    
    function this = AP2700()
      persistent retry
      try
        this.AP = COM.AP2700_Application('server','','IDispatch');
        this.SysType = this.App.SysType;
        this.Version = this.App.Version;
        this.App.Visible = true;
        retry = [];
      catch e
        if strcmp(e.identifier,'MATLAB:COM:servercreationfailed')
          if isempty(retry)
            [~,~] = dos('taskkill /F /IM AP2700.exe');
            d = 'C:\Program Files (x86)\Audio Precision\';
            ls = dir([d 'AP2700 *']);
            if ~isempty(ls)
              ap2700 = [d ls(1).name '\Ap2700.exe'];
              if exist(ap2700,'file')
                [~,~] = dos(['"' ap2700 '" &']);
                pause(3);
                retry = true;
                this = AP2700();
                return
              end
            end
          else
            retry = [];
            error('AP2700:CommunicationError',...
              'Unable to communicate with Audio Precision AP2700.');
          end
        end
        retry = [];
        rethrow(e);
      end
    end
    
    function delete(this)
      try %#ok<TRYNC>
        delete(this.AP);
      end
    end
    
    function p = get.Anlr(this)
      if ~isfield(this.cache,'Anlr')
        this.cache.Anlr = this.AP.Anlr;
      end
      p = this.cache.Anlr;
    end
    
    function p = get.App(this)
      if ~isfield(this.cache,'App')
        this.cache.App = this.AP.App;
      end
      p = this.cache.App;
    end
    
    function p = get.Aux(this)
      if ~isfield(this.cache,'Aux')
        this.cache.Aux = this.AP.Aux;
      end
      p = this.cache.Aux;
    end
    
    function p = get.BarGraph(this)
      if ~isfield(this.cache,'BarGraph')
        this.cache.BarGraph = this.AP.BarGraph;
      end
      p = this.cache.BarGraph;
    end
    
    function p = get.Bits(this)
      if ~isfield(this.cache,'Bits')
        this.cache.Bits = this.AP.Bits;
      end
      p = this.cache.Bits;
    end
    
    function p = get.CommA(this)
      if ~isfield(this.cache,'CommA')
        this.cache.CommA = this.AP.CommA;
      end
      p = this.cache.CommA;
    end
    
    function p = get.CommB(this)
      if ~isfield(this.cache,'CommB')
        this.cache.CommB = this.AP.CommB;
      end
      p = this.cache.CommB;
    end
    
    function p = get.Compute(this)
      if ~isfield(this.cache,'Compute')
        this.cache.Compute = this.AP.Compute;
      end
      p = this.cache.Compute;
    end
    
    function p = get.DGen(this)
      if ~isfield(this.cache,'DGen')
        this.cache.DGen = this.AP.DGen;
      end
      p = this.cache.DGen;
    end
    
    function p = get.Data(this)
      if ~isfield(this.cache,'Data')
        this.cache.Data = this.AP.Data;
      end
      p = this.cache.Data;
    end
    
    function p = get.DCX(this)
      if ~isfield(this.cache,'DCX')
        this.cache.DCX = this.AP.Dcx;
      end
      p = this.cache.DCX;
    end
    
    function p = get.Events(this)
      if ~isfield(this.cache,'Events')
        this.cache.Events = this.AP.Events;
      end
      p = this.cache.Events;
    end
    
    function p = get.File(this)
      if ~isfield(this.cache,'File')
        this.cache.File = this.AP.File;
      end
      p = this.cache.File;
    end
    
    function p = get.Gen(this)
      if ~isfield(this.cache,'Gen')
        this.cache.Gen = this.AP.Gen;
      end
      p = this.cache.Gen;
    end
    
    function p = get.Graph(this)
      if ~isfield(this.cache,'Graph')
        this.cache.Graph = this.AP.Graph;
      end
      p = this.cache.Graph;
    end
    
    function p = get.IEC61937(this)
      if ~isfield(this.cache,'IEC61937')
        this.cache.IEC61937 = this.AP.IEC61937;
      end
      p = this.cache.IEC61937;
    end
    
    function p = get.Log(this)
      if ~isfield(this.cache,'Log')
        this.cache.Log = this.AP.Log;
      end
      p = this.cache.Log;
    end
    
    function p = get.Macro(this)
      if ~isfield(this.cache,'Macro')
        this.cache.Macro = this.AP.Macro;
      end
      p = this.cache.Macro;
    end
    
    function p = get.PSIA(this)
      if ~isfield(this.cache,'PSIA')
        this.cache.PSIA = this.AP.PSIA;
      end
      p = this.cache.PSIA;
    end
    
    function p = get.Print(this)
      if ~isfield(this.cache,'Print')
        this.cache.Print = this.AP.Print;
      end
      p = this.cache.Print;
    end
    
    function p = get.Prompt(this)
      if ~isfield(this.cache,'Prompt')
        this.cache.Prompt = this.AP.Prompt;
      end
      p = this.cache.Prompt;
    end
    
    function p = get.Reg(this)
      if ~isfield(this.cache,'Reg')
        this.cache.Reg = this.AP.Reg;
      end
      p = this.cache.Reg;
    end
    
    function p = get.S2CDio(this)
      if ~isfield(this.cache,'S2CDio')
        this.cache.S2CDio = this.AP.S2CDio;
      end
      p = this.cache.S2CDio;
    end
    
    function p = get.S2CDsp(this)
      if ~isfield(this.cache,'S2CDsp')
        this.cache.S2CDsp = this.AP.S2CDsp;
      end
      p = this.cache.S2CDsp;
    end
    
    function p = get.Speaker(this)
      if ~isfield(this.cache,'Speaker')
        this.cache.Speaker = this.AP.Speaker;
      end
      p = this.cache.Speaker;
    end
    
    function p = get.Sweep(this)
      if ~isfield(this.cache,'Sweep')
        this.cache.Sweep = this.AP.Sweep;
      end
      p = this.cache.Sweep;
    end
    
    function p = get.SWR(this)
      if ~isfield(this.cache,'SWR')
        this.cache.SWR = this.AP.Swr;
      end
      p = this.cache.SWR;
    end
    
    function p = get.Sync(this)
      if ~isfield(this.cache,'Sync')
        this.cache.Sync = this.AP.Sync;
      end
      p = this.cache.Sync;
    end
    
    function filename = get.TestFile(this)
      filename = [this.App.TestDir this.App.TestName];
    end
    
    function openTest(this,filename,forceOpen)
      [path,name,ext] = fileparts(filename);
      if isempty(path)
        path = pwd();
      end
      if isempty(ext)
        ext = '.at27';
      end
      filename = fullfile(path,[name ext]);
      h = fopen(filename);
      if h > 0
        fclose(h);
        if nargin == 3 && ~forceOpen
          if strcmpi(this.TestFile,filename)
            return
          end
        end
        this.File.OpenTest(filename);
      else
        error('AP2700:FileNotFound','"%s": no such file.',filename);
      end
    end
    
    function m = getMeasurement(this)
      try
        tmp = [tempname() '.adx'];
        this.File.ExportASCIIData(tmp);
        m = readadx(tmp);
        delete(tmp);
      catch
        error('AP2700:DataExport',...
          'Unable to export measurement data from AP2700.');
      end
    end
    
  end
  
end
