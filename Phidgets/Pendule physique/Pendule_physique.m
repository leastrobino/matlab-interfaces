%
%  Pendule_physique.m
%
%  Created by Léa Strobino.
%  Copyright 2015 hepia. All rights reserved.
%

classdef Pendule_physique < handle
  
  properties (Access = private)
    h
    s
    d
  end
  
  methods
    
    function this = Pendule_physique()
      
      % Settings
      this.s.cpr = -1000; % sensor counts per revolution (HEDM-5500 B14)
      
      % Default data
      this.d.path = UIComponent.getUserDirectory();
      this.d.t = NaN;
      this.d.p = NaN;
      this.d.plotType = 0;
      this.d.tool = 0;
      this.d.tic = [];
      
      % Main window
      this.h.window = UIComponent.Figure(...
        'CloseRequestFcn',@this.closeRequestFcn,...
        'Name','Pendule physique  |  Laboratoire de physique  |  hepia',...
        'Size',[1024 768]);
      
      % Dial plot
      this.h.dial = UIComponent.Dial(...
        'IndicatorAngle',90,...
        'IndicatorNumberFormat','+0.0°;-0.0°',...
        'Min',-180,...
        'Max',179,...
        'StartAngle',90,...
        'StopAngle',449,...
        'Parent',this.h.window,...
        'Position',[65 598 150 150]);
      
      % Settings panel
      p = UIComponent.Panel(...
        'Parent',this.h.window,...
        'Position',[600 598 210 150],...
        'Title','Paramètres');
      this.h.device = UIComponent.Label(...
        'HorizontalAlignment','left',...
        'Parent',p,...
        'Position',[10 105 190 20],...
        'String','Interface :');
      UIComponent.Label(...
        'HorizontalAlignment','left',...
        'Parent',p,...
        'Position',[10 80 190 20],...
        'String','Durée d''enregistrement :');
      this.h.duration = UIComponent.Spinner(...
        'Callback',@this.zoomDefault,...
        'Min',1,...
        'Max',300,...
        'Parent',p,...
        'Position',[10 50 65 25],...
        'Value',15);
      UIComponent.Label(...
        'HorizontalAlignment','left',...
        'Parent',p,...
        'Position',[85 50 115 25],...
        'String','secondes');
      this.h.autoscale = UIComponent.CheckBox(...
        'Callback',@this.zoomDefault,...
        'Parent',p,...
        'Position',[10 15 188 25],...
        'String','Échelle automatique',...
        'Value',true);
      this.h.progressbar = UIComponent.ProgressBar(...
        'PaintLabel','off',...
        'Parent',p,...
        'Position',[10 15 188 25],...
        'Visible','off');
      
      % Actions
      this.h.zero = UIComponent.Button(...
        'Callback',@this.zero,...
        'Parent',this.h.window,...
        'Position',[855 708 120 35],...
        'String','Remise à zéro');
      this.h.capture = UIComponent.Button(...
        'Callback',@this.capture,...
        'Parent',this.h.window,...
        'Position',[855 653 120 35],...
        'String','Enregistrer');
      this.h.export = UIComponent.Button(...
        'Callback',@this.export,...
        'Enable','off',...
        'Parent',this.h.window,...
        'Position',[855 598 120 35],...
        'String','Exporter');
      
      % Axes
      this.h.axes = UIComponent.Axes(...
        'Parent',this.h.window,...
        'Position',[65 60 910 510]);
      
      % Context menu
      this.h.contextmenu = UIComponent.ContextMenu(...
        'Parent',this.h.window);
      this.h.tool = UIComponent.Menu(...
        'Callback',@this.setTool,...
        'Label','Data cursor',...
        'Parent',this.h.contextmenu);
      UIComponent.Menu(...
        'Callback',@this.zoomDefault,...
        'Label','Reset to original view',...
        'Parent',this.h.contextmenu);
      this.h.plotType = UIComponent.Menu(...
        'Callback',@this.setPlotType,...
        'Label','Stairstep graph',...
        'Parent',this.h.contextmenu,...
        'Separator','on');
      
      % Plot, grid lines & labels
      this.h.plot = plot(this.h.axes,NaN,NaN,'r-','LineWidth',1.2);
      this.h.axes.XGrid = 'on';
      this.h.axes.YGrid = 'on';
      this.h.axes.XLabel.String = 'Temps (s)';
      this.h.axes.YLabel.String = 'Angle  \theta  (°)';
      this.h.axes.FontSize = UIComponent.getFontSize()/1.1;
      
      % Data cursor
      this.h.cursor = datacursormode(this.h.window);
      set(this.h.cursor,...
        'DisplayStyle','datatip',...
        'Enable','off',...
        'SnapToDataVertex','on',...
        'UIContextMenu',this.h.contextmenu,...
        'UpdateFcn',@this.updateCursor);
      
      % Zoom
      this.h.zoom = zoom(this.h.window);
      set(this.h.zoom,...
        'ActionPostCallback',@this.zoomActionPost,...
        'UIContextMenu',this.h.contextmenu,...
        'Enable','on');
      this.zoomDefault();
      
      % Timer
      this.h.timer = timer(...
        'ExecutionMode','FixedRate',...
        'Period',1/25,...
        'TimerFcn',@this.timerFcn);
      
      % Connect to the Phidget encoder, allowing only one instance
      try
        global PhidgetEncoder_instance %#ok<TLEV>
        if PhidgetEncoder_instance == 1
          error('PhidgetEncoder:OneInstanceAllowed',...
            'Only one instance of the PhidgetEncoder class is allowed.');
        end
        this.h.phidget = PhidgetEncoder();
        this.h.phidget.setCountsPerRevolution(1,this.s.cpr);
        this.h.device.String = [this.h.device.String ' Phidget ' this.h.phidget.IDN];
        PhidgetEncoder_instance = 1;
      catch e
        if isempty(e.cause)
          jerrordlg(e.message);
        else
          jerrordlg([e.message 10 e.cause{1}.message]);
        end
        this.closeRequestFcn();
        if isdeployed
          return
        else
          rethrow(e);
        end
      end
      
      % Start the timer
      start(this.h.timer);
      
      % Show the main window and get the JFrame
      this.h.jframe = UIComponent.getJFrame(this.h.window);
      
    end
    
  end
  
  methods (Access = private)
    
    function closeRequestFcn(this,~,~)
      global PhidgetEncoder_instance
      try %#ok<TRYNC>
        this.h.window.Visible = 'off';
      end
      stop(this.h.timer);
      delete(this.h.timer);
      try %#ok<TRYNC>
        delete(this.h.phidget);
        PhidgetEncoder_instance = 0;
      end
      close(this.h.window,'force');
    end
    
    function capture(this,~)
      this.h.jframe.setEnabled(0);
      this.h.progressbar.Value = 0;
      this.h.progressbar.Visible = 'on';
      this.d.tic = tic;
      this.h.phidget.getPositionAsync(1,this.h.duration.Value,@this.captureAsync);
    end
    
    function captureAsync(this,~,t,p)
      this.d.t = t;
      this.d.p = p;
      this.plot();
      this.zoomDefault();
      this.d.tic = [];
      this.h.progressbar.Visible = 'off';
      this.h.export.Enable = 'on';
      this.h.jframe.setEnabled(1);
    end
    
    function export(this,~)
      filter = {'*.csv','Comma-separated values';...
        '*.txt','Tabulation-separated values'};
      [f,p,i] = uiputfile(filter,'Enregistrer sous',this.d.path);
      if ~f
        return
      end
      this.h.jframe.setEnabled(0);
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
      fprintf(f,'%% Temps (s)%sAngle (rad)\n',sep);
      for i = 1:length(this.d.t)
        fprintf(f,'%.9g%s%.9g\n',this.d.t(i),sep,this.d.p(i));
      end
      fclose(f);
      this.h.jframe.setEnabled(1);
    end
    
    function plot(this)
      if this.d.plotType
        x = [this.d.t this.d.t]';
        y = [this.d.p this.d.p]';
        this.h.plot.XData = x(2:end);
        this.h.plot.YData = 180*y(1:end-1)/pi;
      else
        this.h.plot.XData = this.d.t;
        this.h.plot.YData = 180*this.d.p/pi;
      end
    end
    
    function setPlotType(this,~,~)
      this.d.plotType = ~this.d.plotType;
      if this.d.plotType
        this.h.plotType.Label = 'Interpolated graph';
      else
        this.h.plotType.Label = 'Stairstep graph';
      end
      this.plot();
    end
    
    function setTool(this,~,~)
      this.d.tool = ~this.d.tool;
      if this.d.tool
        this.h.zoom.Enable = 'off';
        this.h.cursor.Enable = 'on';
        this.h.tool.Label = 'Zoom';
      else
        this.h.cursor.Enable = 'off';
        this.h.zoom.Enable = 'on';
        this.h.tool.Label = 'Data cursor';
      end
    end
    
    function s = updateCursor(this,~,e)
      s = sprintf('Temps : %.6f s\nAngle : %.2f°',e.Position);
      if this.d.plotType
        x = e.Target.XData(1:2:end);
        y = e.Target.YData(1:2:end);
        if ~any((x == e.Position(1)) & (y == e.Position(2)))
          s = [];
        end
      end
    end
    
    function zero(this,~)
      this.h.phidget.setPosition(1,0);
    end
    
    function zoomActionPost(this,~,~)
      if all(this.h.axes.XLim == [0 15])
        this.h.axes.XTick = 0:15;
      else
        this.h.axes.XTickMode = 'auto';
      end
      if all(this.h.axes.YLim == [-180 180])
        this.h.axes.YTick = -180:30:180;
      else
        this.h.axes.YTickMode = 'auto';
      end
    end
    
    function zoomDefault(this,~,~)
      this.h.axes.XLim = [0 this.h.duration.Value];
      if this.h.autoscale.Value && ~any(isnan(this.d.p))
        m = max([ceil(max(abs(180*this.d.p/pi))),1]);
        this.h.axes.YLim = [-m m];
      else
        this.h.axes.YLim = [-180 180];
      end
      this.zoomActionPost();
    end
    
    function timerFcn(this,~,~)
      a = this.h.phidget.getPosition(1);
      this.h.dial.Value = 180*a/pi;
      if ~isempty(this.d.tic)
        this.h.progressbar.Value = toc(this.d.tic)/this.h.duration.Value;
      end
    end
    
  end
  
end
