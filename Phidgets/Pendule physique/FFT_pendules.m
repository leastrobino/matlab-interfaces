%
%  FFT_pendules.m
%
%  Created by Léa Strobino.
%  Copyright 2016 hepia. All rights reserved.
%

classdef FFT_pendules < handle
  
  properties (Access = private)
    h
    s
    d
  end
  
  methods
    
    function this = FFT_pendules()
      
      % Settings
      this.s.fe = 1E3;           % import sampling frequency
      this.s.method = 'nearest'; % import interpolation method
      
      % Default data
      this.d.f = NaN;
      this.d.fft = NaN;
      this.d.path = UIComponent.getUserDirectory();
      this.d.tool = 0;
      
      % Main window
      this.h.window = UIComponent.Figure(...
        'CloseRequestFcn',@this.closeRequestFcn,...
        'Name','FFT pour pendules  |  Laboratoire de physique  |  hepia',...
        'Size',[1024 768]);
      
      % File
      this.h.file = UIComponent.Label(...
        'FontSize',14,...
        'Parent',this.h.window,...
        'Position',[65 708 630 35]);
      
      % Actions
      this.h.import = UIComponent.Button(...
        'Callback',@this.import,...
        'Parent',this.h.window,...
        'Position',[715 708 120 35],...
        'String','Importer');
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
      this.plot();
      
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
        'UIContextMenu',this.h.contextmenu,...
        'Enable','on');
      
      % Show the main window
      this.h.window.Visible = 'on';
      
    end
    
  end
  
  methods (Access = private)
    
    function closeRequestFcn(this,~,~)
      try %#ok<TRYNC>
        this.h.window.Visible = 'off';
      end
      close(this.h.window,'force');
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
      fprintf(f,'%% Fréquence (Hz)%s',sprintf(...
        sprintf('%sAmplitude relative %%.0f (-)',sep),1:size(this.d.fft,2)));
      for i = 1:length(this.d.f)
        fprintf(f,'\n%.9g',this.d.f(i));
        fprintf(f,sprintf('%s%%.9g',sep),this.d.fft(i,:));
      end
      fprintf(f,'\n');
      fclose(f);
    end
    
    function w = hann(~,n)
      w = .5-.5*cos(2*pi*(0:(n+rem(n,2))/2-1)'/(n-1));
      if mod(n,2)
        w = [w;w(end-1:-1:1)];
      else
        w = [w;w(end:-1:1)];
      end
    end
    
    function import(this,~)
      filter = {'*.csv','Comma-separated values';...
        '*.txt','Tabulation-separated values'};
      [f,p] = uigetfile(filter,'Ouvrir un fichier de mesures',this.d.path);
      if ~f
        return
      end
      [p,n,e] = fileparts([p f]);
      this.d.path = [p '/'];
      try
        data = readcsv(fullfile(this.d.path,[n e]));
        t = data(:,1);
        p = data(:,2:end);
        dt = min(diff(t));
        interp = '';
        if ~all(abs(diff(t)-dt) < 1E-6)
          dt = 1/this.s.fe;
          t = t(1):dt:t(end);
          p = zeros(length(t),size(p,2));
          for i = 1:size(p,2)
            f = griddedInterpolant(data(:,1),data(:,i+1),this.s.method);
            p(:,i) = f(t);
          end
          interp = [' (interpolé à ' double2unit(this.s.fe,3,'Hz') ')'];
        end
        p = bsxfun(@times,p,this.hann(size(p,1)));
        this.d.f = linspace(0,1/dt,length(t));
        this.d.f = this.d.f(1:floor(end/2));
        this.d.fft = abs(fft(p));
        this.d.fft = this.d.fft(1:floor(end/2),:);
        this.plot();
        this.h.file.String = ['Fichier : ' n e interp];
        this.h.export.Enable = 'on';
      catch e
        jerrordlg(e.message);
        this.d.f = NaN;
        this.d.fft = NaN;
        this.plot();
      end
    end
    
    function plot(this)
      plot(this.h.axes,this.d.f,this.d.fft,'LineWidth',1.2);
      if ~any(isnan(this.d.f))
        legend(this.h.axes,...
          sprintfc('Pendule %.0f',1:size(this.d.fft,2)),...
          'FontSize',UIComponent.getFontSize(),...
          'Location','best');
      end
      this.h.axes.XGrid = 'on';
      this.h.axes.YGrid = 'on';
      this.h.axes.XLabel.String = 'Fréquence (Hz)';
      this.h.axes.YLabel.String = 'Amplitude relative (-)';
      this.h.axes.FontSize = UIComponent.getFontSize()/1.1;
      if this.d.tool
        this.setTool();
      end
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
    
    function s = updateCursor(~,~,e)
      s = sprintf('Fréquence : %.3f Hz\nAmplitude : %.1f',e.Position);
    end
    
    function zoomDefault(this,~,~)
      this.h.axes.XLimMode = 'auto';
      this.h.axes.YLimMode = 'auto';
    end
    
  end
  
end
