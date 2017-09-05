%
%  BK_2035.m
%
%  Created by Léa Strobino.
%  Copyright 2015 hepia. All rights reserved.
%

classdef BK_2035 < handle
  
  properties (SetAccess = private)
    IDN
  end
  
  properties (Access = private)
    tty
    rtifc
  end
  
  properties (Constant, Access = private)
    DisplayFunction = {'TIME','COMPL TIME','ORBIT','ENH TIME','ENH ORBIT',...
      'MONITOR SIGNAL','AMPL PROBAB','FOURIER SP','ENH SPEC','COMPL SPEC',...
      'AUTOSPEC','CROSS-SPEC','FREQ RESP','1/FREQ RESP','COHERENCE',...
      'SIG/NOISE RATIO','COHERENT POWER','NONCOHER POWER','AUTOCORR',...
      'CROSSCORR','IMPULSE RESP','SOUND INTENSITY','CEPSTRUM','LIFT SPEC'};
    FunctionCoordinates = {'Real','Imaginary','Magnitude','Phase','Nyquist','Nichols'};
    MeasurementChannel = {'CH.A','CH.B','DUAL-CH.','MULTICH.'};
    MeasurementMode = {'SPECTRUM AVERAGING','SPECTRUM AVERAGING ZERO PAD',...
      '1/N OCTAVE SPECTRUM AVERAGING','MULTI','TIME CAPTURE','TIME HISTORY',...
      'SIGNAL ENHANCEMENT','AMPLITUDE PROBABILITY'};
  end
  
  methods
    
    function this = BK_2035(address)
      this.tty = GPIBlpt(address);
      try
        this.IDN = this.query('*IDN?');
        this.goToLocal();
        this.tty.Timeout = 3;
      catch e
        e = addCause(MException('BK_2035:CommunicationError',...
          'Unable to open the GPIB connection.'),e);
        throw(e);
      end
      if ~strcmp(this.IDN,'B&K 3550')
        error('BK_2035:InstrumentNotFound',...
          'The instrument at GPIB address %d is not a Brüel & Kjær 2035.',address);
      end
      d = which('-all','rtifc');
      d = cd(fileparts(d{1}));
      this.rtifc = @rtifc;
      cd(d);
    end
    
    function delete(this)
      try %#ok<TRYNC>
        this.goToLocal();
      end
    end
    
    function s = getScreen(this)
      fprintf(this.tty,'DP TI,BI');
      d = fread(this.tty);
      this.goToLocal();
      tmp = tempname();
      h = fopen(tmp,'w');
      fwrite(h,d(1:end-1));
      fclose(h);
      s = this.rtifc(struct('filename',tmp,'index',1,'pixelregion',[])) == 0;
      delete(tmp);
    end
    
    function [x,A,B,info] = getTrace(this)
      if ~this.query('ST? CV','%d')
        this.goToLocal();
        error('BK_2035:CursorValuesNotValid',...
          'Cursor values are not valid.');
      end
      info.Measurement = [this.MeasurementChannel{this.query('EM? MCHA','%d')} ...
        ' ' this.MeasurementMode{this.query('EM? MMOD','%d')}];
      n = this.query('EM? SLIN','%d');
      s = this.query('EM? FSPA','%f');
      c = this.query('EM? CFRE','%f');
      if isempty(c)
        x = 0:s/n:s;
      else
        x = (c-s/2):s/n:(c+s/2);
      end
      this.query('UP');
      info.XAxisLog = (this.query('ED? XLLO','%d') == 25);
      info.XLabel = 'Frequency (Hz)';
      for i = 'AB'
        DFUN = this.query('ED? DFUN','%d');
        DFES = this.query('ED? DFES','%d');
        DFCH = this.query('ED? DFCH','%d');
        FCCO = this.query('ED? FCOO','%d');
        if ~((DFUN >= 8 && DFUN <= 18) || DFUN == 22 || DFUN == 24)
          this.goToLocal();
          error('BK_2035:UnsupportedDisplayFunction',...
            'Unsupported display function: %s.',this.DisplayFunction{DFUN});
        end
        label = this.DisplayFunction{DFUN};
        if ~isempty(DFES)
          label = sprintf('%s H%d',label,DFES);
        end
        if DFCH == 2
          label = sprintf('%s CH.A',label);
        elseif DFCH == 3
          label = sprintf('%s CH.B',label);
        end
        if ~isempty(FCCO)
          label = sprintf('%s: %s',label,this.FunctionCoordinates{FCCO});
        end
        fprintf(this.tty,'CV? ALL_MAIN,BINARY_2_FORMAT,NO_STATUS');
        d = fread(this.tty);
        if FCCO == 4
          d = typecast(d(end-1:-1:1),'int32');
          d = double(d(end:-1:1))*45/131072;
          label = sprintf('%s (°)',label);
        else
          d = typecast(d(end-1:-1:1),'int16');
          d = double(d(end:-2:2))./32768.*2.^double(d(end-1:-2:1));
          if this.query('ED? YLLA','%d') == 2
            label = sprintf('%s (dB)',label);
          end
        end
        if i == 'A'
          A = d;
          info.ALabel = label;
          this.query('LO');
        else
          B = d;
          info.BLabel = label;
          this.query('UP');
        end
      end
      this.goToLocal();
    end
    
    function r = query(this,q,format)
      fprintf(this.tty,q);
      if any(q == '?')
        if nargin < 3
          r = fscanf(this.tty);
          r = r(1:end-1);
        else
          r = fscanf(this.tty,format);
        end
      end
    end
    
    function clearDevice(this)
      this.tty.clrdevice();
    end
    
    function goToLocal(this)
      this.tty.gotolocal();
    end
    
  end
  
end
