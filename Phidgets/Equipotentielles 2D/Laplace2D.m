%
%  Laplace2D.m
%
%  Created by Léa Strobino.
%  Copyright 2016 hepia. All rights reserved.
%

classdef Laplace2D < handle
  
  properties (Access = private)
    h
    s
    d
  end
  
  methods
    
    function this = Laplace2D()
      
      % Settings
      this.s.size  = [280 180]; % mm
      this.s.color = ['000000';'EE0000';'FF8000';'90C040';'00B0F0';'903090';'888888'];
      
      % Default data
      this.d.path = UIComponent.getUserDirectory();
      this.d.labels = {};
      this.d.points = [];
      
      % Main window
      this.h.window = UIComponent.Figure(...
        'CloseRequestFcn',@this.closeRequestFcn,...
        'Name','Laplace 2D  |  Laboratoire de physique  |  hepia',...
        'Size',[1024 768]);
      
      % Readings
      this.h.readings = UIComponent.Panel(...
        'Parent',this.h.window,...
        'Position',[56 653 325 105],...
        'Title','Interface :');
      this.h.x.label = UIComponent.Label(...
        'FontName','Helvetica Neue',...
        'FontStyle','bold',...
        'Parent',this.h.readings,...
        'Position',[12 65 150 20],...
        'String','Axe X');
      this.h.x.value = UIComponent.Label(...
        'FontName','Helvetica Neue',...
        'FontSize',24,...
        'FontStyle','bold',...
        'Parent',this.h.readings,...
        'Position',[12 33 150 30],...
        'String','--- mm');
      this.h.x.rawValue = UIComponent.Label(...
        'FontName','Helvetica Neue',...
        'FontSize',14,...
        'FontStyle','bold',...
        'Parent',this.h.readings,...
        'Position',[12 10 150 20],...
        'String','--- %');
      this.h.y.label = UIComponent.Label(...
        'FontName','Helvetica Neue',...
        'FontStyle','bold',...
        'Parent',this.h.readings,...
        'Position',[162 65 150 20],...
        'String','Axe Y');
      this.h.y.value = UIComponent.Label(...
        'FontName','Helvetica Neue',...
        'FontSize',24,...
        'FontStyle','bold',...
        'Parent',this.h.readings,...
        'Position',[162 33 150 30],...
        'String','--- mm');
      this.h.y.rawValue = UIComponent.Label(...
        'FontName','Helvetica Neue',...
        'FontSize',14,...
        'FontStyle','bold',...
        'Parent',this.h.readings,...
        'Position',[162 10 150 20],...
        'String','--- %');
      
      % Buttons
      this.h.new = UIComponent.Button(...
        'Callback',@this.new,...
        'Parent',this.h.window,...
        'Position',[461 683 180 40],...
        'String','Nouvelle série de points');
      this.h.save = UIComponent.Button(...
        'Callback',@this.save,...
        'Enable','off',...
        'Parent',this.h.window,...
        'Position',[656 683 150 40],...
        'String','Enregistrer le point');
      this.h.export = UIComponent.Button(...
        'Callback',@this.export,...
        'Enable','off',...
        'Parent',this.h.window,...
        'Position',[821 683 150 40],...
        'String','Exporter en PDF');
      
      % Axes
      this.h.axes = UIComponent.Axes(...
        'Parent',this.h.window,...
        'Position',[56 49 913 587]);
      this.h.cursor = plot(this.h.axes,...
        [0 0],[0 this.s.size(2)],'-',...
        [0 this.s.size(1)],[0 0],'-',...
        'Color',[.6 .6 .6]);
      this.h.points = [];
      this.h.axes.NextPlot = 'add';
      this.h.axes.XLim = [0 this.s.size(1)];
      this.h.axes.XTick = 0:20:this.s.size(1);
      this.h.axes.YLim = [0 this.s.size(2)];
      this.h.axes.YTick = 0:20:this.s.size(2);
      this.h.axes.XLabel.String = 'X (mm)';
      this.h.axes.YLabel.String = 'Y (mm)';
      this.h.axes.FontSize = UIComponent.getFontSize()/1.1;
      
      % Timer
      this.h.timer = timer(...
        'ExecutionMode','FixedRate',...
        'Period',1/25,...
        'TimerFcn',@this.timerFcn);
      
      % Connect to the Phidget encoder, allowing only one instance
      try
        global PhidgetInterface_instance %#ok<TLEV>
        if PhidgetInterface_instance == 1
          error('PhidgetInterface:OneInstanceAllowed',...
            'Only one instance of the PhidgetInterface class is allowed.');
        end
        this.h.phidget = PhidgetInterface();
        this.h.readings.Title = [this.h.readings.Title ' PhidgetInterface ' this.h.phidget.IDN];
        PhidgetInterface_instance = 1;
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
      
      % Show the main window and get the JFrame
      this.h.jframe = UIComponent.getJFrame(this.h.window);
      
      try
        this.openFile();
      catch
        this.closeRequestFcn();
        return
      end
      
      start(this.h.timer);
      this.calibration();
      fprintf(this.h.file,'%% X (mm)%sY (mm)%sLabel\n',this.d.sep,this.d.sep);
      
    end
    
  end
  
  methods (Access = private)
    
    function closeRequestFcn(this,~,~)
      global PhidgetInterface_instance
      try %#ok<TRYNC>
        this.h.window.Visible = 'off';
      end
      stop(this.h.timer);
      delete(this.h.timer);
      try %#ok<TRYNC>
        fclose(this.h.file);
      end
      try %#ok<TRYNC>
        delete(this.h.phidget);
        PhidgetInterface_instance = 0;
      end
      close(this.h.window,'force');
    end
    
    function calibration(this)
      jmsgbox(sprintf('Déplacer le pantographe\nau point (0,0) mm.'),'Calibration');
      this.d.u0 = this.h.phidget.getAnalogInput(1:2);
      jmsgbox(sprintf('Déplacer le pantographe\nau point (%.0f,%.0f) mm.',this.s.size),'Calibration');
      this.d.u1 = this.h.phidget.getAnalogInput(1:2);
      jmsgbox(sprintf('Déplacer le pantographe au coin en bas\nà gauche de la zone de mesure désirée.'),'Calibration');
      this.d.offset = this.h.phidget.getAnalogInput(1:2);
    end
    
    function export(this,~)
      [f,p] = uiputfile({'*.pdf','Portable Document Format'},...
        'Exporter en PDF',this.d.path);
      if ~f
        return
      end
      this.h.jframe.setEnabled(0);
      [this.d.path,n,e] = fileparts([p f]);
      if ~strcmpi(e,'.pdf')
        e = [e '.pdf'];
      end
      f = figure(...
        'Units','centimeters',...
        'Position',[0 0 29.7 21],...
        'PaperUnits','centimeters',...
        'PaperPosition',[0 0 29.7 21],...
        'PaperSize',[29.7 21],...
        'Visible','off');
      a = axes(...
        'Units','centimeters',...
        'Parent',f,...
        'Position',[([297 210]-this.s.size)/2 this.s.size]/10);
      p = 1:this.d.label;
      for i = 1:this.d.label
        l = (this.d.points(:,3) == i);
        if any(l)
          xydata = this.d.points(l,:);
        else
          xydata = [NaN NaN];
        end
        p(i) = plot(a,...
          xydata(:,1),xydata(:,2),'x',...
          'Color',this.getPlotColor(i),'MarkerSize',6);
        a.NextPlot = 'add';
      end
      a.XLim = [0 this.s.size(1)];
      a.XTick = 0:10:this.s.size(1);
      a.XTickLabel = [];
      a.YLim = [0 this.s.size(2)];
      a.YTick = 0:10:this.s.size(2);
      a.YTickLabel = [];
      legend(p,this.d.labels,'Location','Best');
      a.Title.String = this.h.window.Name;
      a.XLabel.String = datestr(now,'dd/mm/yy HH:MM:SS');
      exportfig(f,fullfile(this.d.path,[n e]),'default','default','latex');
      close(f);
      this.h.jframe.setEnabled(1);
    end
    
    function c = getPlotColor(this,k)
      k = mod(k-1,size(this.s.color,1))+1;
      c = sscanf(this.s.color(k,:),'%2X')/255;
    end
    
    function new(this,~)
      label = jinputdlg('Nom de la série :','Nouvelle série');
      if isempty(label)
        return
      end
      k = length(this.d.labels)+1;
      this.h.points(k) = plot(this.h.axes,NaN,NaN,'x',...
        'Color',this.getPlotColor(k),'MarkerSize',8);
      this.d.labels{k} = label;
      legend(this.h.points,this.d.labels,'FontSize',UIComponent.getFontSize());
      this.d.label = k;
      this.d.xydata = [];
      this.h.save.Enable = 'on';
    end
    
    function openFile(this)
      filter = {'*.csv','Comma-separated values';...
        '*.txt','Tabulation-separated values'};
      [f,p,k] = uiputfile(filter,'Enregistrer les points sous',this.d.path);
      if ~f
        error('Laplace2D:NoFileSelected','Aucun fichier sélectionné.');
      end
      [this.d.path,n,e] = fileparts([p f]);
      switch k
        case 1
          ext = '.csv';
          this.d.sep = ',';
        case 2
          ext = '.txt';
          this.d.sep = sprintf('\t');
      end
      if ~strcmpi(e,ext)
        e = [e ext];
      end
      this.h.file = fopen(fullfile(this.d.path,[n e]),'w');
      fprintf(this.h.file,'%% %s\n%% %s\n%%\n',this.h.window.Name,datestr(now));
    end
    
    function save(this,~)
      label = this.d.labels{this.d.label};
      if any(label == ',')
        label = ['"' label '"'];
      end
      fprintf(this.h.file,'%.1f%s%.1f%s%s\n',...
        this.d.point(1),this.d.sep,...
        this.d.point(2),this.d.sep,...
        label);
      this.d.xydata(end+1,:) = this.d.point;
      this.d.points(end+1,:) = [this.d.point this.d.label];
      set(this.h.points(this.d.label),...
        'XData',this.d.xydata(:,1),...
        'YData',this.d.xydata(:,2));
      this.h.export.Enable = 'on';
    end
    
    function timerFcn(this,~,~)
      this.d.u = this.h.phidget.getAnalogInput(1:2);
      this.h.x.rawValue.String = sprintf('%.1f %%',100*this.d.u(1));
      this.h.y.rawValue.String = sprintf('%.1f %%',100*this.d.u(2));
      if isfield(this.d,'offset')
        this.d.point = round(2*this.s.size.*(this.d.u-this.d.offset)./(this.d.u1-this.d.u0))/2;
        this.h.x.value.String = sprintf('%.1f mm',this.d.point(1));
        this.h.y.value.String = sprintf('%.1f mm',this.d.point(2));
        this.h.cursor(1).XData = this.d.point(1)*[1 1];
        this.h.cursor(2).YData = this.d.point(2)*[1 1];
      end
    end
    
  end
  
end
