%
%  BK_2034.m
%
%  Created by Léa Strobino.
%  Copyright 2015 hepia. All rights reserved.
%

classdef BK_2034 < handle
  
  properties (SetAccess = private)
    IDN
  end
  
  properties (Access = private)
    tty
  end
  
  properties (Constant, Access = private)
    DisplayFunction = {'TIME CH.A','TIME CH.B','TIME A VS B','ENH TIME CH.A',...
      'ENH TIME CH.B','ENH TIME A VS B','PROB DENS CH.A','PROB DENS CH.B',...
      'PROB DIST CH.A','PROB DIST CH.B','INST SPEC CH.A','INST SPEC CH.B',...
      'ENH SPEC CH.A','ENH SPEC CH.B','AUTOSPEC CH.A','AUTOSPEC CH.B','CROSS-SPEC',...
      'FREQ RESP H1','1/FREQ RESP H1','FREQ RESP H2','1/FREQ RESP H2','COHERENCE',...
      'SIG/NOISE RATIO','COHERENT POWER','NONCOHER POWER','AUTO CORR CH.A',...
      'AUTO CORR CH.B','CROSS CORR','IMPULSE RESP','SOUND INTENSITY',...
      'CEPSTRUM CH.A','CEPSTRUM CH.B','LIFT SPEC CH.A','LIFT SPEC CH.B'};
    FunctionCoordinates = {'Real','Imaginary','Magnitude','Phase','Nyquist','Nichols'};
    MeasurementChannel = {'CH.A','CH.B','DUAL-CH.'};
    MeasurementMode = {'SPECTRUM AVERAGING','SPECTRUM AVERAGING ZERO PAD',...
      'SIGNAL ENHANCEMENT','AMPLITUDE PROBABILITY'};
  end
  
  methods
    
    function this = BK_2034(address)
      this.tty = GPIBlpt(address);
      try
        this.IDN = this.query('*IDN?');
        this.goToLocal();
        this.tty.Timeout = 3;
      catch e
        e = addCause(MException('BK_2034:CommunicationError',...
          'Unable to open the GPIB connection.'),e);
        throw(e);
      end
      if isempty(regexp(this.IDN,'^BK,\+02034,','once'))
        error('BK_2034:InstrumentNotFound',...
          'The instrument at GPIB address %d is not a Brüel & Kjær 2034.',address);
      end
    end
    
    function delete(this)
      try %#ok<TRYNC>
        this.goToLocal();
      end
    end
    
    function s = getScreen(this)
      fprintf(this.tty,'DP');
      d = fread(this.tty);
      this.goToLocal();
      d = d(8:18567);
      d = [bitand(d,128) bitand(d,64) bitand(d,32) bitand(d,16) ...
        bitand(d,8) bitand(d,4) bitand(d,2) bitand(d,1)] == 0;
      s = reshape(d',512,290)';
    end
    
    function [x,A,B,info] = getTrace(this)
      info.Measurement = [this.MeasurementChannel{this.query('EM? MC','%d')+1} ...
        ' ' this.MeasurementMode{this.query('EM? MM','%d')+1}];
      s = this.query('EM? FS','%f');
      c = this.query('EM? CF','%f');
      if isempty(c)
        x = 0:s/800:s;
      else
        x = (c-s/2):s/800:(c+s/2);
      end
      this.query('UD');
      info.XAxisLog = logical(this.query('ED? XL','%d'));
      info.XLabel = 'Frequency (Hz)';
      for i = 'AB'
        FU = this.query('ED? FU','%d');
        FC = this.query('ED? FC','%d');
        if ~((FU >= 10 && FU <= 24) || FU == 29 || FU == 32 || FU == 33)
          this.goToLocal();
          error('BK_2034:UnsupportedDisplayFunction',...
            'Unsupported display function: %s.',this.DisplayFunction{FU+1});
        end
        label = this.DisplayFunction{FU+1};
        if ~isempty(FC)
          label = sprintf('%s: %s',label,this.FunctionCoordinates{FC+1});
        end
        try
          fprintf(this.tty,'AB? INCREASED_RESOLUTION');
          d = fread(this.tty);
        catch
          this.clearDevice();
          this.goToLocal();
          error('BK_2034:NoValidDataFile',...
            'No valid data file.');
        end
        b = d([9:4:end-1 ; 8:4:end-1]);
        e = d(10:4:end-1);
        d = double(typecast(b(:),'int16')).*10.^double(typecast(e,'int8'));
        if FC == 3
          label = sprintf('%s (°)',label);
        else
          if this.query('ED? YU','%d')
            label = sprintf('%s (dB)',label);
          end
        end
        if i == 'A'
          A = d;
          info.ALabel = label;
          this.query('LD');
        else
          B = d;
          info.BLabel = label;
          this.query('UD');
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
