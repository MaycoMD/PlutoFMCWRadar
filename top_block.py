#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: PlutoCWradar
# GNU Radio version: 3.8.2.0

from distutils.version import StrictVersion

if __name__ == '__main__':
    import ctypes
    import sys
    if sys.platform.startswith('linux'):
        try:
            x11 = ctypes.cdll.LoadLibrary('libX11.so')
            x11.XInitThreads()
        except:
            print("Warning: failed to XInitThreads()")

from PyQt5 import Qt
from gnuradio import qtgui
from gnuradio.filter import firdes
import sip
from gnuradio import analog
from gnuradio import audio
from gnuradio import blocks
from gnuradio import filter
from gnuradio import gr
import sys
import signal
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio import eng_notation
from gnuradio.qtgui import Range, RangeWidget
import iio

from gnuradio import qtgui

class top_block(gr.top_block, Qt.QWidget):

    def __init__(self):
        gr.top_block.__init__(self, "PlutoCWradar")
        Qt.QWidget.__init__(self)
        self.setWindowTitle("PlutoCWradar")
        qtgui.util.check_set_qss()
        try:
            self.setWindowIcon(Qt.QIcon.fromTheme('gnuradio-grc'))
        except:
            pass
        self.top_scroll_layout = Qt.QVBoxLayout()
        self.setLayout(self.top_scroll_layout)
        self.top_scroll = Qt.QScrollArea()
        self.top_scroll.setFrameStyle(Qt.QFrame.NoFrame)
        self.top_scroll_layout.addWidget(self.top_scroll)
        self.top_scroll.setWidgetResizable(True)
        self.top_widget = Qt.QWidget()
        self.top_scroll.setWidget(self.top_widget)
        self.top_layout = Qt.QVBoxLayout(self.top_widget)
        self.top_grid_layout = Qt.QGridLayout()
        self.top_layout.addLayout(self.top_grid_layout)

        self.settings = Qt.QSettings("GNU Radio", "top_block")

        try:
            if StrictVersion(Qt.qVersion()) < StrictVersion("5.0.0"):
                self.restoreGeometry(self.settings.value("geometry").toByteArray())
            else:
                self.restoreGeometry(self.settings.value("geometry"))
        except:
            pass

        ##################################################
        # Variables
        ##################################################
        self.tx_attenuation = tx_attenuation = 30
        self.tone_freq = tone_freq = 500
        self.samp_rate = samp_rate = int(2e6)
        self.rx_gain = rx_gain = 64
        self.lo_freq = lo_freq = int(4e9)
        self.buf_size = buf_size = 13768
        self.audio_gain = audio_gain = 1

        ##################################################
        # Blocks
        ##################################################
        self._tx_attenuation_range = Range(0, 100, 1, 30, 200)
        self._tx_attenuation_win = RangeWidget(self._tx_attenuation_range, self.set_tx_attenuation, 'tx_attenuation', "counter_slider", float)
        self.top_grid_layout.addWidget(self._tx_attenuation_win)
        self._tone_freq_range = Range(-2e3, 2e3, 1, 500, 200)
        self._tone_freq_win = RangeWidget(self._tone_freq_range, self.set_tone_freq, 'tone_freq', "counter_slider", float)
        self.top_grid_layout.addWidget(self._tone_freq_win)
        self._rx_gain_range = Range(0, 70, 1, 64, 200)
        self._rx_gain_win = RangeWidget(self._rx_gain_range, self.set_rx_gain, 'rx_gain', "counter_slider", float)
        self.top_grid_layout.addWidget(self._rx_gain_win)
        self._audio_gain_range = Range(0, 10, 1, 1, 200)
        self._audio_gain_win = RangeWidget(self._audio_gain_range, self.set_audio_gain, 'audio_gain', "counter_slider", float)
        self.top_grid_layout.addWidget(self._audio_gain_win)
        self.qtgui_waterfall_sink_x_0 = qtgui.waterfall_sink_c(
            1024*8, #size
            firdes.WIN_HAMMING, #wintype
            0, #fc
            samp_rate/50, #bw
            "", #name
            1 #number of inputs
        )
        self.qtgui_waterfall_sink_x_0.set_update_time(0.10)
        self.qtgui_waterfall_sink_x_0.enable_grid(False)
        self.qtgui_waterfall_sink_x_0.enable_axis_labels(True)



        labels = ['', '', '', '', '',
                  '', '', '', '', '']
        colors = [0, 0, 0, 0, 0,
                  0, 0, 0, 0, 0]
        alphas = [1.0, 1.0, 1.0, 1.0, 1.0,
                  1.0, 1.0, 1.0, 1.0, 1.0]

        for i in range(1):
            if len(labels[i]) == 0:
                self.qtgui_waterfall_sink_x_0.set_line_label(i, "Data {0}".format(i))
            else:
                self.qtgui_waterfall_sink_x_0.set_line_label(i, labels[i])
            self.qtgui_waterfall_sink_x_0.set_color_map(i, colors[i])
            self.qtgui_waterfall_sink_x_0.set_line_alpha(i, alphas[i])

        self.qtgui_waterfall_sink_x_0.set_intensity_range(-140, 10)

        self._qtgui_waterfall_sink_x_0_win = sip.wrapinstance(self.qtgui_waterfall_sink_x_0.pyqwidget(), Qt.QWidget)
        self.top_grid_layout.addWidget(self._qtgui_waterfall_sink_x_0_win)
        self.qtgui_freq_sink_x_2 = qtgui.freq_sink_c(
            1024*8, #size
            firdes.WIN_BLACKMAN_hARRIS, #wintype
            0, #fc
            samp_rate/50, #bw
            "", #name
            1
        )
        self.qtgui_freq_sink_x_2.set_update_time(0.10)
        self.qtgui_freq_sink_x_2.set_y_axis(-140, 10)
        self.qtgui_freq_sink_x_2.set_y_label('Relative Gain', 'dB')
        self.qtgui_freq_sink_x_2.set_trigger_mode(qtgui.TRIG_MODE_FREE, 0.0, 0, "")
        self.qtgui_freq_sink_x_2.enable_autoscale(False)
        self.qtgui_freq_sink_x_2.enable_grid(False)
        self.qtgui_freq_sink_x_2.set_fft_average(1.0)
        self.qtgui_freq_sink_x_2.enable_axis_labels(True)
        self.qtgui_freq_sink_x_2.enable_control_panel(False)



        labels = ['BRF', '', '', '', '',
            '', '', '', '', '']
        widths = [1, 1, 1, 1, 1,
            1, 1, 1, 1, 1]
        colors = ["blue", "red", "green", "black", "cyan",
            "magenta", "yellow", "dark red", "dark green", "dark blue"]
        alphas = [1.0, 1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0, 1.0]

        for i in range(1):
            if len(labels[i]) == 0:
                self.qtgui_freq_sink_x_2.set_line_label(i, "Data {0}".format(i))
            else:
                self.qtgui_freq_sink_x_2.set_line_label(i, labels[i])
            self.qtgui_freq_sink_x_2.set_line_width(i, widths[i])
            self.qtgui_freq_sink_x_2.set_line_color(i, colors[i])
            self.qtgui_freq_sink_x_2.set_line_alpha(i, alphas[i])

        self._qtgui_freq_sink_x_2_win = sip.wrapinstance(self.qtgui_freq_sink_x_2.pyqwidget(), Qt.QWidget)
        self.top_grid_layout.addWidget(self._qtgui_freq_sink_x_2_win)
        self.low_pass_filter_0 = filter.fir_filter_ccf(
            int(samp_rate/40000),
            firdes.low_pass(
                1,
                samp_rate,
                tone_freq*2,
                250,
                firdes.WIN_HAMMING,
                6.76))
        self.iio_pluto_source_1 = iio.pluto_source('192.168.2.1', lo_freq, samp_rate, 20000000, buf_size, True, True, True, 'manual', rx_gain, '', True)
        self.iio_pluto_sink_0 = iio.pluto_sink('192.168.2.1', lo_freq, samp_rate, 20000000, buf_size, False, tx_attenuation, '', True)
        self.blocks_multiply_const_vxx_0 = blocks.multiply_const_cc(audio_gain)
        self.blocks_complex_to_real_0 = blocks.complex_to_real(1)
        self.band_reject_filter_0 = filter.fir_filter_ccf(
            1,
            firdes.band_reject(
                1,
                samp_rate/50,
                tone_freq-5,
                tone_freq+5,
                5,
                firdes.WIN_HAMMING,
                6.76))
        self.audio_sink_0 = audio.sink(48000, '', True)
        self.analog_sig_source_x_0 = analog.sig_source_c(samp_rate, analog.GR_COS_WAVE, tone_freq, 1, 0, 0)



        ##################################################
        # Connections
        ##################################################
        self.connect((self.analog_sig_source_x_0, 0), (self.iio_pluto_sink_0, 0))
        self.connect((self.band_reject_filter_0, 0), (self.blocks_multiply_const_vxx_0, 0))
        self.connect((self.blocks_complex_to_real_0, 0), (self.audio_sink_0, 0))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.blocks_complex_to_real_0, 0))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.qtgui_freq_sink_x_2, 0))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.qtgui_waterfall_sink_x_0, 0))
        self.connect((self.iio_pluto_source_1, 0), (self.low_pass_filter_0, 0))
        self.connect((self.low_pass_filter_0, 0), (self.band_reject_filter_0, 0))


    def closeEvent(self, event):
        self.settings = Qt.QSettings("GNU Radio", "top_block")
        self.settings.setValue("geometry", self.saveGeometry())
        event.accept()

    def get_tx_attenuation(self):
        return self.tx_attenuation

    def set_tx_attenuation(self, tx_attenuation):
        self.tx_attenuation = tx_attenuation
        self.iio_pluto_sink_0.set_params(self.lo_freq, self.samp_rate, 20000000, self.tx_attenuation, '', True)

    def get_tone_freq(self):
        return self.tone_freq

    def set_tone_freq(self, tone_freq):
        self.tone_freq = tone_freq
        self.analog_sig_source_x_0.set_frequency(self.tone_freq)
        self.band_reject_filter_0.set_taps(firdes.band_reject(1, self.samp_rate/50, self.tone_freq-5, self.tone_freq+5, 5, firdes.WIN_HAMMING, 6.76))
        self.low_pass_filter_0.set_taps(firdes.low_pass(1, self.samp_rate, self.tone_freq*2, 250, firdes.WIN_HAMMING, 6.76))

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.analog_sig_source_x_0.set_sampling_freq(self.samp_rate)
        self.band_reject_filter_0.set_taps(firdes.band_reject(1, self.samp_rate/50, self.tone_freq-5, self.tone_freq+5, 5, firdes.WIN_HAMMING, 6.76))
        self.iio_pluto_sink_0.set_params(self.lo_freq, self.samp_rate, 20000000, self.tx_attenuation, '', True)
        self.iio_pluto_source_1.set_params(self.lo_freq, self.samp_rate, 20000000, True, True, True, 'manual', self.rx_gain, '', True)
        self.low_pass_filter_0.set_taps(firdes.low_pass(1, self.samp_rate, self.tone_freq*2, 250, firdes.WIN_HAMMING, 6.76))
        self.qtgui_freq_sink_x_2.set_frequency_range(0, self.samp_rate/50)
        self.qtgui_waterfall_sink_x_0.set_frequency_range(0, self.samp_rate/50)

    def get_rx_gain(self):
        return self.rx_gain

    def set_rx_gain(self, rx_gain):
        self.rx_gain = rx_gain
        self.iio_pluto_source_1.set_params(self.lo_freq, self.samp_rate, 20000000, True, True, True, 'manual', self.rx_gain, '', True)

    def get_lo_freq(self):
        return self.lo_freq

    def set_lo_freq(self, lo_freq):
        self.lo_freq = lo_freq
        self.iio_pluto_sink_0.set_params(self.lo_freq, self.samp_rate, 20000000, self.tx_attenuation, '', True)
        self.iio_pluto_source_1.set_params(self.lo_freq, self.samp_rate, 20000000, True, True, True, 'manual', self.rx_gain, '', True)

    def get_buf_size(self):
        return self.buf_size

    def set_buf_size(self, buf_size):
        self.buf_size = buf_size

    def get_audio_gain(self):
        return self.audio_gain

    def set_audio_gain(self, audio_gain):
        self.audio_gain = audio_gain
        self.blocks_multiply_const_vxx_0.set_k(self.audio_gain)





def main(top_block_cls=top_block, options=None):

    if StrictVersion("4.5.0") <= StrictVersion(Qt.qVersion()) < StrictVersion("5.0.0"):
        style = gr.prefs().get_string('qtgui', 'style', 'raster')
        Qt.QApplication.setGraphicsSystem(style)
    qapp = Qt.QApplication(sys.argv)

    tb = top_block_cls()

    tb.start()

    tb.show()

    def sig_handler(sig=None, frame=None):
        Qt.QApplication.quit()

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    timer = Qt.QTimer()
    timer.start(500)
    timer.timeout.connect(lambda: None)

    def quitting():
        tb.stop()
        tb.wait()

    qapp.aboutToQuit.connect(quitting)
    qapp.exec_()

if __name__ == '__main__':
    main()
