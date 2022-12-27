from PyQt5.QtWidgets import QMainWindow, QApplication, QFileDialog
from UI import Ui_MainWindow
from PyQt5.QtWidgets import QSizePolicy
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.pyplot import MultipleLocator
from serial import Serial, EIGHTBITS, PARITY_NONE, STOPBITS_ONE
from sys import argv
from PyQt5.Qt import QUrl
from PyQt5.QtMultimedia import QMediaPlayer, QMediaContent, QMediaPlaylist
import math
from PyQt5.QtGui import QIcon
import struct
import time

class EQ_plot(FigureCanvas):
    def __init__(self, parent = None, width = 5, height = 4, dpi = 100, data = [0]*15, type = None, color = 'blue'):
        self.data = data
        self.type = type
        self.color = color
        fig = Figure(figsize=(width, height), dpi=dpi)
        self.axes = fig.add_subplot(111)
        FigureCanvas.__init__(self, fig)
        self.setParent(parent)
        FigureCanvas.setSizePolicy(self, QSizePolicy.Expanding, QSizePolicy.Expanding)
        FigureCanvas.updateGeometry(self)
        self.plot()
    def plot(self):
        x = [0, 1378, 2756, 4135, 5513, 6891, 8269, 9647, 11025, 12403, 13781, 15160, 16538, 17916, 19294]
        self.axes.set_xlim([0, 20000])
        self.axes.set_xlabel('dB')
        self.axes.set_ylim([0, 90])
        self.axes.set_ylabel('Hz')
        self.axes.bar(x, self.data, color = self.color, width = 100)
        self.axes.set_title(self.type)
        self.draw()

class NG_plot(FigureCanvas):
    def __init__(self, parent = None, width = 5, height = 4, dpi = 100, threshold = 5):
        self.data = [0]*threshold + list(range(threshold, 91))
        fig = Figure(figsize = (width, height), dpi = dpi)
        self.axes = fig.add_subplot(111)
        FigureCanvas.__init__(self, fig)
        self.setParent(parent)
        FigureCanvas.setSizePolicy(self, QSizePolicy.Expanding, QSizePolicy.Expanding)
        FigureCanvas.updateGeometry(self)
        self.plot()
    def plot(self):
        x = list(range(0, 91))
        self.axes.set_xlim([0, 90])
        self.axes.set_ylim([0, 90])
        self.axes.xaxis.set_major_locator(MultipleLocator(20))
        self.axes.plot(x, self.data, color = 'red')
        self.draw()

class Comp_plot(FigureCanvas):
    def __init__(self, parent = None, width = 5, height = 4, dpi = 100, threshold = 55, makeup = 0, ratio = 2, argv = argv):
        self.data = [i + makeup for i in (list(range(threshold)) + [threshold + i/ratio for i in range(91-threshold)])]
        fig = Figure(figsize = (width, height), dpi = dpi)
        self.axes = fig.add_subplot(111)
        FigureCanvas.__init__(self, fig)
        self.setParent(parent)
        FigureCanvas.setSizePolicy(self, QSizePolicy.Expanding, QSizePolicy.Expanding)
        FigureCanvas.updateGeometry(self)
        self.plot()
    def plot(self):
        x = list(range(0, 91))
        self.axes.set_xlim([0, 90])
        self.axes.set_ylim([0, 90])
        self.axes.xaxis.set_major_locator(MultipleLocator(20))
        self.axes.plot(x, self.data, color = 'red')
        
        self.draw()

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)
        self.NGthreshold = 0
        self.Compthreshold = 90
        self.Compratio = 5
        self.Compmakeup = 0
        self.status = 'pause'
        self.filepath = None
        self.progress = 0
        self.progress_sec = 0
        self.progress_min = 0
        self.duration = 0
        self.duration_sec = 0
        self.duration_min = 0
        self.playlist = QMediaPlaylist(self)
        self.player = QMediaPlayer(self)
        self.dmin = ''
        self.dsec = ''
        self.volume = 100
        self.mute = False
        self.LR = 2
        self.setup_control()
        
        
    def setup_control(self):
        self.serial_init(argv=argv)
        # 初始化serial       
        
        self.FFTfgraph = EQ_plot(self)
        self.ui.verticalLayout.addWidget(self.FFTfgraph)
        self.Compfgraph = EQ_plot(self, color = 'red')
        self.ui.verticalLayout_2.addWidget(self.Compfgraph)
        # 初始化頻譜圖
        self.NGgraph = NG_plot(self, threshold = self.NGthreshold)
        self.ui.verticalLayout_NG.addWidget(self.NGgraph)
        # 初始化NG圖
        self.Compgraph = Comp_plot(self, threshold = self.Compthreshold, makeup = self.Compmakeup, ratio = self.Compratio)
        self.ui.verticalLayout_Comp.addWidget(self.Compgraph)
        # 初始化comp圖
        self.ui.stop_button.clicked.connect(lambda: self.status_refresh('stop'))
        self.ui.play_button.clicked.connect(lambda: self.status_refresh('play'))
        self.ui.pause_button.clicked.connect(lambda: self.status_refresh('pause'))
        # 更新status
        self.ui.NG_threshold_slider.valueChanged.connect(lambda: self.NG_refresh('thresholdslider'))
        self.ui.NG_threshold_lineEdit.textChanged.connect(lambda: self.NG_refresh('thresholdtext'))
        # 更新NG參數及NG圖
        self.ui.Comp_threshold_slider.valueChanged.connect(lambda: self.Comp_refresh('thresholdslider'))
        self.ui.Comp_threshold_lineEdit.textChanged.connect(lambda: self.Comp_refresh('thresholdtext'))
        
        self.ui.Comp_ratio_slider.valueChanged.connect(lambda: self.Comp_refresh('ratioslider'))
        self.ui.Comp_ratio_lineEdit.textChanged.connect(lambda: self.Comp_refresh('ratiotext'))
        self.ui.Comp_ratio_lineEdit.editingFinished.connect(lambda: self.Comp_refresh('ratioeditend'))

        self.ui.Comp_makeup_slider.valueChanged.connect(lambda: self.Comp_refresh('makeupslider'))
        self.ui.Comp_makeup_lineEdit.textChanged.connect(lambda: self.Comp_refresh('makeuptext'))
        # 更新Comp參數及Comp圖
        self.ui.filebutton.clicked.connect(self.openfile)
        # 開啟欲播放之檔案
        self.player.positionChanged.connect(self.progress_slider_refresh)
        self.ui.progressSlider.sliderMoved.connect(self.player_refresh)
        # 更新進度條及播放位置
        self.ui.volume_slider.valueChanged.connect(self.volume_refresh)
        self.ui.sound_button.clicked.connect(self.sound_refresh)
        # 更新聲音
        self.ui.LRSlider.valueChanged.connect(self.LR_refresh)
        
    def status_refresh(self, button):
        if button == 'stop':
            self.status = 'stop'
            self.player.stop()
        elif button == 'play':
            if self.status == 'pause':
                if self.filepath:
                    self.status = 'play'
                    self.player.play()
                    self.funct()
        elif button == 'pause':
            if self.status == 'play':
                self.status = 'pause'
                self.player.pause()

    def fgraph_refresh(self, FFT_data = [0]*15, Comp_data = [0]*15):
        self.ui.verticalLayout.removeWidget(self.FFTfgraph)
        self.FFTfgraph = EQ_plot(self, width=5, height=4, data = FFT_data, type = 'Original')
        self.ui.verticalLayout.addWidget(self.FFTfgraph)

        self.ui.verticalLayout_2.removeWidget(self.Compfgraph)
        self.Compfgraph = EQ_plot(self, width=5, height=4, data = Comp_data, type = 'Compressed', color = 'red')
        self.ui.verticalLayout_2.addWidget(self.Compfgraph)
        
    def funct(self):
        NGthreshold_raw = bin(int(10**(self.NGthreshold/20)))[2:] 
        NGthreshold = '0'*16 + '0'*(16-len(NGthreshold_raw)) + NGthreshold_raw
        NGthresholddata = ['']*4
        for i in range(4):
            NGthresholddata[i] = int(NGthreshold[8*i:8*i+8], base = 2)
        self.s.write(NGthresholddata)
   
        Compthreshold_raw = bin(int(10**(self.Compthreshold/20)))[2:]
        Compthreshold = '0'*15 + '1' + '0'*(16-len(Compthreshold_raw)) + Compthreshold_raw
        Compthresholddata = ['']*4
        for i in range(4):
            Compthresholddata[i] = int(Compthreshold[8*i:8*i+8], base = 2)
        self.s.write(Compthresholddata)
      
        Compratio_raw = bin(self.Compratio)[2:]
        Compratio = '0'*14 + '10' + '0'*(16-len(Compratio_raw)) + Compratio_raw
        Compratiodata = ['']*4
        for i in range(4):
            Compratiodata[i] = int(Compratio[8*i:8*i+8], base = 2)
        self.s.write(Compratiodata)
        
        Compmakeup_raw = bin(int(10**(self.Compmakeup/20)))[2:]
        Compmakeup = '0'*14 + '11' + '0'*(16-len(Compmakeup_raw)) + Compmakeup_raw
        Compmakeupdata = ['']*4
        for i in range(4):
            Compmakeupdata[i] = int(Compmakeup[8*i:8*i+8], base = 2)
        self.s.write(Compmakeupdata)

        LR_raw = bin(self.LR)[2:]
        LR = '0'*13 + '100' + '0'*(16-len(LR_raw)) + LR_raw
        LRdata = ['']*4
        for i in range(4):
            LRdata[i] = int(LR[8*i:8*i+8], base = 2)
        self.s.write(LRdata)
       
        self.s.write([int('ff', base = 16), int('ff', base = 16), int('00', base = 16), int('01', base = 16)])
        
        databyte = self.s.read(32)
        data = struct.unpack('>HHHHHHHHHHHHHHHH', databyte)
        print(databyte)
        dataFFT = [0]*8
        dataComp = [0]*8
        for i in range(8):
            if data[i] < 1:
                dataFFT[i] = 1
            else:
                dataFFT[i] = data[i]
            if data[i+8] < 1:
                dataComp[i] = 1
            else:
                dataComp[i] = data[i+8]
                
        dataFFTdB = [int((math.log10(dataFFT[i]))*10) for i in range(8)]
        dataCompdB = [int((math.log10(dataComp[i]))*10) for i in range(8)]
        dataFFTin = [0]*15
        dataCompin = [0]*15
        for i in range(15):
            if i%2 == 0:
                dataFFTin[i] = dataFFTdB[i//2]
                dataCompin[i] = dataCompdB[i//2]
            else:
                dataFFTin[i] = (dataFFTdB[i//2] + dataFFTdB[i//2+1])//2
                dataCompin[i] = (dataCompdB[i//2] + dataCompdB[i//2+1])//2
        self.fgraph_refresh(FFT_data = dataFFTin, Comp_data = dataCompin)
        
    def NG_refresh(self, item):
        if item == 'thresholdslider':
            value = self.ui.NG_threshold_slider.value()
            self.NGthreshold = value
            self.ui.NG_threshold_lineEdit.setText(str(value))
        elif item == 'thresholdtext':
            text = self.ui.NG_threshold_lineEdit.text()
            if text == '':
                value = 0
                self.ui.NG_threshold_lineEdit.setText('0')
            else:
                if int(text) > 90:
                    value = 90
                else:
                    value = int(text)
            self.NGthreshold = value
            self.ui.NG_threshold_slider.setValue(value)
                
        self.ui.verticalLayout_NG.removeWidget(self.NGgraph)
        self.NGgraph = NG_plot(self, threshold = self.NGthreshold)
        self.ui.verticalLayout_NG.addWidget(self.NGgraph)

    def Comp_refresh(self, item):
        if item == 'thresholdslider':
            value = self.ui.Comp_threshold_slider.value()
            self.Compthreshold = value
            self.ui.Comp_threshold_lineEdit.setText(str(value))
        elif item == 'thresholdtext':
            text = self.ui.Comp_threshold_lineEdit.text()
            if text == '':
                value = 0
                self.ui.Comp_threshold_lineEdit.setText('0')
            else:
                if int(text) > 90:
                    value = 90
                else:
                    value = int(text)
            self.Compthreshold = value
            self.ui.Comp_threshold_slider.setValue(value)

        elif item == 'ratioslider':
            value = self.ui.Comp_ratio_slider.value()
            self.Compratio = value
            if self.ui.Comp_ratio_lineEdit.text() != '':
                self.ui.Comp_ratio_lineEdit.setText(str(value))
        elif item == 'ratiotext':
            text = self.ui.Comp_ratio_lineEdit.text()
            if text == '':
                value = 5
            else:
                if int(text) > 31:
                    value = 31
                else:
                    value = int(text)
            self.Compratio = value
            self.ui.Comp_ratio_slider.setValue(value)
        elif item == 'ratioeditend':
            if self.ui.Comp_ratio_lineEdit.text() == '':
                self.ui.Comp_ratio_lineEdit.setText('5')

        elif item == 'makeupslider':
            value = self.ui.Comp_makeup_slider.value()
            self.Compmakeup = value
            self.ui.Comp_makeup_lineEdit.setText(str(value))
        elif item == 'makeuptext':
            text = self.ui.Comp_makeup_lineEdit.text()
            if text == '':
                value = 0
                self.ui.Comp_makeup_lineEdit.setText('0')
            else:
                if int(text) > 10:
                    value = 10
                else:
                    value = int(text)
            self.Compmakeup = value
            self.ui.Comp_makeup_slider.setValue(value)

        self.ui.verticalLayout_Comp.removeWidget(self.Compgraph)
        self.Compgraph = Comp_plot(self, threshold = self.Compthreshold, makeup = self.Compmakeup, ratio = self.Compratio)
        self.ui.verticalLayout_Comp.addWidget(self.Compgraph)

    def openfile(self):
        self.filepath = QFileDialog.getOpenFileName(self, "Open file", "./")[0]
        if self.filepath.split('/')[-1][-3:] == 'mp3':
            self.ui.song_name_label.setText('Now Playing:     ' + self.filepath.split('/')[-1])
            self.status = 'pause'
            self.progress = 0
            self.playlist.addMedia(QMediaContent(QUrl.fromLocalFile(self.filepath)))
            self.player.setPlaylist(self.playlist)
            self.player.durationChanged.connect(self.setduration)
        else:
            print('file must be .mp3 format')

    def setduration(self, d):
        self.duration = d
        self.duration_sec = self.duration // 1000
        self.duration_min = self.duration_sec // 60
        self.duration_sec -= self.duration_min*60
        if self.duration_min < 10:
            self.dmin = '0'+str(self.duration_min)
        else:
            self.dmin = str(self.duration)
        if self.duration_sec < 10:
            self.dsec = '0'+str(self.duration_sec)
        else:
            self.dsec = str(self.duration_sec)
        self.ui.progressLabel.setText('XX:XX'+'/'+self.dmin+':'+self.dsec)
        self.ui.progressSlider.setRange(0, self.duration)

    def progress_slider_refresh(self, p):
        self.ui.progressSlider.setValue(p)
        self.progress = p
        self.progress_sec = self.progress // 1000
        if p>500:
            self.funct()
        self.progress_min = self.progress_sec // 60
        self.progress_sec -= self.progress_min*60
        if self.progress_min < 10:
            min = '0'+str(self.progress_min)
        else:
            min = str(self.progress_min)
        if self.progress_sec < 10:
            sec = '0'+str(self.progress_sec)
        else:
            sec = str(self.progress_sec)
        self.ui.progressLabel.setText(min+':'+sec+'/'+self.dmin+':'+self.dsec)

    def player_refresh(self):
        self.progress = self.ui.progressSlider.value()
        self.player.setPosition(self.progress)
        
    def volume_refresh(self, v):
        self.player.setVolume(v)
        if v == 0:
            self.ui.sound_button.setIcon(QIcon('icons/sound_off.png'))
            self.mute = True
        else:
            self.ui.sound_button.setIcon(QIcon('icons/sound_on.png'))
            self.mute = False
            self.volume = v
    
    def sound_refresh(self):
        if self.mute:
            self.ui.sound_button.setIcon(QIcon('icons/sound_on.png'))
            self.mute = False
            self.player.setVolume(self.volume)
            self.ui.volume_slider.setValue(self.volume)
        else:
            self.ui.sound_button.setIcon(QIcon('icons/sound_off.png'))
            self.mute = True
            self.volume = self.player.volume()
            self.player.setVolume(0)
            self.ui.volume_slider.setValue(0)

    def serial_init(self, argv):
        assert len(argv) == 2
        self.s = Serial(
            port=argv[1],
            baudrate=115200,
            bytesize=EIGHTBITS,
            parity=PARITY_NONE,
            stopbits=STOPBITS_ONE,
            xonxoff=False,
            rtscts=False
        )

    def LR_refresh(self, ratio):
        self.LR = ratio

if __name__ == "__main__":
    app = QApplication(argv)
    mainwindow = MainWindow()
    mainwindow.show()
    app.exec()
    
    