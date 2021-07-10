
import picamera
import serial
import time
import os

class Uart:
    def __init__(self, port = '/dev/serial0', boud = 9600, timeout = 1):
        self.uart = serial.Serial(port, boud, timeout = timeout)
        self.uart.flush() # очистка юарта

    # Принять сообщение
    def accept_message(self):
        if self.uart.in_waiting > 0:
            line = self.uart.readline()
            print(line.decode("utf-8").rstrip())
            return line.decode("utf-8").rstrip()

    # распарсить сообщение
    def message_parse(self, message):

        ind_X = message.find("X")
        ind_Y = message.find("Y")
        ind_Z = message.find("Z")

        x = "{:.2f}".format(float(message[(ind_X + 1):(ind_Y)]))
        y = "{:.2f}".format(float(message[(ind_Y + 1):(ind_Z)]))
        z = "{:.2f}".format(float(message[(ind_Z + 1):]))
        print(x, y, z)
        return x, y, z



# допустимые разрешения для raspberry pi Camera v2.1
# 3280x2464
# 1920x1080
# 1640x1232
# 1640x922
# 1280x720
# 640x480
class Camera:
    def __init__(self, width_frame=1920, height_frame=1080, method=2):
        if method == 1:
            pass

        if method == 2:
            self.camera = picamera.PiCamera(sensor_mode=1, framerate=24)
            self.camera.resolution = (1920, 1080)
            self.camera.framerate = 30
            self.camera.exposure_mode = "antishake"
            self.camera.iso = 500
            self.camera.shutter_speed = 10000

        self.num_photo = 0
        self.file = open("photo.txt", "w")  # создание текстового файла


    def get_photoCV(self, x, y, z):
        # получение и сохранение фотографии

        ret, frame = self.cap.read()
        path = str(self.num_photo) + ".jpg"
        cv2.imwrite(path, frame)
        print("фото", self.num_photo)
        # запись координат и номера фотографии
        self.get_txt(x, y, z)
        self.num_photo = self.num_photo + 1

    def get_photo_piCam(self,x ,y, z):
        path = "1_" + str(self.num_photo) + ".jpg"
        self.camera.capture(path)
        print("фото", self.num_photo)
        # запись координат и номера фотографии
        self.get_txt(x, y, z)
        self.num_photo = self.num_photo + 1

    # запись в файл
    def get_txt(self, x, y, z):
        string = "1_" + str(self.num_photo) + ".jpg" + " " + str(x) + " " + str(y) + " " + str(z) + "\n"
        self.file.write(string)

start = False
delta = 1
time_work = 0
if __name__ == '__main__':
    os.system("rm *.txt")
    os.system("rm *.jpg")
    

    uart = Uart('/dev/serial0', 9600, 1)
    cam = Camera(width_frame=1920, height_frame=1080, method=2)

    t1 = time.time()
    print("старт")
    while True:

        line = uart.accept_message() # чтение из юарта

        if line is not None:
            x, y, z = uart.message_parse(line)
            cam.get_photo_piCam(x, y, z)
            start = True

        if (time.time() - t1 >= delta) and (start == True):
            time_work = time_work + 1

            if time_work >= 10:
                print("Время работы:", time_work, "сек")

            t1 = time.time()




