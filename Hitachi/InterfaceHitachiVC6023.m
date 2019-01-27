%
%  InterfaceHitachiVC6023.m
%
%  Created by Léa Strobino.
%  Copyright 2018. All rights reserved.
%

classdef InterfaceHitachiVC6023 < handle
  
  properties (Access = private)
    h
    s
    d
  end
  
  methods
    
    function this = InterfaceHitachiVC6023(port)
      
      % Serial port
      if nargin
        this.s.port = port;
      elseif ispc
        try
          [~,dev] = dos('reg query HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM');
          dev = regexp(dev,'REG_SZ +([^\n]*)\n','tokens');
          this.s.port = dev{end}{1};
        catch
          error('InterfaceHitachiVC6023:NoSerialPortDetected',...
            'No serial port detected.\nUse %s(''PORT'') to skip autodetection.',mfilename);
        end
      else
        if ismac
          [~,dev] = unix('ls /dev | grep "tty\.usbserial\|tty\.UC-232AC"');
        else
          [~,dev] = unix('ls /dev | grep ttyUSB');
        end
        if isempty(dev)
          error('InterfaceHitachiVC6023:NoSerialPortDetected',...
            'No USB serial port detected.\nUse %s(''PORT'') to skip autodetection.',mfilename);
        end
        this.s.port = ['/dev/' sscanf(dev,'%s',1)];
      end
      
      % Settings
      this.s.color = '0072BD'; % plot color
      
      % Default data
      this.d.appdir = [fileparts(mfilename('fullpath')) filesep];
      this.d.path = UIComponent.getUserDirectory();
      
      % Main window
      this.h.window = UIComponent.Figure(...
        'CloseRequestFcn',@this.closeRequestFcn,...
        'Name','Interface Hitachi VC-6023',...
        'Size',[1024 768]);
      zoom(this.h.window,'on');
      
      % Axes
      this.h.axes_A = UIComponent.Axes(...
        'Parent',this.h.window,...
        'Position',[65 438 743 300]);
      this.h.axes_B = UIComponent.Axes(...
        'Parent',this.h.window,...
        'Position',[65 60 743 300]);
      
      % Traces, grid lines & labels
      c = sscanf(this.s.color,'%2X')/255;
      this.h.trace_A = plot(this.h.axes_A,NaN,NaN,'Color',c);
      this.h.trace_B = plot(this.h.axes_B,NaN,NaN,'Color',c);
      set([this.h.axes_A this.h.axes_B],...
        'FontSize',UIComponent.getFontSize()/1.1,...
        'XGrid','on','YGrid','on');
      this.h.XLabel = [this.h.axes_A.XLabel this.h.axes_B.XLabel];
      this.h.ALabel = this.h.axes_A.YLabel;
      this.h.BLabel = this.h.axes_B.YLabel;
      this.h.parameters = this.h.axes_B.Title;
      set(this.h.parameters,...
        'HorizontalAlignment','right',...
        'Units','pixels',...
        'Position',[750 315 0]);
      linkaxes([this.h.axes_A this.h.axes_B],'x');
      
      % Logo
      UIComponent.Label(...
        'Icon',UIComponent.createIcon([this.d.appdir 'hitachi.png']),...
        'Parent',this.h.window,...
        'Position',[848 664 147 74]);
      
      % Plot preview
      img = zeros(119,147,3,'uint8');
      img(2:118,2:146,:) = 255;
      this.h.preview = UIComponent.Label(...
        'Icon',UIComponent.createIcon(img),...
        'Parent',this.h.window,...
        'Position',[848 242 147 119]);
      
      % Trig, transfer & export buttons
      this.h.trig = UIComponent.Button(...
        'Callback',@this.trig,...
        'Parent',this.h.window,...
        'Position',[848 438 147 40],...
        'String','Send trigger');
      this.h.exportPlot = UIComponent.Button(...
        'Callback',@this.exportPlot,...
        'Enable','off',...
        'Parent',this.h.window,...
        'Position',[848 180 147 40],...
        'String','Export plot');
      this.h.getTrace = UIComponent.Button(...
        'Callback',@this.getTrace,...
        'Parent',this.h.window,...
        'Position',[848 120 147 40],...
        'String','Transfer traces');
      this.h.export = UIComponent.Button(...
        'Callback',@this.export,...
        'Enable','off',...
        'Parent',this.h.window,...
        'Position',[848 60 147 40],...
        'String','Export traces');
      
      % Connect to the Hitachi VC-6023, allowing only one instance
      try
        global hitachiVC6023_instance %#ok<TLEV>
        if hitachiVC6023_instance == 1
          error('InterfaceHitachiVC6023:OneInstanceAllowed',...
            'Only one instance of the Hitachi VC-6023 interface is allowed.');
        end
        this.h.VC6023 = Hitachi_VC6023(this.s.port,@this.preview);
        hitachiVC6023_instance = 1;
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
      global hitachiVC6023_instance
      try %#ok<TRYNC>
        this.h.window.Visible = 'off';
      end
      try %#ok<TRYNC>
        delete(this.h.VC6023);
        hitachiVC6023_instance = 0;
      end
      close(this.h.window,'force');
    end
    
    % Trigger
    
    function trig(this,~,~,~)
      try
        this.h.VC6023.trig();
      catch e
        jwarndlg(e.message);
      end
    end
    
    % Traces
    
    function getTrace(this,~,~,~)
      this.h.window.Pointer = 'watch';
      drawnow();
      try
        [this.d.x,this.d.trace_A,this.d.trace_B,this.d.info] = this.h.VC6023.getTrace();
      catch e
        this.h.window.Pointer = 'arrow';
        jerrordlg(e.message);
        return
      end
      this.h.trace_A(1).XData = this.d.x;
      this.h.trace_A(1).YData = this.d.trace_A;
      this.h.trace_B(1).XData = this.d.x;
      this.h.trace_B(1).YData = this.d.trace_B;
      this.autoScale();
      set(this.h.XLabel,'String',this.d.info.XLabel);
      this.h.ALabel.String = this.d.info.ALabel;
      this.h.BLabel.String = this.d.info.BLabel;
      this.h.parameters.String = this.d.info.Measurement;
      drawnow();
      this.h.export.Enable = 'on';
      this.h.window.Pointer = 'arrow';
    end
    
    function autoScale(this)
      set([this.h.axes_A this.h.axes_B],...
        'XLim',[this.d.x(1) this.d.x(end)],...
        'YLimMode','auto');
    end
    
    % Plot preview
    
    function preview(this,~)
      try
        plot = this.h.VC6023.getScreen(1);
      catch e
        jerrordlg(e.message);
        return
      end
      img = zeros(119,147,3,'uint8');
      img(2:118,2:146,:) = imresize(plot,[117 145]);
      this.h.preview.Icon = UIComponent.createIcon(img);
      this.h.exportPlot.Enable = 'on';
      this.exportPlot();
    end
    
    % Export
    
    function export(this,~,~,~)
      filter = {'*.csv','Comma-separated values';...
        '*.txt','Tabulation-separated values';...
        '*.pdf','PDF plot'};
      [f,p,i] = uiputfile(filter,'Save as',this.d.path);
      if ~f
        return
      end
      this.h.window.Pointer = 'watch';
      drawnow();
      [p,n,e] = fileparts([p f]);
      this.d.path = [p '/'];
      switch i
        case 1
          ext = '.csv';
          sep = ',';
        case 2
          ext = '.txt';
          sep = sprintf('\t');
        case 3
          ext = '.pdf';
      end
      if ~strcmpi(e,ext)
        e = [e ext];
      end
      file = fullfile(this.d.path,[n e]);
      switch ext
        case {'.csv','.txt'}
          f = fopen(file,'w');
          fprintf(f,'%% %s\n%% %s\n%%\n',this.h.window.Name,datestr(now));
          fprintf(f,'%% %s\n',strrep(this.d.info.Measurement,'; ',sprintf('\n%% ')));
          fprintf(f,'%%\n%% %s%s',this.d.info.XLabel,sep);
          fprintf(f,'%s%s%s\n',this.d.info.ALabel,sep,this.d.info.BLabel);
          for i = 1:length(this.d.x)
            fprintf(f,'%.9g%s%.9g%s%.9g\n',...
              this.d.x(i),sep,...
              this.d.trace_A(i),sep,...
              this.d.trace_B(i));
          end
          fclose(f);
        case '.pdf'
          f = figure('Visible','off');
          a(1) = subplot(2,1,1,'Parent',f);
          a(2) = subplot(2,1,2,'Parent',f);
          c = sscanf(this.s.color,'%2X')/255;
          plot(a(1),this.d.x,this.d.trace_A,'Color',c);
          plot(a(2),this.d.x,this.d.trace_B,'Color',c);
          set(a,...
            'XLim',[this.d.x(1) this.d.x(end)],...
            'YLimMode','auto',...
            'XGrid','on','YGrid','on');
          set([a(1).XLabel a(2).XLabel],'String',this.d.info.XLabel);
          a(1).YLabel.String = this.d.info.ALabel;
          a(2).YLabel.String = this.d.info.BLabel;
          exportfig(f,file,[297 210],10);
          close(f);
      end
      this.h.window.Pointer = 'arrow';
    end
    
    function exportPlot(this,~,~,~)
      filter = {'*.png','PNG screen copy';...
        '*.pdf','PDF plot';...
        '*.eps','EPS plot';...
        '*.hpgl','Raw HPGL plot'};
      [f,p,i] = uiputfile(filter,'Save as',this.d.path);
      if ~f
        return
      end
      [p,n,e] = fileparts([p f]);
      this.d.path = [p '/'];
      switch i
        case 1
          ext = '.png';
        case 2
          ext = '.pdf';
        case 3
          ext = '.eps';
        case 4
          ext = '.hpgl';
      end
      if ~strcmpi(e,ext)
        e = [e ext];
      end
      file = fullfile(this.d.path,[n e]);
      try
        this.h.VC6023.getScreen(1,file);
      catch e
        jerrordlg(e.message);
      end
    end
    
  end
  
end
