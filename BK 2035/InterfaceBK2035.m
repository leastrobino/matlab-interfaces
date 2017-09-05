%
%  InterfaceBK2035.m
%
%  Created by Léa Strobino.
%  Copyright 2015 hepia. All rights reserved.
%

classdef InterfaceBK2035 < handle
  
  properties (Access = private)
    h
    s
    d
  end
  
  methods
    
    function this = InterfaceBK2035()
      
      % Settings
      this.s.address = 25; % GPIB address
      this.s.color = '0072BD'; % plot color
      
      % Default data
      this.d.appdir = [fileparts(mfilename('fullpath')) filesep];
      this.d.path = UIComponent.getUserDirectory();
      this.d.export = 0;
      
      % Main window
      this.h.window = UIComponent.Figure(...
        'CloseRequestFcn',@this.closeRequestFcn,...
        'Name','Interface Brüel & Kjær 2035  |  hepia',...
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
        'Icon',UIComponent.createIcon([this.d.appdir 'bk.png']),...
        'Parent',this.h.window,...
        'Position',[855 628 140 110]);
      
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
      
      % Connect to the Brüel & Kjær 2035, allowing only one instance
      try
        global bk2035_instance %#ok<TLEV>
        if bk2035_instance == 1
          error('InterfaceBK2035:OneInstanceAllowed',...
            'Only one instance of the Brüel & Kjær 2035 interface is allowed.');
        end
        this.h.bk2035 = BK_2035(this.s.address);
        bk2035_instance = 1;
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
      global bk2035_instance
      try %#ok<TRYNC>
        this.h.window.Visible = 'off';
      end
      try %#ok<TRYNC>
        delete(this.h.bk2035);
        bk2035_instance = 0;
      end
      close(this.h.window,'force');
    end
    
    % Traces
    
    function getTrace(this,~,~,~)
      this.h.window.Pointer = 'watch';
      drawnow();
      try
        [this.d.x,this.d.trace_A,this.d.trace_B,this.d.info] = this.h.bk2035.getTrace();
      catch e
        this.h.window.Pointer = 'arrow';
        jwarndlg(e.message);
        return
      end
      this.h.trace_A(1).XData = this.d.x;
      this.h.trace_A(1).YData = this.d.trace_A;
      this.h.trace_B(1).XData = this.d.x;
      this.h.trace_B(1).YData = this.d.trace_B;
      n = length(this.d.x)-1;
      this.autoScale();
      set(this.h.XLabel,'String',this.d.info.XLabel);
      this.h.ALabel.String = this.d.info.ALabel;
      this.h.BLabel.String = this.d.info.BLabel;
      this.d.parameters{1} = ['Measurement: ' this.d.info.Measurement];
      this.d.parameters{2} = sprintf('%d lines',n);
      this.d.parameters{3} = ['\Delta{}f = ' double2unit((this.d.x(end)-this.d.x(1))/n,3,'Hz')];
      this.h.parameters.String = strjoin(this.d.parameters,', ');
      this.d.export = 1;
      this.h.window.Pointer = 'arrow';
    end
    
    function autoScale(this)
      if this.d.info.XAxisLog
        set([this.h.axes_A this.h.axes_B],...
          'XLimMode','auto',...
          'YLimMode','auto',...
          'XScale','log');
      else
        set([this.h.axes_A this.h.axes_B],...
          'XLim',[this.d.x(1) this.d.x(end)],...
          'YLimMode','auto',...
          'XScale','linear');
      end
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
          fprintf(f,'%% %s\n',this.d.parameters{:});
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
          if this.d.info.XAxisLog
            set(a,'XScale','log');
          end
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
            img = this.h.bk2035.getScreen();
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
