%
%  InterfaceLDVideoCom.m
%
%  Created by Léa Strobino.
%  Copyright 2017 hepia. All rights reserved.
%

classdef InterfaceLDVideoCom < handle
  
  properties (Access = private)
    h
    s
    d
  end
  
  methods
    
    function this = InterfaceLDVideoCom(port)
      
      % Serial port
      if nargin
        this.s.port = port;
      elseif ispc
        try
          [~,dev] = dos('reg query HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM');
          dev = regexp(dev,'REG_SZ +([^\n]*)\n','tokens');
          this.s.port = dev{end}{1};
        catch
          error('InterfaceLDVideoCom:NoSerialPortDetected',...
            'No serial port detected.\nUse %s(''PORT'') to skip autodetection.',mfilename);
        end
      else
        if ismac
          [~,dev] = unix('ls /dev | grep "tty\.usbserial\|tty\.UC-232AC"');
        else
          [~,dev] = unix('ls /dev | grep ttyUSB');
        end
        if isempty(dev)
          error('InterfaceLDVideoCom:NoSerialPortDetected',...
            'No USB serial port detected.\nUse %s(''PORT'') to skip autodetection.',mfilename);
        end
        this.s.port = ['/dev/' sscanf(dev,'%s',1)];
      end
      
      % Default data
      this.d.path = UIComponent.getUserDirectory();
      this.d.start = true;
      
      % Main window
      this.h.window = UIComponent.Figure(...
        'CloseRequestFcn',@this.closeRequestFcn,...
        'Name','Interface LD 337 47  |  Laboratoire de physique  |  hepia',...
        'Size',[1024 768]);
      
      % Pixels
      this.h.pixels = UIComponent.ComboBox(...
        'Callback',@this.setPixels,...
        'Parent',this.h.window,...
        'Position',[65 708 150 35],...
        'String',{' 64 points',' 128 points',' 256 points',' 512 points',' 1024 points',' 2048 points'},...
        'Value',3);
      
      % Start/Stop
      this.h.start = UIComponent.Button(...
        'Callback',@this.start,...
        'Parent',this.h.window,...
        'Position',[235 708 120 35],...
        'String','Stop');
      
      % Export
      this.h.export = UIComponent.Button(...
        'Callback',@this.export,...
        'Enable','off',...
        'Parent',this.h.window,...
        'Position',[855 708 120 35],...
        'String','Exporter');
      
      % Axes
      this.h.axes = UIComponent.Axes(...
        'Parent',this.h.window,...
        'Position',[65 60 910 620]);
      this.h.plot = plot(this.h.axes,NaN,NaN,'r-','LineWidth',1.2);
      this.h.axes.XLim = [-14 14];
      this.h.axes.XTick = -14:14;
      this.h.axes.YLim = [0 256];
      this.h.axes.YTick = 0:16:256;
      this.h.axes.XGrid = 'on';
      this.h.axes.YGrid = 'on';
      this.h.axes.XLabel.String = 'x (mm)';
      this.h.axes.YLabel.String = 'Amplitude relative (-)';
      this.h.axes.FontSize = UIComponent.getFontSize()/1.1;
      
      % Connect to the LD VideoCom, allowing only one instance
      try
        global ldVideoCom_instance %#ok<TLEV>
        if ldVideoCom_instance == 1
          error('InterfaceLDVideoCom:OneInstanceAllowed',...
            'Only one instance of the LD VideoCom interface is allowed.');
        end
        this.h.videocom = LD_VideoCom(this.s.port,@this.plot);
        this.h.window.Name = ['Interface LD 337 47  |  ' ...
          this.h.videocom.IDN '  |  Laboratoire de physique  |  hepia'];
        ldVideoCom_instance = 1;
      catch e
        jerrordlg(e.message);
        this.closeRequestFcn();
        if isdeployed
          return
        else
          rethrow(e);
        end
      end
      
      % Show the main window
      this.h.window.Visible = 'on';
      
    end
    
  end
  
  methods (Access = private)
    
    function closeRequestFcn(this,~,~)
      global ldVideoCom_instance
      try %#ok<TRYNC>
        this.h.window.Visible = 'off';
      end
      try %#ok<TRYNC>
        delete(this.h.videocom);
        ldVideoCom_instance = 0;
      end
      close(this.h.window,'force');
    end
    
    function setPixels(this,~)
      n = 64*2^(this.h.pixels.Value-1);
      this.h.videocom.Pixels = n;
    end
    
    function start(this,~)
      this.d.start = ~this.d.start;
      if this.d.start
        this.h.start.String = 'Stop';
        this.h.export.Enable = 'off';
      else
        this.h.start.String = 'Start';
        this.h.export.Enable = 'on';
      end
    end
    
    function export(this,~)
      filter = {'*.csv','Comma-separated values';...
        '*.txt','Tabulation-separated values'};
      [f,p,i] = uiputfile(filter,'Enregistrer sous',this.d.path);
      if ~f
        return
      end
      [p,n,e] = fileparts([p f]);
      this.d.path = [p '/'];
      switch i
        case 1
          ext = '.csv';
          sep = ',';
        case 2
          ext = '.txt';
          sep = sprintf('\t');
      end
      if ~strcmpi(e,ext)
        e = [e ext];
      end
      f = fopen(fullfile(this.d.path,[n e]),'w');
      fprintf(f,'%% %s\n%% %s\n%%\n',this.h.window.Name,datestr(now));
      fprintf(f,'%% x (mm)%sAmplitude relative (-)\n',sep);
      for i = 1:2:length(this.h.plot.XData)
        fprintf(f,'%.9g%s%.9g\n',this.h.plot.XData(i),sep,this.h.plot.YData(i));
      end
      fclose(f);
    end
    
    function plot(this,d)
      if this.d.start
        if this.h.videocom.Pixels ~= 64*2^(this.h.pixels.Value-1)
          this.setPixels();
        end
        x = -14:28/(length(d)-1):14;
        x = [x;x];
        y = [d d]';
        this.h.plot.XData = x(2:end);
        this.h.plot.YData = y(1:end-1);
      end
    end
    
  end
  
end
