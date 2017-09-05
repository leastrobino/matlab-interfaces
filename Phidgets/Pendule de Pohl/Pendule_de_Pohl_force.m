%
%  Pendule_de_Pohl_force.m
%
%  Created by Léa Strobino.
%  Copyright 2016 hepia. All rights reserved.
%

classdef Pendule_de_Pohl_force < handle
  
  properties (Access = private)
    h
    s
    d
  end
  
  methods
    
    function this = Pendule_de_Pohl_force()
      
      % Settings
      this.s.cpr = -500; % sensor counts per revolution (HEDM-5500 B14)
      
      % Default data
      this.d.path = UIComponent.getUserDirectory();
      this.d.t = NaN;
      this.d.p = NaN;
      this.d.t_exc = NaN;
      this.d.t_enc = NaN;
      this.d.plotType = 0;
      this.d.tool = 0;
      this.d.tic = [];
      
      % Main window
      this.h.window = UIComponent.Figure(...
        'CloseRequestFcn',@this.closeRequestFcn,...
        'Name','Pendule de Pohl forcé  |  Laboratoire de physique  |  hepia',...
        'Size',[1024 768]);
      
      % Dial plot
      this.h.dial = UIComponent.Dial(...
        'IndicatorAngle',-90,...
        'IndicatorNumberFormat','+0.0°;-0.0°',...
        'Min',-150,...
        'Max',150,...
        'StartAngle',-60,...
        'StopAngle',240,...
        'Parent',this.h.window,...
        'Position',[65 598 150 150]);
      
      % Settings panel
      p = UIComponent.Panel(...
        'Parent',this.h.window,...
        'Position',[580 598 230 150],...
        'Title','Paramètres');
      this.h.device = UIComponent.Label(...
        'HorizontalAlignment','left',...
        'Parent',p,...
        'Position',[10 105 210 20],...
        'String','Interfaces :');
      UIComponent.Label(...
        'HorizontalAlignment','left',...
        'Parent',p,...
        'Position',[10 80 210 20],...
        'String','Durée d''enregistrement :');
      this.h.duration = UIComponent.Spinner(...
        'Callback',@this.zoomDefault,...
        'Min',1,...
        'Max',300,...
        'Parent',p,...
        'Position',[10 50 65 25],...
        'Value',30);
      UIComponent.Label(...
        'HorizontalAlignment','left',...
        'Parent',p,...
        'Position',[85 50 135 25],...
        'String','secondes');
      this.h.progressbar = UIComponent.ProgressBar(...
        'PaintLabel','off',...
        'Parent',p,...
        'Position',[10 15 208 25],...
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
      this.h.plot = plot(this.h.axes,NaN,NaN,'r-',NaN,NaN,'o',NaN,NaN,'o','LineWidth',1.2);
      if ispc, m = 4; else m = 6; end
      set(this.h.plot(2),...
        'MarkerEdgeColor',[0 0 0],...
        'MarkerFaceColor',[0 0 0],...
        'MarkerSize',m);
      set(this.h.plot(3),...
        'MarkerEdgeColor',[1 0 0],...
        'MarkerFaceColor',[1 0 0],...
        'MarkerSize',m);
      this.h.axes.XGrid = 'on';
      this.h.axes.YGrid = 'on';
      this.h.axes.XLabel.String = 'Temps (s)';
      this.h.axes.YLabel.String = 'Angle  \theta  (°)';
      set(this.h.axes.Title,...
        'FontSize',UIComponent.getFontSize(),...
        'FontWeight','normal',...
        'Units','pixels',...
        'Position',[455 480 0]);
      this.h.axes.FontSize = UIComponent.getFontSize()/1.1;
      legend(this.h.plot(2:3),{'Passage index excitation','Passage index pendule'},...
        'Box','off',...
        'FontSize',UIComponent.getFontSize(),...
        'Location','south',...
        'Orientation','horizontal');
      
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
        this.h.encoder = PhidgetEncoder('Pohl');
        this.h.phase = PhidgetEncoder('Pohl_Phase');
        this.h.encoder.setCountsPerRevolution(1,this.s.cpr);
        this.h.phase.setCountsPerRevolution(1,pi/2);
        this.h.device.String = [this.h.device.String ' Phidgets ' ...
          this.h.encoder.IDN ' & ' this.h.phase.IDN];
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
        delete(this.h.encoder);
        delete(this.h.phase);
        PhidgetEncoder_instance = 0;
      end
      close(this.h.window,'force');
    end
    
    function capture(this,~)
      this.h.jframe.setEnabled(0);
      this.h.progressbar.Value = 0;
      this.h.progressbar.Visible = 'on';
      this.d.tic = tic;
      this.h.encoder.getPositionAsync(1,this.h.duration.Value,@this.captureAsync);
      this.h.phase.getPositionAsync(1,this.h.duration.Value,@this.capturePhaseAsync);
    end
    
    function captureAsync(this,~,t,p)
      this.d.t = t;
      this.d.p = p;
    end
    
    function capturePhaseAsync(this,~,t,p)
      t = t(2:end);
      p = diff(p) > 0;
      this.d.t_exc = t(p == 0);
      this.d.t_enc = t(p == 1);
      % Frequency (S_f_min = 0.0001 Hz)
      f = 1/mean(diff(this.d.t_exc));
      S_f = max([f^2*sqrt(var(diff(this.d.t_exc))/(length(this.d.t_exc)-1)),1E-4]);
      if ~isnan(f)
        % Amplitude (S_a_min = 0.05°)
        p_max = findpeaks(this.d.p);
        p_min = -findpeaks(-this.d.p);
        a = 90*(mean(p_max)-mean(p_min))/pi;
        S_a = max([90*sqrt(var(p_max)/length(p_max)+var(p_min)/length(p_min))/pi,5E-2]);
        % Phase (S_phi_min = 0.05°)
        if p(1) == 1
          t = t(2:end);
        end
        T = diff(t);
        S_T = sqrt(var(T(1:2:end))/ceil(length(T)/2));
        T = mean(T(1:2:end));
        phi = 360*(.5-T*f);
        S_phi = max([360*sqrt((f*S_T)^2+(T*S_f)^2),5E-2]);
        % Display
        d = -floor(log10([S_f S_a S_phi]));
        s = fixd([S_f S_a S_phi],d);
        for i = 1:3
          if any(s{i} == '.') && s{i}(end) == '0'
            d(i) = d(i)-1;
          end
        end
        if isfinite(d(1))
          s1 = ['(' fixd(f,d(1)) ' \pm ' fixd(S_f,d(1)) ')'];
        else
          s1 = double2str(f,3);
        end
        if isfinite(d(2))
          s2 = [fixd(a,d(2)) '° \pm ' fixd(S_a,d(2))];
        else
          s2 = double2str(a,3);
        end
        if isfinite(d(3))
          s3 = [fixd(phi,d(3)) '° \pm ' fixd(S_phi,d(3))];
        else
          s3 = double2str(phi,3);
        end
        this.h.axes.Title.String = [...
          'Fréquence : ' s1 ' Hz     ' ...
          'Amplitude : ' s2 '°     ' ...
          'Phase : ' s3 '°'];
      end
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
      fprintf(f,'%% Temps (s)%sAngle (rad)%sTemps passage index excitation (s)%sTemps passage index pendule (s)\n',sep,sep,sep);
      for i = 1:max([length(this.d.t),length(this.d.t_exc),length(this.d.t_enc)])
        try %#ok<TRYNC>
          fprintf(f,'%.9g%s%.9g',this.d.t(i),sep,this.d.p(i));
        end
        try %#ok<TRYNC>
          fprintf(f,'%s%.9g',sep,this.d.t_exc(i));
        end
        try %#ok<TRYNC>
          fprintf(f,'%s%.9g',sep,this.d.t_enc(i));
        end
        fprintf(f,'\n');
      end
      fclose(f);
      this.h.jframe.setEnabled(1);
    end
    
    function plot(this)
      if this.d.plotType
        x = [this.d.t this.d.t]';
        y = [this.d.p this.d.p]';
        this.h.plot(1).XData = x(2:end);
        this.h.plot(1).YData = 180*y(1:end-1)/pi;
      else
        this.h.plot(1).XData = this.d.t;
        this.h.plot(1).YData = 180*this.d.p/pi;
      end
      try
        f = griddedInterpolant(this.d.t,180*this.d.p/pi);
      catch
        f = @(~) 0;
      end
      try
        this.h.plot(2).XData = this.d.t_exc;
        this.h.plot(2).YData = f(this.d.t_exc);
      catch
        this.h.plot(2).XData = NaN;
        this.h.plot(2).YData = NaN;
      end
      try
        this.h.plot(3).XData = this.d.t_enc;
        this.h.plot(3).YData = f(this.d.t_enc);
      catch
        this.h.plot(3).XData = NaN;
        this.h.plot(3).YData = NaN;
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
      this.h.encoder.setPosition(1,0);
    end
    
    function zoomActionPost(this,~,~)
      if all(this.h.axes.XLim == [0 30])
        this.h.axes.XTick = 0:2:30;
      else
        this.h.axes.XTickMode = 'auto';
      end
      if all(this.h.axes.YLim == [-90 90])
        this.h.axes.YTick = -90:15:90;
      else
        this.h.axes.YTickMode = 'auto';
      end
    end
    
    function zoomDefault(this,~,~)
      this.h.axes.XLim = [0 this.h.duration.Value];
      this.h.axes.YLim = [-90 90];
      this.zoomActionPost();
    end
    
    function timerFcn(this,~,~)
      a = this.h.encoder.getPosition(1);
      this.h.dial.Value = 180*a/pi;
      if ~isempty(this.d.tic)
        this.h.progressbar.Value = toc(this.d.tic)/this.h.duration.Value;
      end
    end
    
  end
  
end
