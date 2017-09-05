%
%  InterfaceTektronixTDS.m
%
%  Created by Léa Strobino.
%  Copyright 2015 hepia. All rights reserved.
%

classdef InterfaceTektronixTDS < handle
  
  properties (Access = private)
    h
    s
    d
  end
  
  methods
    
    function this = InterfaceTektronixTDS(port)
      
      % Serial port
      if nargin
        this.s.port = port;
      elseif ispc
        try
          [~,dev] = dos('reg query HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM');
          dev = regexp(dev,'REG_SZ +([^\n]*)\n','tokens');
          this.s.port = dev{end}{1};
        catch
          error('InterfaceTektronixTDS:NoSerialPortDetected',...
            'No serial port detected.\nUse %s(''PORT'') to skip autodetection.',mfilename);
        end
      else
        if ismac
          [~,dev] = unix('ls /dev | grep "tty\.usbserial\|tty\.UC-232AC"');
        else
          [~,dev] = unix('ls /dev | grep ttyUSB');
        end
        if isempty(dev)
          error('InterfaceTektronixTDS:NoSerialPortDetected',...
            'No USB serial port detected.\nUse %s(''PORT'') to skip autodetection.',mfilename);
        end
        this.s.port = ['/dev/' sscanf(dev,'%s',1)];
      end
      
      % Settings
      this.s.color = '0072BD'; % plot color
      
      % Default data
      this.d.path = UIComponent.getUserDirectory();
      this.d.export = 0;
      
      % Main window
      this.h.window = UIComponent.Figure(...
        'CloseRequestFcn',@this.closeRequestFcn,...
        'Name','Interface Tektronix TDS  |  hepia',...
        'Size',[1024 768]);
      zoom(this.h.window,'on');
      
      % Axes
      this.h.axes_A = UIComponent.Axes(...
        'Parent',this.h.window,...
        'Position',[65 438 750 300]);
      this.h.axes_B = UIComponent.Axes(...
        'Parent',this.h.window,...
        'Position',[65 60 750 300]);
      
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
        'Icon',UIComponent.createIcon('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIwAAAAjCAYAAABGiuIFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoV2luZG93cykiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6ODI0NTk5RTA1NjAzMTFFNTkwQUY4RjhEMzAzQTY3NjQiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6ODI0NTk5RTE1NjAzMTFFNTkwQUY4RjhEMzAzQTY3NjQiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo4MjQ1OTlERTU2MDMxMUU1OTBBRjhGOEQzMDNBNjc2NCIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo4MjQ1OTlERjU2MDMxMUU1OTBBRjhGOEQzMDNBNjc2NCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PiKe+MkAABS3SURBVHja7FwJtF1V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'),...
        'Parent',this.h.window,...
        'Position',[855 703 140 35]);
      
      % Transfer & export buttons
      this.h.getTrace = UIComponent.Button(...
        'Callback',@this.getTrace,...
        'Parent',this.h.window,...
        'Position',[855 120 140 40],...
        'String','Transfer traces');
      this.h.export = UIComponent.Button(...
        'Callback',@this.export,...
        'Parent',this.h.window,...
        'Position',[855 60 140 40],...
        'String','Export');
      
      % Connect to the Tektronix oscilloscope, allowing only one instance
      try
        global tektronixTDS_instance %#ok<TLEV>
        if tektronixTDS_instance == 1
          error('InterfaceTektronixTDS:OneInstanceAllowed',...
            'Only one instance of the Tektronix oscilloscope interface is allowed.');
        end
        this.h.tds = Tektronix_TDS(this.s.port);
        IDN = strsplit(this.h.tds.IDN,',');
        this.h.window.Name = ['Interface Tektronix ' IDN{2} '  |  ' ...
          this.s.port '  |  ' IDN{4} '  |  hepia'];
        tektronixTDS_instance = 1;
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
      global tektronixTDS_instance
      try %#ok<TRYNC>
        this.h.window.Visible = 'off';
      end
      try %#ok<TRYNC>
        delete(this.h.tds);
        tektronixTDS_instance = 0;
      end
      close(this.h.window,'force');
    end
    
    % Traces
    
    function getTrace(this,~,~,~)
      this.h.window.Pointer = 'watch';
      drawnow();
      try
        [this.d.x,this.d.trace_A,this.d.trace_B,this.d.info] = this.h.tds.getTrace();
      catch e
        this.h.window.Pointer = 'arrow';
        jwarndlg(e.message);
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
      this.d.export = 1;
      this.h.window.Pointer = 'arrow';
    end
    
    function autoScale(this)
      set([this.h.axes_A this.h.axes_B],...
        'XLim',[this.d.x(1) this.d.x(end)],...
        'YLimMode','auto');
    end
    
    % Export
    
    function export(this,~,~,~)
      filter = {'*.csv','Comma-separated values';...
        '*.txt','Tabulation-separated values';...
        '*.pdf','PDF plot';...
        '*.png','PNG screen copy'};
      if ~this.d.export
        filter = filter(end,:);
      end
      [f,p,i] = uiputfile(filter,'Save as',this.d.path);
      if ~f
        return
      end
      this.h.window.Pointer = 'watch';
      drawnow();
      [p,n,e] = fileparts([p f]);
      this.d.path = [p '/'];
      if this.d.export
        switch i
          case 1
            ext = '.csv';
            sep = ',';
          case 2
            ext = '.txt';
            sep = sprintf('\t');
          case 3
            ext = '.pdf';
          case 4
            ext = '.png';
        end
      else
        ext = '.png';
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
        case '.png'
          try
            img = this.h.tds.getScreen();
          catch e
            this.h.window.Pointer = 'arrow';
            jwarndlg(e.message);
            return
          end
          imwrite(img,file,'Software',strrep(this.h.window.Name,'  | ',','));
      end
      this.h.window.Pointer = 'arrow';
    end
    
  end
  
end
