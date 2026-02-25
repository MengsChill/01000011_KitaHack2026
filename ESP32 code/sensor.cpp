from machine import I2C, Pin
import time

# ==== I2C Setup ====
i2c = I2C(0, scl=Pin(22), sda=Pin(21), freq=400000)

# Change to 0x3F if needed
addr = 0x27

# ==== Low-level LCD functions ====
def lcd_write(cmd, mode=0):
    high = mode | (cmd & 0xF0) | 0x08
    low = mode | ((cmd << 4) & 0xF0) | 0x08
    i2c.writeto(addr, bytearray([high | 0x04]))
    i2c.writeto(addr, bytearray([high]))
    i2c.writeto(addr, bytearray([low | 0x04]))
    i2c.writeto(addr, bytearray([low]))

def lcd_cmd(cmd):
    lcd_write(cmd, 0)

def lcd_data(data):
    lcd_write(data, 1)

def lcd_init():
    time.sleep(0.02)
    lcd_cmd(0x33)
    lcd_cmd(0x32)
    lcd_cmd(0x28)
    lcd_cmd(0x0C)
    lcd_cmd(0x06)
    lcd_cmd(0x01)
    time.sleep(0.005)

def lcd_move(row, col):
    addr_map = [0x80, 0xC0]
    lcd_cmd(addr_map[row] + col)

def lcd_print(text):
    for char in text:
        lcd_data(ord(char))

# ==== Run Test ====
lcd_init()

block = chr(255)

lcd_move(0, 4)
lcd_print(block * 8)

lcd_move(1, 4)
lcd_print(block * 8)
