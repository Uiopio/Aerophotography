import serial




class Uart:
    def __init__(self, port = '/dev/serial0', boud = 9600, timeout = 1):
        self.uart = serial.Serial(port, boud, timeout = timeout)
        self.uart.flush() # очистка юарта

    # Принять сообщение
    def accept_message(self):
        if self.uart.in_waiting > 0:
            line = self.uart.readline()
            print(line)
            #return line.decode("utf-8").rstrip()

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



while True:

    uart = Uart('/dev/serial0', 9600, 1)

    while True:
        uart.accept_message()