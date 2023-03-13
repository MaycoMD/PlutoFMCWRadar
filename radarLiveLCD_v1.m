clc;
clear all;
% ========================================================================
% -------------- PLUTO PARAMETERS ---------
% Power DC Input (USB):4.5 V to 5.5 V
% ADC and DAC Sample Rate: 65.2 kSPS to 61.44 MSPS
% ADC and DAC Resolution: 12 bits
% Frequency Accuracy: ±25 ppm
% Tuning Range: 325 MHz to 3800 MHz
% Antennas Bandwidth: 824 MHz to ~894 MHz / 1710 MHz to ~2170 MHz
% Up to 20 MHz of instantaneous bandwidth (complex I/Q)
% Tx Power Output: 7 dBm
% Rx Noise Figure: <3.5 dB
% Rx and Tx Modulation Accuracy (EVM): –34 dB (2%)
% RF Shielding: None
% Digital USB2.0 On-the-Go
% Core: Single ARM Cortex®-A9 @ 667 MHz
% FPGA Logic Cells: 28k
% DSP Slices:80
% DDR3L: 4 Gb (512 MB)
% QSPI Flash: 256 Mb (32 MB)
% Temperature: 10°C to 40°C

% ------------- RADAR PARAMETERS ---------
c = 3e8;        % Velocidad de la luz [m/s]
fc = 2.1e9;     % Frecuencia de la portadora [Hz]
tau = 0.001;    % Duración del pulso [s]
PRI = 1*tau;    % Pulse Repetition Interval [s]
beta = 500e3;   % Ancho de banda [Hz]
fs = 2.0e6;     % Frecuencia de muestreo de la banda base [S/s]
% "Overflows generally come from running at too high a sample rate
% for the computer to handle (MATLAB) or for the USB interface to
% transfer."
% - Travis

L = fs*PRI;             % Número de celdas de rango
delta_R = c/(2*beta);   % Resolución en rango [m]: primer cero de la función ambigüedad
R_unam = c*PRI/2;       % Rango sin ambigüedad [m]
celda_R = c/(2*fs);     % Tamaño de la celda de rango [m]
delta_f = 1/tau;        % Resolución en frecuencia [Hz]: primer cero de la función ambigüedad

frameSize = PRI*fs;  % frameSize = SamplesPerFrame = 1 pulso por frame
if(frameSize<3660)
    warning('Using less than 3660 samples per frame can yield poor performance')
end

% ========================================================================
% -------------- RADIO ---------------
% Set up receiver
rx=sdrrx('Pluto',...
         'CenterFrequency',fc,...
         'GainSource','AGC Fast Attack',...
         'ChannelMapping',1,...
         'BasebandSampleRate',fs,...
         'OutputDataType','int16',...
         'SamplesPerFrame',frameSize,...
         'ShowAdvancedProperties',true,...
         'BISTLoopbackMode','Disabled');%'Digital Tx -> Digital Rx');

% Set up transmitter
tx = sdrtx('Pluto',...
           'CenterFrequency',fc,...
           'Gain',-30,...
           'ChannelMapping',1,...
           'BasebandSampleRate',fs,...
           'ShowAdvancedProperties',true,...
           'BISTLoopbackMode','Disabled');%'Digital Tx -> Digital Rx');

% ========================================================================
% ---------------- WAVE ----------------
% Generate wave
t = (0:1/fs:PRI-(1/fs)).'; % Tiempo de muestreo para un pulso
chirp = zeros(length(t),1);
chirp = exp(1i*pi*beta*t.^2/tau).*((0 <= t) & (t <= tau));

%tx_inicial = zeros(size(t));
%tx.transmitRepeat(tx_inicial);

% Conformación del filtro adaptado
Lp = 2^(nextpow2(L)+1);
h_t = chirp; % Filtro adaptado a partir de una señal chirp de referencia
H_f = conj(fft(h_t,Lp)); % Espectro del filtro adaptado

%Pass data through radio
tx.release();
tx.transmitRepeat(chirp); 

% ======================================================================== 
% -------------- ANALISYS -------------------
% Process new live data
figure();
    
while(1)
    %tic
    X_f = fft(rx(),Lp);
    Y_f = X_f.*H_f;
    Y_t = ifft(Y_f,Lp);
    Y_t = abs(Y_t(1:L));
    plot(t*1000,Y_t);
    axis([0 tau*1000 0 1*10^7]);
    title('Respuesta del Filtro Adaptado');
    xlabel('Tiempo [ms]');
    ylabel('Amplitud');
    %time = toc;
    %pause(0.1-time);
    %toc 
end