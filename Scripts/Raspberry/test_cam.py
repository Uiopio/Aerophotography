import time
import picamera


camera = picamera.PiCamera(sensor_mode=1, framerate=24)
camera.resolution = (1920, 1080)     # Разрешение 3280x2464
camera.framerate = 30
camera.exposure_mode = "antishake"
camera.iso = 500
camera.shutter_speed = 8000
print(camera.shutter_speed)


camera.capture('image3333.jpg')
